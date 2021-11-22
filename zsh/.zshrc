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
alias dc="docker-compose"
alias dcr="compose-run"
alias da="docker_start_attach"
alias daa="docker_apply_all_containers"
alias dci="docker_clean_images"
alias dcc="docker_clean_containers"
alias dac="docker_apply_containers"

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

#export PATH="/home/alvaro/.bin:/opt/eclipse:/opt/anaconda3/bin:$PATH" 
#tail -n +1 /home/alvaro/msg
#echo "Welcome Overlord!"
