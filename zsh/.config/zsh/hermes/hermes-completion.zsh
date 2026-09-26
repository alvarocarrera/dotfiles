# Hermes zsh completion: official `hermes completion zsh` + local extension.
#
# The extension only adds dynamic candidates:
#   hermes|<profile-alias> ... -r|--resume <TAB>   sessions from the profile's state.db
#                                                   (every source, incl. kanban/tool/oneshot)
#   hermes kanban show|tail <TAB>                   task ids from the active kanban board
# Everything else is delegated to the official _hermes function.
# All DB access is read-only (see hermes-complete.py next to this file).
# Sourced from ~/.zshrc; no-op on machines without hermes.

(( $+functions[compdef] )) || return 0
(( $+commands[hermes] )) || return 0

typeset -g _HERMES_COMP_HELPER="$HOME/.config/zsh/hermes/hermes-complete.py"
typeset -g _HERMES_COMP_CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/hermes-completion-official.zsh"
typeset -gA _hermes_alias_profile   # wrapper path -> profile name ("" = none)

# --- official completion, cached (generating it takes ~1s) ------------------
() {
  local stamp=$HOME/.hermes/hermes-agent/.git/logs/HEAD
  if [[ ! -s $_HERMES_COMP_CACHE ]]; then
    mkdir -p ${_HERMES_COMP_CACHE:h}
    hermes completion zsh >| $_HERMES_COMP_CACHE.tmp 2>/dev/null \
      && mv -f $_HERMES_COMP_CACHE.tmp $_HERMES_COMP_CACHE
  elif [[ -e $stamp && $stamp -nt $_HERMES_COMP_CACHE ]]; then
    # Hermes checkout moved: refresh in the background for the next shell.
    ( hermes completion zsh >| $_HERMES_COMP_CACHE.tmp 2>/dev/null \
        && mv -f $_HERMES_COMP_CACHE.tmp $_HERMES_COMP_CACHE ) &!
  fi
  [[ -s $_HERMES_COMP_CACHE ]] && source $_HERMES_COMP_CACHE
}
(( $+functions[_hermes] )) || return 0

# --- profile resolution (mirrors hermes_cli.main._apply_profile_override) ---
_hermes_comp_root() {
  local home=${HERMES_HOME:-}
  if [[ -n $home && ${home:A}/ != ${HOME:A}/.hermes/* && ${home:A} != ${HOME:A}/.hermes ]]; then
    [[ ${home:h:t} == profiles ]] && REPLY=${home:h:h} || REPLY=$home
  else
    REPLY=$HOME/.hermes
  fi
}

# Profile baked into a wrapper script such as ~/.local/bin/cluster.
_hermes_comp_alias_profile() {
  local file=${commands[$1]} content prof=
  REPLY=
  [[ -n $file && -f $file ]] || return 1
  if (( ! ${+_hermes_alias_profile[$file]} )); then
    content=$(<$file) 2>/dev/null
    if [[ $content != *hermes* ]]; then
      :
    elif [[ $content =~ '(^|[[:space:]])(-p|--profile)(=|[[:space:]]+)"?([A-Za-z0-9_.-]+)' ]]; then
      prof=${match[4]:l}
    elif [[ $content =~ 'HERMES_HOME=["'"'"']?[^"'"'"'[:space:]]*/profiles/([A-Za-z0-9_.-]+)' ]]; then
      prof=${match[1]:l}
    fi
    _hermes_alias_profile[$file]=$prof
  fi
  REPLY=${_hermes_alias_profile[$file]}
  [[ -n $REPLY ]]
}

# Sets REPLY to the HERMES_HOME the command line will use.
_hermes_comp_home() {
  local root prof= i w
  _hermes_comp_root; root=$REPLY
  for (( i = 2; i < CURRENT; i++ )); do
    w=${words[i]}
    [[ $w == -- ]] && break
    case $w in
      -p|--profile) prof=${words[i+1]}; break ;;
      --profile=*)  prof=${w#--profile=}; break ;;
    esac
  done
  prof=${(Q)prof}
  if [[ -z $prof && $words[1] != hermes ]]; then
    _hermes_comp_alias_profile $words[1] && prof=$REPLY
  fi
  if [[ -z $prof ]]; then
    if [[ -n $HERMES_HOME && ${HERMES_HOME:h:t} == profiles ]]; then
      REPLY=$HERMES_HOME; return
    fi
    [[ -r $root/active_profile ]] && prof=${${(f)"$(<$root/active_profile)"}[1]}
    prof=${${prof##[[:space:]]#}%%[[:space:]]#}
  fi
  prof=${prof:l}
  if [[ -z $prof || $prof == default ]]; then
    REPLY=$root
  else
    REPLY=$root/profiles/$prof
  fi
}

_hermes_comp_sessions() {
  local home db
  _hermes_comp_home; home=$REPLY
  db=$home/state.db
  [[ -r $db ]] || { _message "no state.db in $home"; return 1 }
  local -a cands
  cands=( ${(f)"$(python3 $_HERMES_COMP_HELPER sessions $db 2>/dev/null)"} )
  (( $#cands )) || { _message "no sessions in $db"; return 1 }
  _describe -V -t hermes-sessions "session (${${home:t}/.hermes/default})" cands
}

_hermes_comp_kanban_tasks() {
  local root board= db i
  _hermes_comp_root; root=${HERMES_KANBAN_HOME:-$REPLY}
  for (( i = 2; i < CURRENT; i++ )); do
    case ${words[i]} in
      --board)   board=${words[i+1]} ;;
      --board=*) board=${words[i]#--board=} ;;
    esac
  done
  if [[ -n $HERMES_KANBAN_DB && -z $board ]]; then
    db=$HERMES_KANBAN_DB
  else
    [[ -z $board ]] && board=${HERMES_KANBAN_BOARD:-}
    [[ -z $board && -r $root/kanban/current ]] && board=${${(f)"$(<$root/kanban/current)"}[1]}
    board=${${board##[[:space:]]#}%%[[:space:]]#}
    board=${board:l}
    if [[ -z $board || $board == default || ! -d $root/kanban/boards/$board ]]; then
      db=$root/kanban.db
    else
      db=$root/kanban/boards/$board/kanban.db
    fi
  fi
  [[ -r $db ]] || { _message "no kanban db"; return 1 }
  local -a cands
  cands=( ${(f)"$(python3 $_HERMES_COMP_HELPER kanban $db 2>/dev/null)"} )
  (( $#cands )) || { _message "no kanban tasks"; return 1 }
  _describe -V -t kanban-tasks 'kanban task' cands
}

# True when completing the first positional after `kanban show|tail`.
_hermes_comp_is_kanban_id() {
  local i k=0 sub= w
  for (( i = 2; i < CURRENT; i++ )); do
    [[ ${words[i]} == kanban ]] && { k=i; break }
  done
  (( k )) || return 1
  for (( i = k + 1; i < CURRENT; i++ )); do
    w=${words[i]}
    if [[ $w == --board ]]; then (( i++ )); continue; fi
    [[ $w == -* ]] && continue
    if [[ -z $sub ]]; then
      [[ $w == (show|tail) ]] || return 1
      sub=$w
    else
      return 1   # id already given
    fi
  done
  [[ -n $sub && ${words[CURRENT]} != -* ]]
}

_hermes_ext() {
  local prev=${words[CURRENT-1]}
  if [[ $prev == (-r|--resume) ]]; then
    _hermes_comp_sessions; return
  fi
  if [[ ${words[CURRENT]} == --resume=* ]]; then
    compset -P '--resume='
    _hermes_comp_sessions; return
  fi
  if _hermes_comp_is_kanban_id; then
    _hermes_comp_kanban_tasks; return
  fi
  _hermes "$@"
}

# hermes itself plus every profile wrapper in ~/.local/bin that pins a profile.
() {
  local -a cmds=(hermes) f
  for f in $HOME/.local/bin/*(N-.xLk-4); do
    [[ ${f:t} == hermes* ]] && continue
    _hermes_comp_alias_profile ${f:t} && [[ ${commands[${f:t}]} == $f ]] && cmds+=${f:t}
  done
  compdef _hermes_ext $cmds
}
