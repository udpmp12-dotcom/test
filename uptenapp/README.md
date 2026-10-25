# UpTen

Tarjetas de lealtad (sellos) para cafeterías, con Apple Wallet.

> Esta app vive en la carpeta `uptenapp/` del repositorio. En Vercel hay que indicar esa carpeta (ver abajo).

## Estado

- [x] Fase 0 · Proyecto, base de datos y seguridad
- [ ] Fase 1 · Alta de cliente + pase de Apple Wallet
- [ ] Fase 2 · Actualizaciones automáticas y avisos push
- [ ] Fase 3 · Escáner del empleado
- [ ] Fase 4 · Panel del dueño
- [ ] Fase 5 · Panel de administrador y pulido

---

## Fase 0 · Puesta en marcha (paso a paso)

### 1. Crear tu proyecto en Supabase

1. Entra a <https://supabase.com> y crea una cuenta (puedes usar GitHub).
2. Clic en **New project**. Ponle nombre `uptenapp`, elige una contraseña de base de datos (guárdala) y la región más cercana (por ejemplo *East US* o *South America*).
3. Espera 1–2 minutos a que se cree.

### 2. Crear las tablas

1. En Supabase, menú izquierdo → **SQL Editor** → **New query**.
2. Abre el archivo `supabase/migrations/0001_tablas.sql`, copia **todo** su contenido, pégalo y presiona **Run**. Debe decir *Success*.
3. Repite con `0002_seguridad_rls.sql` y luego con `0003_funciones_sellos.sql`. **Respeta el orden.**
4. (Datos de prueba) Repite con `supabase/seed.sql`. Crea el negocio **Café Demo** con un empleado de PIN `1234`.

### 3. Copiar las claves

En Supabase → **Project Settings** (engrane) → **API**. Necesitas tres cosas:

| Dónde la ves | Variable |
|---|---|
| *Project URL* | `NEXT_PUBLIC_SUPABASE_URL` |
| *anon public* | `NEXT_PUBLIC_SUPABASE_ANON_KEY` |
| *service_role* (clic en "Reveal") | `SUPABASE_SERVICE_ROLE_KEY` |

> ⚠️ La `service_role` es como la llave maestra. Nunca la pegues en un chat, en GitHub ni en el navegador.

### 4. Subir la app a Vercel

1. Entra a <https://vercel.com>, inicia sesión con GitHub → **Add New… → Project** → elige este repositorio.
2. En **Root Directory** pulsa *Edit* y elige `uptenapp`. (Importante: el repositorio tiene otro proyecto en la raíz.)
3. En **Environment Variables** agrega, una por una, las variables de `.env.example`. Por ahora solo estas:
   - `NEXT_PUBLIC_SUPABASE_URL`, `NEXT_PUBLIC_SUPABASE_ANON_KEY`, `SUPABASE_SERVICE_ROLE_KEY` (del paso 3)
   - `ADMIN_EMAILS` → tu correo
   - `SESSION_SECRET` → un texto largo al azar (en Terminal: `openssl rand -base64 32`; si no tienes Terminal, escribe 40 letras y números al azar)
   - `NEXT_PUBLIC_APP_URL` → por ahora `https://uptenapp.vercel.app` (luego pones la dirección real que te dé Vercel, ver abajo)
4. **Deploy**. Vercel te da una dirección como `https://uptenapp-xxxx.vercel.app`.
5. Vuelve a **Settings → Environment Variables**, corrige `NEXT_PUBLIC_APP_URL` con esa dirección exacta (sin `/` al final) y haz **Redeploy**.

### 5. Comprobar que todo funciona

Abre `https://TU-DIRECCION.vercel.app/api/health`. Debes ver algo así:

```json
{"ok":true,"negocios":[{"slug":"cafe-demo","name":"Café Demo","stamps_required":8,"status":"active"}]}
```

Si ves `"ok": false`, el mensaje dice qué falta (normalmente una variable mal copiada).

---

## Trabajar en tu compu (opcional)

```bash
cd uptenapp
cp .env.example .env.local   # y llénalo
npm install
npm run dev                  # http://localhost:3000
```

## Apple Wallet

La guía completa (Pass Type ID, CSR con openssl, certificados, WWDR G4) se agrega en la Fase 1, cuando ya tengas tu cuenta de Apple Developer.

## Seguridad: qué NO subir nunca al repositorio

`.env.local`, archivos `.p12`, `.pem`, `.key`, `.csr`, `.cer`. El archivo `.gitignore` ya bloquea `.env*`; los certificados solo viven en variables de entorno (Vercel).
