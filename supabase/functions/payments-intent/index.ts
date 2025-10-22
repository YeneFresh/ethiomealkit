import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.45.4";

type CreateIntentBody = {
  amount_cents: number;
  currency: string;                  // 'ETB' | 'USD'
  provider_id: "telebirr" | "chapa" | "arifpay" | "cod";
  method_id?: string | null;         // reserved (not used for local wallets today)
  address_id: string;
  delivery_window_id: string;
  purpose?: string;                  // 'weekly_box' default
  idempotency_key?: string;
  selected_recipes?: string[];       // NEW: attach items server-side
  quantities?: number[];             // optional, matches length of selected_recipes
};

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY")!;
const APP_RETURN_HOST = Deno.env.get("APP_RETURN_HOST") || "return.yenefresh.com";

// Utilities
function money(cents: number) {
  return (cents / 100).toFixed(2);
}
function uid() {
  return crypto.randomUUID();
}

// ---- Provider adapters ----

// TELEBIRR: Create a pay link (or deeplink) the app can open.
// Replace base URL & payload per your Telebirr merchant docs.
async function createTelebirrCheckout(ctx: {
  body: CreateIntentBody;
  user: any;
  order_id: string;
  intent_id: string;
}) {
  const appId = Deno.env.get("PAY_TELBIRR_APP_ID")!;
  const merchantId = Deno.env.get("PAY_TELBIRR_MERCHANT_ID")!;
  const appKey = Deno.env.get("PAY_TELBIRR_APP_KEY")!; // used to sign provider payload if needed

  // TODO: Build Telebirr payload & signature properly per docs.
  const payload = {
    appId,
    merchantId,
    amount: money(ctx.body.amount_cents),
    currency: ctx.body.currency,
    reference: ctx.intent_id,              // we normalize on our intent id
    returnUrl: `https://${APP_RETURN_HOST}/pay/return`, // client WebView closes here
    // ...additional Telebirr fields (msisdn, description, etc.)
  };

  // Placeholder call (you must replace with Telebirr endpoint)
  // const res = await fetch("https://api.telebirr.com/payments/create", { ... })

  // For now return a stub URL so you can test end-to-end
  const redirect_url = `https://example.com/telebirr/checkout?ref=${ctx.intent_id}`;

  return {
    redirect_url,
    provider_payload: payload,
  };
}

// CHAPA: Initialize hosted checkout (has good sandbox)
async function createChapaCheckout(ctx: {
  body: CreateIntentBody;
  user: any;
  order_id: string;
  intent_id: string;
}) {
  const secret = Deno.env.get("PAY_CHAPA_SECRET_KEY")!;
  const txRef = ctx.body.idempotency_key || `yf_${ctx.intent_id}`;
  const initRes = await fetch("https://api.chapa.co/v1/transaction/initialize", {
    method: "POST",
    headers: {
      Authorization: `Bearer ${secret}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      amount: money(ctx.body.amount_cents),
      currency: ctx.body.currency,
      email: ctx.user.user_metadata?.email || "user@yenefresh.com",
      first_name: ctx.user.user_metadata?.full_name || "YeneFresh",
      tx_ref: txRef,
      // Customer returns here in WebView; webhook also fires server-side.
      callback_url: `https://${APP_RETURN_HOST}/pay/return`,
      // You can pass custom fields; put our intent_id to find it easily in webhook.
      custom_fields: [{ display_name: "intent_id", variable_name: "intent_id", value: ctx.intent_id }],
    }),
  });
  const data = await initRes.json();
  if (!initRes.ok) {
    throw new Error(`Chapa init failed: ${data?.message || initRes.statusText}`);
  }
  const redirect_url = data?.data?.checkout_url as string;
  return {
    redirect_url,
    provider_payload: data,
  };
}

// ARIFPAY: Similar to Chapa; replace endpoint/fields per docs.
async function createArifpayCheckout(ctx: {
  body: CreateIntentBody;
  user: any;
  order_id: string;
  intent_id: string;
}) {
  const pk = Deno.env.get("PAY_ARIFPAY_PUBLIC_KEY")!;
  const sk = Deno.env.get("PAY_ARIFPAY_SECRET_KEY")!;
  // TODO: Replace with Arifpay init endpoint and auth
  // const res = await fetch("https://api.arifpay.com/checkout/init", { ... })

  // Stub for immediate testing:
  const redirect_url = `https://example.com/arifpay/checkout?ref=${ctx.intent_id}`;
  return {
    redirect_url,
    provider_payload: { pk, ref: ctx.intent_id },
  };
}

const adapters: Record<string, Function> = {
  telebirr: createTelebirrCheckout,
  chapa: createChapaCheckout,
  arifpay: createArifpayCheckout,
  cod: async (_: any) => ({ provider_payload: { note: "cash_on_delivery" } }),
};

serve(async (req) => {
  try {
    if (req.method !== "POST") return new Response("Method not allowed", { status: 405 });

    const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
      global: { headers: { Authorization: req.headers.get("Authorization") || "" } },
    });

    const { data: userRes } = await supabase.auth.getUser();
    const user = userRes.user;
    if (!user) return new Response("Unauthorized", { status: 401 });

    const body = (await req.json()) as CreateIntentBody;
    const idempotencyKey = body.idempotency_key || `yf_${uid()}`;

    // Create order + intent (and insert items) via RPC (you extended this RPC)
    const { data: rows, error } = await supabase.rpc("app_create_order_with_intent", {
      total_cents: body.amount_cents,
      currency: body.currency,
      provider_id: body.provider_id,
      method_id: body.method_id,
      address_id: body.address_id,
      delivery_window_id: body.delivery_window_id,
      purpose: body.purpose ?? "weekly_box",
      idempotency_key: idempotencyKey,
      selected_recipes: body.selected_recipes ?? [],
      quantities: body.quantities ?? [],
    });
    if (error) {
      return new Response(error.message, { status: 400 });
    }
    const { order_id, intent_id } = rows[0];

    // Prepare provider session/link
    const adapter = adapters[body.provider_id];
    if (!adapter) return new Response("Unknown provider", { status: 400 });

    const prep = await adapter({ body, user, order_id, intent_id });

    // Save client_secret / redirect / payload
    await supabase.from("app.payment_intent")
      .update({
        client_secret: (prep as any).client_secret ?? null,
        redirect_url: (prep as any).redirect_url ?? null,
        provider_payload: (prep as any).provider_payload ?? {},
        status: body.provider_id === "cod" ? "pending" : "created",
      })
      .eq("id", intent_id);

    return new Response(JSON.stringify({
      order_id,
      intent_id,
      client_secret: (prep as any).client_secret ?? null,
      redirect_url: (prep as any).redirect_url ?? null,
    }), { headers: { "content-type": "application/json" } });

  } catch (e) {
    return new Response(`payments-intent error: ${(e as Error).message}`, { status: 500 });
  }
});


