#!/usr/bin/env bash
# Compila GridLearn para web. Lo usan Vercel y Render como "build command", y
# sirve también para compilar en tu equipo:
#
#   SUPABASE_URL=... SUPABASE_ANON_KEY=... bash scripts/build-web.sh
#
# Variables:
#   SUPABASE_URL, SUPABASE_ANON_KEY  Obligatorias (clave pública del proyecto).
#   FLUTTER_VERSION                  Versión de Flutter (por defecto 3.41.4).
#   ALLOW_LOCAL_MODE=1               Permite compilar sin Supabase (modo local,
#                                    sin cuentas). Solo para pruebas.
set -euo pipefail

FLUTTER_VERSION="${FLUTTER_VERSION:-3.41.4}"
FLUTTER_HOME="${FLUTTER_HOME:-$HOME/.flutter-sdk-$FLUTTER_VERSION}"

DEFINES=()
if [[ -n "${SUPABASE_URL:-}" && -n "${SUPABASE_ANON_KEY:-}" ]]; then
  DEFINES+=("--dart-define=SUPABASE_URL=${SUPABASE_URL}" "--dart-define=SUPABASE_ANON_KEY=${SUPABASE_ANON_KEY}")
elif [[ "${ALLOW_LOCAL_MODE:-0}" != "1" ]]; then
  echo "ERROR: faltan SUPABASE_URL y/o SUPABASE_ANON_KEY." >&2
  echo "       Sin ellas la app se publicaría en modo local (sin inicio de sesión)." >&2
  echo "       Defínelas en el panel de Vercel/Render, o usa ALLOW_LOCAL_MODE=1 a propósito." >&2
  exit 1
fi

# Seguridad: la clave service_role NUNCA debe llegar al navegador.
if [[ "${SUPABASE_ANON_KEY:-}" == *service_role* ]] || [[ "${SUPABASE_ANON_KEY:-}" == sb_secret_* ]]; then
  echo "ERROR: SUPABASE_ANON_KEY parece una clave secreta. Usa solo la clave pública (anon/publishable)." >&2
  exit 1
fi

if ! command -v flutter >/dev/null 2>&1; then
  if [[ ! -x "$FLUTTER_HOME/bin/flutter" ]]; then
    echo "Instalando Flutter $FLUTTER_VERSION en $FLUTTER_HOME ..."
    git clone --depth 1 --branch "$FLUTTER_VERSION" https://github.com/flutter/flutter.git "$FLUTTER_HOME"
  fi
  export PATH="$FLUTTER_HOME/bin:$PATH"
fi

# Evita que Flutter se queje de ejecutarse como root dentro de contenedores de CI.
export CI=true
flutter --version
flutter config --no-analytics --enable-web >/dev/null
flutter precache --web
flutter pub get

# --no-web-resources-cdn: incluye CanvasKit en el despliegue (no depende de gstatic.com).
flutter build web --release --no-web-resources-cdn ${DEFINES[@]+"${DEFINES[@]}"}

echo "Listo: build/web"
