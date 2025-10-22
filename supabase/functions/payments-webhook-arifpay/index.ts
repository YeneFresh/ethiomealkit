// Arifpay webhook verify + intent update.
// Adjust header names / body schema to match Arifpay docs.

import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.45.4";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SERVICE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

async function verifyHmac(raw: string, signature: string, secret: string) {
  const key = await crypto.subtle.importKey(
    "raw",
    new TextEncoder().encode(secret),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"]
  );
  const sig = await crypto.subtle.sign("HMAC", key, new TextEncoder().encode(raw));
  const hex = Array.from(new Uint8Array(sig)).map(b => b.toString(16).padStart(2, "0")).join("");
  return signature === hex;
}

serve(async (req) => {
  try {
    const supabase = createClient(SUPABASE_URL, SERVICE_KEY);

    const secret = Deno.env.get("PAY_ARIFPAY_WEBHOOK_SECRET")!;
    const raw = await req.text();
    const signature = req.headers.get("X-Arifpay-Signature") || req.headers.get("x-arifpay-signature") || "";
    if (!signature || !(await verifyHmac(raw, signature, secret))) {
      return new Response("invalid signature", { status: 403 });
    }

    const payload = JSON.parse(raw);

    // Try common fields; adjust once you confirm Arifpay’s exact payload
    const intentId = payload?.meta?.intent_id || payload?.reference || payload?.tx_ref || null;
    if (!intentId) return new Response("no intent", { status: 400 });

    const status = (payload?.status === "SUCCESS" || payload?.status === "success")
      ? "succeeded"
      : (payload?.status === "PENDING" || payload?.status === "pending") ? "pending" : "failed";

    await supabase.rpc("app_mark_intent_status", {
      intent: intentId,
      new_status: status,
      provider_response: payload,
      provider_txn_id: payload?.txn_id ?? payload?.data?.transaction_id ?? null,
    });

    return new Response("ok");
  } catch (e) {
    return new Response(`arifpay webhook error: ${(e as Error).message}`, { status: 500 });
  }
});
