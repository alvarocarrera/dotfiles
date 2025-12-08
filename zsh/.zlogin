# Mostrar mensaje solo en shells interactivos con TTY
[[ -o INTERACTIVE && -t 2 ]] || return

case "$HOST" in
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
