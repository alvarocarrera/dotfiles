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
    bash /home/alvaro/git/amor-robots/pal_docker_utils/scripts/pal_docker.sh -it -d -v /home/alvaro/docker_mounts/gallium:/home/user/ -v /home/alvaro/pal-workspace:/home/user/example_ws/ --name pal-dev-machine registry.gitlab.com/pal-robotics/ari-1922/dockers/pal-gallium-pal-metapkg-development-ari-41-dev
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

openclaw() {
  docker exec -it openclaw-gateway node dist/index.js "$@"
}

lpprint () {
  local file="" copies=1 printer="" mode="duplex" color_mode="${PRINT_COLOR:-mono}" quality=""
  local last="" arg

  for arg in "$@"; do last="$arg"; done

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
        echo "Uso: lpprint [archivo] [-d|-s] [-n N] [-c|-m] [-q draft|normal|high] [-p IMPRESORA]"
        return 0
        ;;

      *=*) shift ;;
      *)
        if [[ -z "$file" && -f "$1" ]]; then file="$1"; fi
        shift
        ;;
    esac
  done

  if [[ -z "$printer" && -n "$last" && "$last" != *=* && "$last" != --* && "$last" != -* && ! -f "$last" ]]; then
    printer="$last"
  fi
  [[ -z "$printer" ]] && printer="HP_B208_M478f"

  if [[ -z "$file" || ! -f "$file" ]]; then
    echo "Error: debes indicar un archivo existente."
    return 2
  fi

  local color_option=""
  case "$color_mode" in
    mono)  color_option="-o ColorModel=Gray" ;;
    color) color_option="-o ColorModel=RGB" ;;
    *) echo "Modo color inválido: $color_mode"; return 3 ;;
  esac

  local quality_option=""
  if [[ -n "$quality" ]]; then
    case "$quality" in
      draft|Draft)   quality_option="-o cupsPrintQuality=Draft" ;;
      normal|Normal) quality_option="-o cupsPrintQuality=Normal" ;;
      high|High)     quality_option="-o cupsPrintQuality=High" ;;
      *) echo "quality inválida: $quality"; return 4 ;;
    esac
  fi

  local sides_option=""
  case "$mode" in
    duplex|two-sided|2) sides_option="-o sides=two-sided-long-edge" ;;
    single|one-sided|1) sides_option="-o sides=one-sided" ;;
    *) echo "Modo inválido: $mode"; return 5 ;;
  esac

  lp -d "$printer" -n "$copies" \
     $sides_option \
     $color_option \
     $quality_option \
     "$file"
}

alias pr='lpprint'
alias print-from-console='lpprint'
