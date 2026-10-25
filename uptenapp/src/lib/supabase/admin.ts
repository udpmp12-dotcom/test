import { createClient } from "@supabase/supabase-js";
import { env } from "@/lib/env";

// Cliente con llave de servicio: se salta las reglas de seguridad (RLS).
// SOLO usar en el servidor (rutas API y páginas del servidor), nunca en el navegador.
export function supabaseAdmin() {
  const e = env();
  return createClient(e.NEXT_PUBLIC_SUPABASE_URL, e.SUPABASE_SERVICE_ROLE_KEY, {
    auth: { persistSession: false, autoRefreshToken: false },
  });
}
