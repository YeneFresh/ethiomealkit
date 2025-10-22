import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.45.4";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SERVICE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

async function timingSafeEqual(a: Uint8Array, b: Uint8Array) {
  if (a.length !== b.length) return false;
  let out = 0;
  for (let i = 0; i < a.length; i++) out |= a[i] ^ b[i];
  return out === 0;
}

async function verifyHmac(raw: string, signature: string, secret: string) {
  const key = await crypto.subtle.importKey("raw", new TextEncoder().encode(secret), { name: "HMAC", hash: "SHA-256" }, false, ["sign"]);
  const sig = await crypto.subtle.sign("HMAC", key, new TextEncoder().encode(raw));
  const got = Uint8Array.from(atob(signature), c => c.charCodeAt(0));
  const exp = new Uint8Array(sig);
  return timingSafeEqual(got, exp);
}

serve(async (req) => {
  try {
    const supabase = createClient(SUPABASE_URL, SERVICE_KEY);
    const secret = Deno.env.get("PAY_TELBIRR_WEBHOOK_SECRET")!;
    const raw = await req.text();

    // Telebirr signature header name may differ; adjust per docs
    const sigHeader = req.headers.get("X-Telebirr-Signature") || "";
    if (!sigHeader || !(await verifyHmac(raw, sigHeader, secret))) {
      return new Response("invalid signature", { status: 403 });
    }

    const payload = JSON.parse(raw);
    // Normalize: find our intent id and map status
    const intentId = payload?.meta?.intent_id || payload?.reference || null;
    if (!intentId) return new Response("no intent id", { status: 400 });

    const status = (payload?.status === "SUCCESS")
      ? "succeeded"
      : (payload?.status === "PENDING" ? "pending" : "failed");

    await supabase.rpc("app_mark_intent_status", {
      intent: intentId,
      new_status: status,
      provider_response: payload,
      provider_txn_id: payload?.txn_id ?? null,
    });

    return new Response("ok");
  } catch (e) {
    return new Response(`telebirr webhook error: ${(e as Error).message}`, { status: 500 });
  }
});


