export default function Inicio() {
  return (
    <main className="mx-auto flex min-h-screen max-w-md flex-col items-center justify-center gap-4 p-6 text-center">
      <h1 className="text-4xl font-bold">UpTen</h1>
      <p className="text-neutral-600">Tarjetas de lealtad digitales para cafeterías.</p>
      <a href="/api/health" className="text-sm text-blue-600 underline">
        Revisar conexión con la base de datos
      </a>
    </main>
  );
}
