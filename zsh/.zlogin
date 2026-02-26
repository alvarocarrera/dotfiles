# Mostrar mensaje solo en shells interactivos con TTY
[[ -o INTERACTIVE && -t 2 ]] || return

host="$HOST"

# ──────────────────────────────────────────────
# Mensajes para ROOT
# ──────────────────────────────────────────────
if [[ $EUID -eq 0 ]]; then
  case "$host" in
    atlas)
      cat <<'EOF'
⚠️ Entrando como root en atlas
    Incluso los titanes pisan con cuidado.
EOF
      ;;
    oceano)
      cat <<'EOF'
⚠️ Entrando como root en oceano
    Las profundidades requieren respeto.
EOF
      ;;
    prometeo)
      cat <<'EOF'
⚠️ Entrando como root en prometeo
    El fuego puede crear… o destruir.
EOF
      ;;
    cronos)
      cat <<'EOF'
⚠️ Entrando como root en cronos
    Hasta el tiempo teme a ciertos errores.
EOF
      ;;
  esac

  return
fi

# ──────────────────────────────────────────────
# Mensajes para usuarios normales
# ──────────────────────────────────────────────
case "$host" in
  atlas)
    cat <<'EOF'
🗿 Entrando en atlas
    Que el peso del cielo hoy sea ligero.
EOF
    ;;
  oceano)
    cat <<'EOF'
🌊 Entrando en oceano
    Que las mareas te reciban en calma.
EOF
    ;;
  prometeo)
    cat <<'EOF'
🔥 Entrando en prometeo
    Que la chispa del ingenio te acompañe.
EOF
    ;;
  cronos)
    cat <<'EOF'
⏳ Entrando en cronos
    Que el tiempo discurra a tu favor.
EOF
    ;;
esac
