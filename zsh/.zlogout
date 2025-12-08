[[ -o INTERACTIVE && -t 2 ]] && {
  case "$(hostname)" in
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
