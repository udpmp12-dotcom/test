import { NextResponse } from "next/server";
import { supabaseAdmin } from "@/lib/supabase/admin";

// Revisa que la app y la base de datos se estén hablando bien.
export async function GET() {
  try {
    const db = supabaseAdmin();
    const { data, error } = await db
      .from("businesses")
      .select("slug, name, stamps_required, status")
      .order("created_at");
    if (error) throw error;
    return NextResponse.json({ ok: true, negocios: data });
  } catch (err) {
    const mensaje = err instanceof Error ? err.message : "Error desconocido";
    return NextResponse.json({ ok: false, error: mensaje }, { status: 500 });
  }
}
