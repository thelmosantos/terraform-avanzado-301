#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# setup-aws-profiles.sh — se ejecuta al crear el dev container (postCreateCommand)
#
# Filosofía del curso: NO te damos las credenciales hechas. El dev container trae
# los binarios; tú aprendes las DISTINTAS VÍAS de inyectar credenciales:
#
#   1) GitHub Codespaces  -> "Codespaces secrets" (llegan como variables de entorno)
#   2) Local (Docker)     -> archivo .env cargado por direnv dentro del contenedor
#   3) (Opcional) Asunción de rol -> define AWS_ROLE_ARN y se configura un perfil
#
# Este script NO falla si aún no hay credenciales: solo informa de cómo ponerlas.
# ------------------------------------------------------------------------------
set -uo pipefail

bold() { printf '\033[1m%s\033[0m\n' "$1"; }
ok()   { printf '  \033[32m✔\033[0m %s\n' "$1"; }
warn() { printf '  \033[33m!\033[0m %s\n' "$1"; }
info() { printf '  \033[36m•\033[0m %s\n' "$1"; }

echo
bold "== Dev container Terraform Avanzado — verificación de entorno =="

# --- Binarios -----------------------------------------------------------------
bold "Herramientas instaladas:"
for bin in terraform aws ansible tflint jq; do
  if command -v "$bin" >/dev/null 2>&1; then
    ver=$("$bin" --version 2>/dev/null | head -n1)
    ok "$bin — ${ver}"
  else
    warn "$bin no encontrado"
  fi
done

# --- ¿Dónde estamos? ----------------------------------------------------------
echo
if [ "${CODESPACES:-}" = "true" ]; then
  bold "Entorno detectado: GitHub Codespaces"
else
  bold "Entorno detectado: local / Docker"
fi

# --- Región -------------------------------------------------------------------
REGION="${AWS_REGION:-${AWS_DEFAULT_REGION:-}}"
if [ -n "$REGION" ]; then
  ok "Región AWS: $REGION"
else
  warn "No hay región definida (AWS_REGION / AWS_DEFAULT_REGION). El curso usa, p. ej., eu-west-1."
fi

# --- (Opcional) Asunción de rol ----------------------------------------------
# Si te dan un rol que asumir, exporta AWS_ROLE_ARN (y opcionalmente AWS_ROLE_SESSION_NAME).
# Se crea un perfil 'lab' que asume ese rol usando tus credenciales base.
if [ -n "${AWS_ROLE_ARN:-}" ]; then
  echo
  bold "Configurando perfil 'lab' para asumir rol:"
  mkdir -p "$HOME/.aws"
  {
    echo "[profile lab]"
    echo "role_arn = ${AWS_ROLE_ARN}"
    echo "credential_source = Environment"
    [ -n "$REGION" ] && echo "region = ${REGION}"
    echo "role_session_name = ${AWS_ROLE_SESSION_NAME:-tf-curso}"
  } > "$HOME/.aws/config"
  ok "Perfil 'lab' creado en ~/.aws/config (úsalo con: export AWS_PROFILE=lab)"
fi

# --- ¿Hay credenciales? -------------------------------------------------------
echo
bold "Comprobando acceso a AWS:"
if aws sts get-caller-identity >/tmp/_idn 2>/tmp/_iderr; then
  ok "Autenticado en AWS como:"
  jq -r '"      Account: \(.Account)\n      Arn:     \(.Arn)"' /tmp/_idn 2>/dev/null || cat /tmp/_idn
else
  warn "Todavía no hay acceso a AWS. Es normal si aún no has puesto credenciales."
  echo
  info "VÍA 1 — Codespaces secrets (recomendado en Codespaces):"
  info "   Settings → Codespaces → Secrets: AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY,"
  info "   (AWS_SESSION_TOKEN si es temporal) y AWS_REGION. Reabre el Codespace."
  echo
  info "VÍA 2 — Local con .env + direnv:"
  info "   cp .env.example .env  &&  edita .env  &&  direnv allow"
  echo
  info "VÍA 3 — Asunción de rol: exporta AWS_ROLE_ARN y reabre el contenedor."
  echo
  info "Detalle del último error (si lo hubo):"
  sed 's/^/      /' /tmp/_iderr 2>/dev/null | head -n3
fi
rm -f /tmp/_idn /tmp/_iderr 2>/dev/null || true

# --- Recordatorios ------------------------------------------------------------
echo
bold "Siguiente paso:"
info "Comprueba que tienes los permisos necesarios para los labs:"
info "   ./scripts/check-aws-permissions.sh"
warn "La cuenta AWS del curso solo vive en la ventana de clase. Fuera de ella, el acceso fallará (es esperado)."
echo
exit 0
