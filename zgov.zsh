ZGOV_REGISTERED_PLUGINS=( )
ZGOV_REPORT=( )

ZGOV_HOME="$HOME/.zgov"
ZGOV_PLUGINS_DIR="$ZGOV_HOME/plugins"

ZGOV_CURRENT_USER=""
ZGOV_CURRENT_PLUGIN=""

#
# Shadow functions
#

zgov-shadow-autoload() {
    local i
    for i in "$@"; do
        ZGOV_REPORT+="Autoloading $i"
    done

    # Shadowed autoload
    for i in "$@"; do
        eval "$i() { "\
            "local FPATH='$ZGOV_HOME/plugins/${ZGOV_CURRENT_USER}--${ZGOV_CURRENT_PLUGIN}';"\
            "builtin autoload -X;"\
            "}"
    done
}

zgov-shadow-bindkey() {
    ZGOV_REPORT+="Bindkey $@"

    # Actual bindkey
    bindkey "$@"
}

zgov-shadow-setopt() {
    local i
    for i in "$@"; do
        ZGOV_REPORT+="setopt $i"
    done

    # Actual setopt
    setopt "$@"
}

# Shadowing on
zgov-shadow-on() {
    alias autoload=zgov-shadow-autoload
    alias bindkey=zgov-shadow-bindkey
    alias setopt=zgov-shadow-setopt
}

# Shadowing off
zgov-shadow-off() {
    unalias autoload bindkey setopt
}

#
# Zgov functions
#

zgov-prepare-home() {
    [ -n "$_ZGOV_HOME_READY" ] && return
    _ZGOV_HOME_READY="1"

    [ ! -d "$ZGOV_HOME" ] && mkdir 2>/dev/null "$ZGOV_HOME"
    [ ! -d "$ZGOV_PLUGINS_DIR" ] && mkdir 2>/dev/null "$ZGOV_PLUGINS_DIR"
}

zgov-setup-plugin-dir() {
    local user="$1" plugin="$2" github_path="$1/$2"
    if [ ! -d "$ZGOV_PLUGINS_DIR/${user}--${plugin}" ]; then
        cd "$ZGOV_PLUGINS_DIR"
        git clone https://github.com/"$github_path" "${user}--${plugin}"
    fi
}

zgov-register-plugin() {
    ZGOV_REGISTERED_PLUGINS+="$1/$2"
}

zgov-load-plugin() {
    local user="$1" plugin="$2"
    zgov-shadow-on
    ZGOV_CURRENT_USER="$user"
    ZGOV_CURRENT_PLUGIN="$plugin"
    source "$ZGOV_PLUGINS_DIR/${user}--${plugin}/${plugin}.plugin.zsh"
    zgov-shadow-off
}

zgov-show-report() {
    local user="$1" plugin="$2"
    echo "Plugin report for $user/$plugin"
    print -rl "${ZGOV_REPORT[@]}"
}

# $1 - plugin name, possibly github path
zgov-load () {
    local github_path="$1"

    local user="$1:h"
    local plugin="$1:t"

    # Name only? User can place a plugin
    # in plugins directory himself
    if [ "$user" = "$plugin" ]; then
        user="_local"
    fi

    zgov-setup-plugin-dir "$user" "$plugin"
    # Instead of fpath entries, there
    # are entries in ZGOV_REGISTERED_PLUGINS array
    zgov-register-plugin "$user" "$plugin"
    zgov-load-plugin "$user" "$plugin"
    zgov-show-report "$user" "$plugin"
}

# Main function with subcommands:
# - load
# - unload
zgov() {
    zgov-prepare-home

    case "$1" in
       (load)
           zgov-load "$2"
           ;;
       (unload)
           ;;
       (*)
           ;;
    esac

}
