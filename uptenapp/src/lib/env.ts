import { z } from "zod";

// Variables que necesita el servidor. Si falta una, el error dice cuál.
const schema = z.object({
  NEXT_PUBLIC_SUPABASE_URL: z.string().url(),
  NEXT_PUBLIC_SUPABASE_ANON_KEY: z.string().min(1),
  SUPABASE_SERVICE_ROLE_KEY: z.string().min(1),
  NEXT_PUBLIC_APP_URL: z.string().url(),
  ADMIN_EMAILS: z.string().default(""),
  SESSION_SECRET: z.string().min(16, "SESSION_SECRET debe tener al menos 16 caracteres"),
});

let cached: z.infer<typeof schema> | null = null;

export function env() {
  if (cached) return cached;
  const result = schema.safeParse(process.env);
  if (!result.success) {
    const faltan = result.error.issues.map((i) => `${i.path.join(".")}: ${i.message}`).join("; ");
    throw new Error(`Faltan variables de entorno o son inválidas → ${faltan}`);
  }
  cached = result.data;
  return cached;
}

export function adminEmails(): string[] {
  return env()
    .ADMIN_EMAILS.split(",")
    .map((e) => e.trim().toLowerCase())
    .filter(Boolean);
}
