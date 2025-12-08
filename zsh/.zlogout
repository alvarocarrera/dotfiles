[[ -o INTERACTIVE && -t 2 ]] && {

  host="$(hostname)"

  # ──────────────────────────────────────────────
  # Mensajes para ROOT (UID 0)
  # ──────────────────────────────────────────────
  if [[ $EUID -eq 0 ]]; then
    case "$host" in
      atlas)
        cat <<-EOF

⚠️ Cerrando sesión de root en atlas
    Incluso un titán debe actuar con cuidado.

EOF
        ;;
      oceano)
        cat <<-EOF

⚠️ Cerrando sesión de root en oceano
    Que las profundidades sigan en calma.

EOF
        ;;
      prometeo)
        cat <<-EOF

⚠️ Cerrando sesión de root en prometeo
    El fuego está bajo control… por ahora.

EOF
        ;;
      cronos)
        cat <<-EOF

⚠️ Cerrando sesión de root en cronos
    El tiempo también observa tus acciones.

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
      cat <<-EOF

🗿 Cerrando sesión en atlas
    La carga del mundo espera tu regreso.

EOF
      ;;
    oceano)
      cat <<-EOF

🌊 Cerrando sesión en oceano
    El oleaje queda en calma.

EOF
      ;;
    prometeo)
      cat <<-EOF

🔥 Cerrando sesión en prometeo
    La llama sigue viva.

EOF
      ;;
    cronos)
      cat <<-EOF

⏳ Cerrando sesión en cronos
    El tiempo sigue su curso, estés o no.

EOF
      ;;
  esac
} >&2
