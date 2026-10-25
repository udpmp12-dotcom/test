import { createBrowserClient } from "@supabase/ssr";

// Cliente para el navegador (login del dueño). Usa solo la llave pública.
export function supabaseBrowser() {
  return createBrowserClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
  );
}
