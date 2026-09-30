import { createClient, SupabaseClient } from "npm:@supabase/supabase-js@2";

const url = Deno.env.get("SUPABASE_URL")!;
const anonKey = Deno.env.get("SUPABASE_ANON_KEY")!;
const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

/// Acts as the caller: every query runs under row-level security with
/// the Firebase token from the request, so "select my booking" is also
/// the ownership check.
export function callerClient(request: Request): SupabaseClient | null {
  const auth = request.headers.get("Authorization");
  if (!auth?.startsWith("Bearer ")) return null;
  return createClient(url, anonKey, {
    global: { headers: { Authorization: auth } },
    auth: { persistSession: false },
  });
}

/// Bypasses row-level security. Used only for the writes a customer
/// must not be able to make themselves: marking a payment paid and a
/// booking confirmed.
export function serviceClient(): SupabaseClient {
  return createClient(url, serviceKey, { auth: { persistSession: false } });
}
