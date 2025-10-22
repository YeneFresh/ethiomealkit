// Schedules: set in Studio to 09:00 Africa/Addis_Ababa (see step 3 below).
// Auth: NO end-user auth required. Uses Service Role internally.
// Modes: BILLING_RUN_MODE = 'dry' | 'live'

import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.45.4";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SERVICE_KEY   = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const RUN_MODE      = (Deno.env.get("BILLING_RUN_MODE") || "dry").toLowerCase();
const LOOKAHEAD_DAYS = parseInt(Deno.env.get("BILLING_LOOKAHEAD_DAYS") || "3", 10) || 3;
const TIMEZONE     = Deno.env.get("BILLING_TIMEZONE") || "Africa/Addis_Ababa";
const CRON_SHARED_KEY = Deno.env.get("CRON_SHARED_KEY") || ""; // optional

function serializeError(e: unknown): string {
  try {
    // deno-lint-ignore no-explicit-any
    const msg = (e as any)?.message ?? e;
    return typeof msg === 'string' ? msg : JSON.stringify(msg);
  } catch {
    return String(e);
  }
}

type SubRow = {
  id: string;
  user_id: string;
  next_invoice_date: string; // DATE
  // optional columns may not exist in all schemas
  status?: string;
  default_method?: string | null;
  shipping_window?: any | null;
};

type PmRow = {
  id: string;
  user_id: string;
  provider_id: string;  // e.g., 'telebirr','chapa','arifpay','stripe','cod'
  status: string;       // 'active' | ...
};

type ProvRow = {
  id: string;           // provider id
  kind: string;         // 'card' | 'local_wallet' | 'cod' | 'bank'
};

serve(async (_req) => {
  // Optional shared secret for external triggers (e.g., GitHub Actions)
  const hdrKey = _req.headers.get("X-Cron-Key") || "";
  if (CRON_SHARED_KEY && hdrKey !== CRON_SHARED_KEY) {
    if (RUN_MODE === "live") {
      return json({ ok:false, error:"forbidden: bad cron key" }, 403);
    }
  }

  const admin = createClient(SUPABASE_URL, SERVICE_KEY, { db: { schema: "app" } });

  const now = new Date();
  const until = new Date(now.getTime() + LOOKAHEAD_DAYS * 24 * 60 * 60 * 1000);

  const summary = {
    ok: true,
    mode: RUN_MODE,
    timezone: TIMEZONE,
    lookahead_days: LOOKAHEAD_DAYS,
    window: { from: now.toISOString(), to: until.toISOString() },
    counts: { total: 0, card: 0, local_or_cod: 0 },
    acted_on: 0,
    notes: [] as string[],
  };

  try {
    const fromISODate = now.toISOString().slice(0,10);
    const toISODate   = until.toISOString().slice(0,10);

    // 1) Fetch due subs (active, within window) - minimal columns for robustness
    const { data: subs, error: subsErr } = await admin
      .from("subscription")
      .select("id,user_id,next_invoice_date")
      .gte("next_invoice_date", fromISODate)
      .lte("next_invoice_date", toISODate)
      .limit(500) as unknown as { data: SubRow[]; error: unknown };

    if (subsErr) {
      return json({ ok:false, step:"fetch_subs", error: serializeError(subsErr), window:{from:fromISODate,to:toISODate} });
    }

    if (!subs || subs.length === 0) {
      return json({ ok:true, mode: RUN_MODE, window:{from:fromISODate,to:toISODate}, counts:{total:0,card:0,local_or_cod:0}, acted_on:0, notes:["No active subs due in window."] });
    }

    // 2) payment_methods for default_method ids (only if available later)
    const methodIds = Array.from(new Set((subs as SubRow[]).map(s => s.default_method).filter(Boolean))) as string[];

    let pmMap = new Map<string, PmRow>();
    if (methodIds.length > 0) {
      const { data: pms, error: pmErr } = await admin
        .from("payment_method")
        .select("id,user_id,provider_id,status")
        .in("id", methodIds) as unknown as { data: PmRow[]; error: unknown };
      if (pmErr) {
        return json({ ok:false, step:"fetch_payment_methods", error: serializeError(pmErr), methodIdsCount: methodIds.length });
      }
      for (const pm of (pms || [])) pmMap.set(pm.id, pm);
    }

    // 3) providers by provider_id
    const providerIds = Array.from(new Set(Array.from(pmMap.values()).map(pm => pm.provider_id)));
    let provMap = new Map<string, ProvRow>();
    if (providerIds.length > 0) {
      const { data: provs, error: provErr } = await admin
        .from("payment_provider")
        .select("id,kind")
        .in("id", providerIds) as unknown as { data: ProvRow[]; error: unknown };
      if (provErr) {
        return json({ ok:false, step:"fetch_providers", error: serializeError(provErr), providerIdsCount: providerIds.length });
      }
      for (const pv of (provs || [])) provMap.set(pv.id, pv);
    }

    // 4) normalized working set
    const due = (subs as SubRow[]).map(s => {
      const pm = s.default_method ? pmMap.get(s.default_method) : undefined;
      const prov = pm ? provMap.get(pm.provider_id) : undefined;
      return {
        id: s.id,
        user_id: s.user_id,
        next_invoice_date: s.next_invoice_date,
        shipping_window: s.shipping_window ?? null,
        default_method: s.default_method ?? null,
        provider_id: pm?.provider_id ?? null,
        provider_kind: prov?.kind ?? null,
      };
    });

    summary.counts.total = due.length;

    for (const s of due) {
      const kind = s.provider_kind || "unknown";
      if (kind === "card") summary.counts.card++; else summary.counts.local_or_cod++;

      if (RUN_MODE === "dry") {
        summary.notes.push(`DRY: would bill sub ${s.id} (user ${s.user_id}) via ${kind}`);
        continue;
      }

      try {
        if (kind === "card") {
          const amount_cents = 50000;
          const currency = "ETB";
          const fnUrl = `${SUPABASE_URL}/functions/v1/payments-intent`;
          const resp = await fetch(fnUrl, {
            method: "POST",
            headers: {
              "Authorization": `Bearer ${SERVICE_KEY}`,
              "Content-Type": "application/json",
            },
            body: JSON.stringify({
              amount_cents,
              currency,
              provider_id: "stripe",
              address_id: "00000000-0000-0000-0000-000000000000",
              delivery_window_id: "00000000-0000-0000-0000-000000000000",
              purpose: "weekly_box",
              idempotency_key: `cron_${s.id}_${s.next_invoice_date}`,
              selected_recipes: [],
            }),
          });
          if (!resp.ok) {
            summary.notes.push(`LIVE: failed to create intent for sub ${s.id} → ${resp.status} ${await resp.text()}`);
            continue;
          }
          summary.acted_on++;
        } else {
          const reminder = { sub_id: s.id, user_id: s.user_id, kind, next_invoice_date: s.next_invoice_date };
          summary.notes.push(`LIVE: would enqueue reminder ${JSON.stringify(reminder)}`);
        }
      } catch (e) {
        summary.notes.push(`LIVE: error for sub ${s.id} → ${(e as Error).message}`);
      }
    }
  } catch (e) {
    return json({ ok:false, error: serializeError(e) });
  }

  return json(summary);
});

function json(obj: unknown, status = 200) {
  return new Response(JSON.stringify(obj), { status, headers: { "content-type": "application/json" } });
}


