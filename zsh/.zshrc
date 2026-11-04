#
# Executes commands at the start of an interactive session.
#
# Authors:
#   Sorin Ionescu <sorin.ionescu@gmail.com>
#

plugins=(git docker docker-compose)

# Source Prezto.
if [[ -s "${ZDOTDIR:-$HOME}/.zprezto/init.zsh" ]]; then
  source "${ZDOTDIR:-$HOME}/.zprezto/init.zsh"
fi

# Customize to your needs...

eval $(dircolors ~/.dircolors)

if which pyenv >/dev/null ; then
    eval "$(pyenv virtualenv-init -)"
fi

alias gitpush-origin-master="git push -u origin master"
alias dps="docker ps"
alias dpi="docker images"
alias dc="docker compose"
alias dcr="compose-run"
alias da="docker_start_attach"
alias daa="docker_apply_all_containers"
alias dci="docker_clean_images"
alias dcc="docker_clean_containers"
alias dac="docker_apply_containers"
alias dip="docker image prune"
alias hermes-bridge='python3 "$HOME/repos/hermes-admin/scripts/hermes-work-bridge.py" wrapper'

function docker_start_attach () {
    docker start $1 && docker attach $1
}

function drmia () {
    docker rmi $(docker images | grep "^<none>" | awk '{print $3}')
}

function newdev () {
    docker run -v $PWD:/usr/src/app -t -i --name $1 -h $1 alvarocarrera/devmachine
}

function docker_apply_containers () {
    if [[ "$#" -lt 1 ]];
    then
        echo "Usage: $0 <filter> <action>"
        return
    fi
    containers=$(docker ps -a | grep -v 'CONTAINER' | awk "/$1/{ print \$0}")
    echo -n $containers
    if [[ "$#" -gt 1 ]];
       then
           shift;
           echo $containers | awk '{print $1}' | xargs docker "$@"
    fi
    #| xargs docker rmi "$@"
}

function docker_apply_images () {
    if [[ "$#" -lt 1 ]];
    then
        echo "Usage: $0 <filter> <action>"
        return
    fi
    images=$(docker images -a | grep -v 'REPOSITORY' | awk "/$1/{ print \$0}")
    echo -n $images
    if [[ "$#" -gt 1 ]];
       then
           shift;
           echo $images | awk '{print $3}' | xargs docker "$@"
    fi
    #| xargs docker rmi "$@"
}

function docker_clean_containers () {
    docker rm $(docker ps -q --filter=status=exited)
}

function docker_clean_images () {
    docker rmi $(docker images -a --filter=dangling=true -q)
}

function docker_nuke () {
    docker rmi $(docker images -q)
}

function attach-tmux {
    readonly session=${1:?"Session must be specified."}
    tmux attach -t "$session"
}

function prometeo-ssh-login () {
    ssh alvaro@prometeo
}

function atlas-ssh-login () {
    ssh alvaro@atlas
}

function start-pal-dev-docker-machine () {
    bash /home/alvaro/repos/investigacion/amor-robots/pal_docker_utils/scripts/pal_docker.sh -it -d -v /home/alvaro/docker_mounts/gallium:/home/user/ -v /home/alvaro/pal-workspace:/home/user/example_ws/ --name pal-dev-machine registry.gitlab.com/pal-robotics/ari-1922/dockers/pal-gallium-pal-metapkg-development-ari-41-dev
}

function attach-pal-dev () {
    docker exec -it pal-dev-machine bash
}

function ari-ssh-login {
    ssh pal@ari-${1:-42}c
}

function protege-launch () {
    /home/alvaro/Protege-5.6.4/run.sh > /dev/null &
}

function cesvima-ssh () {
    ssh vpsadmin@gsi.upm.es
}
function widoco-launch () {
  docker run -ti --rm -v ./src:/usr/local/widoco/in:Z -v ./doc:/usr/local/widoco/out:Z ghcr.io/dgarijo/widoco:latest -confFile in/widoco-amor-config.properties -ontFile in/amor.n3 -outFolder out -rewriteAll
}

lpprint () {
  local file="" copies=1 printer="" mode="duplex" color_mode="${PRINT_COLOR:-mono}" quality="" raster=0 arg

  while [[ $# -gt 0 ]]; do
    case "$1" in
      -f|--file)    file="$2"; shift 2 ;;
      -n|--copies)  copies="$2"; shift 2 ;;
      -p|--printer) printer="$2"; shift 2 ;;
      -q|--quality) quality="$2"; shift 2 ;;
      -c|--color)   color_mode="color"; shift ;;
      -m|--mono)    color_mode="mono"; shift ;;
      -d|--duplex)  mode="duplex"; shift ;;
      -s|--single)  mode="single"; shift ;;
      -r|--raster)  raster=1; shift ;;

      file=*)     file="${1#file=}"; shift ;;
      copies=*)   copies="${1#copies=}"; shift ;;
      printer=*)  printer="${1#printer=}"; shift ;;
      quality=*)  quality="${1#quality=}"; shift ;;
      mode=*|sides=*) mode="${1#*=}"; shift ;;
      color=*)
        color_mode="${1#color=}"
        case "$color_mode" in
          gray|grey) color_mode="mono" ;;
          rgb)       color_mode="color" ;;
        esac
        shift
        ;;

      --help|-h)
        echo "Uso: lpprint [archivo] [IMPRESORA] [-d|-s] [-n N] [-c|-m] [-q draft|normal|high] [-p IMPRESORA] [-r]"
        echo "  -r  rasteriza el PDF a imagen antes de imprimir (para PDFs que la impresora ignora); cada pagina sale por separado a una cara"
        return 0
        ;;

      *=*) shift ;;
      *)
        if [[ -z "$file" && -f "$1" ]]; then
          file="$1"
        elif [[ -z "$printer" && "$1" != -* ]]; then
          printer="$1"
        fi
        shift
        ;;
    esac
  done

  [[ -z "$printer" ]] && printer="HP_B208_M478f"

  if [[ -z "$file" || ! -f "$file" ]]; then
    echo "Error: debes indicar un archivo existente."
    return 2
  fi

  local -a opts
  case "$color_mode" in
    mono)  opts+=(-o ColorModel=Gray) ;;
    color) opts+=(-o ColorModel=RGB) ;;
    *) echo "Modo color inválido: $color_mode"; return 3 ;;
  esac

  if [[ -n "$quality" ]]; then
    case "$quality" in
      draft|Draft)   opts+=(-o cupsPrintQuality=Draft) ;;
      normal|Normal) opts+=(-o cupsPrintQuality=Normal) ;;
      high|High)     opts+=(-o cupsPrintQuality=High) ;;
      *) echo "quality inválida: $quality"; return 4 ;;
    esac
  fi

  case "$mode" in
    duplex|two-sided|2) opts+=(-o sides=two-sided-long-edge) ;;
    single|one-sided|1) opts+=(-o sides=one-sided) ;;
    *) echo "Modo inválido: $mode"; return 5 ;;
  esac

  if (( raster )); then
    local tmp img rc=0
    tmp=$(mktemp -d) || return 6
    pdftoppm -jpeg -r 300 "$file" "$tmp/p" || { rm -rf "$tmp"; return 7; }
    for img in "$tmp"/p*.jpg; do
      lp -d "$printer" -n "$copies" "${opts[@]}" -o sides=one-sided -o fit-to-page -o media=A4 "$img" || rc=$?
    done
    sleep 2; rm -rf "$tmp"
    return $rc
  fi

  lp -d "$printer" -n "$copies" "${opts[@]}" "$file"
}

# Aliases for print from console
alias pr='lpprint'
alias print-from-console='lpprint'

# Aliases for OpenClaw
alias oc='openclaw'
alias oclogs='openclaw logs --follow --local-time'

[[ -r "$HOME/.config/zsh/local.zsh" ]] && source "$HOME/.config/zsh/local.zsh"

for f in "$HOME/.config/zsh/local.d/"*.zsh(N); do
  source "$f"
done

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# Hermes Agent command
export PATH="$HOME/.local/bin:$PATH"

# Hermes completion (official + session/kanban ids); no-op without hermes
[[ -r "$HOME/.config/zsh/hermes/hermes-completion.zsh" ]] && source "$HOME/.config/zsh/hermes/hermes-completion.zsh"

# Claude Code mediante OpenRouter
claude-or() {
    local key

    if [[ -n "${OPENROUTER_API_KEY:-}" ]]; then
        key="$OPENROUTER_API_KEY"
    elif [[ -r "$HOME/.config/claude-openrouter/token" ]]; then
        key="$(< "$HOME/.config/claude-openrouter/token")"
    else
        read -rs "key?OpenRouter API key: "
        printf '\n'
    fi

    [[ -n "$key" ]] || return 1

    ANTHROPIC_BASE_URL="https://openrouter.ai/api" \
    ANTHROPIC_AUTH_TOKEN="$key" \
    ANTHROPIC_API_KEY="" \
    ANTHROPIC_MODEL="~anthropic/claude-sonnet-latest" \
    CLAUDE_CODE_ENABLE_GATEWAY_MODEL_DISCOVERY=1 \
    command claude "$@"
}

# Load the local Hermes MCP token only for these agent processes.
function codex claude() (
  local token_file="$HOME/.config/hermes-admin/work-bridge.env"
  if [[ -r "$token_file" ]]; then
    set -a
    source "$token_file"
    set +a
  fi
  command "$0" "$@"
)

command -v batcat >/dev/null 2>&1 && alias cat='batcat'  # bat
