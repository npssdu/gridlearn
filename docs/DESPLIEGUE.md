# Despliegue de GridLearn

GridLearn son dos piezas independientes:

| Pieza | Qué es | Dónde se despliega |
|---|---|---|
| **Base de datos + cuentas** | PostgreSQL y autenticación de **Supabase** (`supabase/migrations/`) | Supabase |
| **Aplicación** | Flutter web, sitio estático (`build/web`) | **Vercel** o **Render** |

La app habla directamente con Supabase. No hay servidor propio: la seguridad la
dan las políticas **RLS** de la base de datos, que se aplican aunque alguien
manipule el cliente.

> Trata esta carpeta (`gridlearn/`) como la **raíz del repositorio** que
> conectas a Vercel o Render.

---

## 1. Supabase (base de datos y cuentas)

1. Crea un proyecto en <https://supabase.com> (elige región cercana a tus usuarios).
2. Crea las tablas, políticas y funciones. Elige **una** vía:
   - **Panel**: *SQL Editor* → pega el contenido de
     `supabase/migrations/20260101000000_init_gridlearn.sql` → *Run*.
   - **CLI**:
     ```bash
     supabase init            # solo la primera vez
     supabase link --project-ref TU_REF
     supabase db push
     ```
3. Copia los valores públicos: *Project Settings → API*
   - **Project URL** → `SUPABASE_URL`
   - **Publishable key** (`sb_publishable_…`) o la clave **anon** → `SUPABASE_ANON_KEY`

   Estas dos son públicas por diseño. **Nunca** uses la clave `service_role` / `sb_secret_…`
   en la app (el script de compilación la rechaza).
4. Configura la autenticación (*Authentication*):
   - **Providers → Email**: activo. Mantén **Confirm email** activado.
   - **Sign In / Providers → Password requirements**: largo mínimo **8** y exige
     letras y números (igual que valida la app).
   - **URL Configuration**: pon como *Site URL* la dirección final de la app y
     añade a *Redirect URLs* esa misma dirección (y `http://localhost:*` para
     desarrollo). Es lo que hace funcionar los enlaces de confirmación y de
     "olvidé mi contraseña".
   - **Rate limits** y **CAPTCHA** (Auth → Attack Protection): actívalos si la app es pública.
   - **SMTP propio** (Auth → SMTP Settings): el correo integrado de Supabase está
     muy limitado; para producción usa un proveedor (Resend, Brevo, SES…).

### Modelo de datos

```
auth.users 1 ──< vocabularies 1 ──< vocabulary_words
```

- `vocabularies`: `id`, `user_id`, `title` (opcional, ≤120), `created_at`, `updated_at`.
- `vocabulary_words`: `id`, `vocabulary_id`, `user_id`, `position` (0 = primera casilla),
  `english`, `spanish`, `phonetic`.
- Función `save_vocabulary(p_id, p_title, p_words)`: guarda o actualiza un vocabulario
  y reemplaza sus palabras en **una sola transacción**.

### Probar el esquema

Las pruebas arrancan un PostgreSQL real (PGlite, no necesita Docker) y comprueban
aislamiento entre usuarios, restricciones, límites y borrado en cascada:

```bash
cd supabase/tests
npm install
npm test
```

---

## 2. Ejecutar en tu equipo

```bash
cp env.example.json env.json      # y rellena tus valores de Supabase
flutter run -d chrome --dart-define-from-file=env.json
```

Sin `env.json` la app arranca en **modo local**: sin cuentas, con los vocabularios
guardados solo en ese navegador. Sirve para desarrollar, no para producción.

---

## 3. Vercel

1. *Add New → Project* y elige el repositorio. En **Root Directory** deja la raíz de `gridlearn/`.
2. Vercel detecta `vercel.json` (build: `bash scripts/build-web.sh`, salida: `build/web`).
3. En *Settings → Environment Variables* añade `SUPABASE_URL` y `SUPABASE_ANON_KEY`
   (y opcionalmente `FLUTTER_VERSION`).
4. *Deploy*. Copia la URL final a *Site URL / Redirect URLs* de Supabase (paso 1.4).

El primer build descarga Flutter, por lo que tarda varios minutos.

## 4. Render

1. *New → Blueprint* y elige el repositorio: Render lee `render.yaml`
   (sitio estático, rewrite a `index.html` y cabeceras de seguridad).
2. Rellena `SUPABASE_URL` y `SUPABASE_ANON_KEY` cuando lo pida.
3. Al terminar, copia la URL a *Site URL / Redirect URLs* de Supabase.

## 5. ¿Y si quiero la base de datos en Render (PostgreSQL de Render)?

Render ofrece PostgreSQL gestionado y puedes crear las mismas tablas allí, **pero
este esquema depende de Supabase**: usa `auth.users` y `auth.uid()` para el inicio
de sesión y la seguridad por filas, y la app se conecta con el cliente de Supabase.
Un Postgres suelto no tiene API ni autenticación: tendrías que añadir un backend
propio (API + login con contraseñas/JWT) y cambiar `lib/services/`. No se incluye.
La app ya está separada en interfaces (`AuthService`, `VocabularyRepository`) para
que ese cambio sea acotado.

---

## Seguridad

**Ya incluido**

- **RLS en todas las tablas**: cada usuario solo lee/crea/modifica/borra sus filas;
  `anon` no tiene acceso. Una clave de API robada no da acceso a datos ajenos.
- **Integridad entre tablas**: una palabra no puede colgar del vocabulario de otra
  persona (clave foránea compuesta `(vocabulary_id, user_id)`).
- **Límites** (en la base, no solo en la app): título/palabras ≤120 caracteres,
  ≤500 palabras por vocabulario y ≤100 vocabularios por usuario.
- **Contraseñas**: las gestiona Supabase Auth (hash bcrypt); la app nunca las guarda.
  Mínimo 8 caracteres con letras y números; sesión con tokens renovables (PKCE).
- **Sin filtrar cuentas**: el inicio de sesión y el registro muestran mensajes genéricos
  ("Correo o contraseña incorrectos", "si el correo es válido te enviamos un enlace")
  para no revelar qué correos existen.
- **Aislamiento en el dispositivo**: el borrador local va separado por usuario y se
  borra al cerrar sesión; al cambiar de cuenta se crea un estado nuevo.
- **Cabeceras HTTP** (`vercel.json` / `render.yaml`): `X-Frame-Options: DENY`,
  `nosniff`, `Referrer-Policy`, `Permissions-Policy`, HSTS y COOP.
- **Sin secretos en el código**: solo se inyectan la URL y la clave pública; el
  script de compilación rechaza claves `service_role`/`sb_secret_`.

**Recomendado antes de salir a producción**

- Activa *Leaked password protection* (plan Pro) y CAPTCHA en Supabase.
- Usa SMTP propio y un dominio propio con HTTPS.
- Valora añadir una **Content-Security-Policy**. No va activada por defecto porque
  la impresión/PDF (`printing`) crea iframes `blob:` y Chrome puede bloquear su visor
  con directivas como `object-src 'none'`. Si la añades, pruébala con *Imprimir* y
  *Guardar como PDF*; punto de partida:
  `default-src 'self'; script-src 'self' 'wasm-unsafe-eval'; style-src 'self' 'unsafe-inline';
  img-src 'self' data: blob:; font-src 'self' data: https://fonts.gstatic.com;
  connect-src 'self' https://*.supabase.co wss://*.supabase.co https://fonts.googleapis.com https://fonts.gstatic.com;
  worker-src 'self' blob:; frame-src 'self' blob:; base-uri 'self'; form-action 'self'`.
- Haz copias de seguridad (Supabase las incluye en planes de pago) y revisa los *Logs*.
- Si publicas una nueva versión del esquema, añade un archivo nuevo en
  `supabase/migrations/` en lugar de editar el existente.
