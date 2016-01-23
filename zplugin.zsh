ZPLUGIN_REGISTERED_PLUGINS=( )
ZPLUGIN_REPORT=( )

ZPLUGIN_HOME="$HOME/.zplugin"
ZPLUGIN_PLUGINS_DIR="$ZPLUGIN_HOME/plugins"

ZPLUGIN_CURRENT_USER=""
ZPLUGIN_CURRENT_PLUGIN=""

#
# Shadow functions
#

zplugin-shadow-autoload() {
    local i
    for i in "$@"; do
        ZPLUGIN_REPORT+="Autoloading $i"
    done

    # Shadowed autoload
    for i in "$@"; do
        functions[$i]=" 
            local FPATH='$ZPLUGIN_HOME/plugins/${ZPLUGIN_CURRENT_USER}--${ZPLUGIN_CURRENT_PLUGIN}'
            builtin autoload -X
        "
    done
}

zplugin-shadow-bindkey() {
    ZPLUGIN_REPORT+="Bindkey $@"

    # Actual bindkey
    bindkey "$@"
}

zplugin-shadow-setopt() {
    local i
    for i in "$@"; do
        ZPLUGIN_REPORT+="setopt $i"
    done

    # Actual setopt
    setopt "$@"
}

# Shadowing on
zplugin-shadow-on() {
    alias autoload=zplugin-shadow-autoload
    alias bindkey=zplugin-shadow-bindkey
    alias setopt=zplugin-shadow-setopt
}

# Shadowing off
zplugin-shadow-off() {
    unalias autoload bindkey setopt
}

#
# Zgov functions
#

zplugin-prepare-home() {
    [ -n "$_ZPLUGIN_HOME_READY" ] && return
    _ZPLUGIN_HOME_READY="1"

    [ ! -d "$ZPLUGIN_HOME" ] && mkdir 2>/dev/null "$ZPLUGIN_HOME"
    [ ! -d "$ZPLUGIN_PLUGINS_DIR" ] && mkdir 2>/dev/null "$ZPLUGIN_PLUGINS_DIR"
}

zplugin-setup-plugin-dir() {
    local user="$1" plugin="$2" github_path="$1/$2"
    if [ ! -d "$ZPLUGIN_PLUGINS_DIR/${user}--${plugin}" ]; then
        cd "$ZPLUGIN_PLUGINS_DIR"
        git clone https://github.com/"$github_path" "${user}--${plugin}"
    fi
}

zplugin-register-plugin() {
    ZPLUGIN_REGISTERED_PLUGINS+="$1/$2"
}

zplugin-load-plugin() {
    local user="$1" plugin="$2"
    zplugin-shadow-on
    ZPLUGIN_CURRENT_USER="$user"
    ZPLUGIN_CURRENT_PLUGIN="$plugin"
    source "$ZPLUGIN_PLUGINS_DIR/${user}--${plugin}/${plugin}.plugin.zsh"
    zplugin-shadow-off
}

zplugin-show-report() {
    local user="$1" plugin="$2"
    echo "Plugin report for $user/$plugin"
    print -rl "${ZPLUGIN_REPORT[@]}"
}

# $1 - plugin name, possibly github path
zplugin-load () {
    local github_path="$1"

    local user="$1:h"
    local plugin="$1:t"

    # Name only? User can place a plugin
    # in plugins directory himself
    if [ "$user" = "$plugin" ]; then
        user="_local"
    fi

    zplugin-setup-plugin-dir "$user" "$plugin"
    # Instead of fpath entries, there
    # are entries in ZPLUGIN_REGISTERED_PLUGINS array
    zplugin-register-plugin "$user" "$plugin"
    zplugin-load-plugin "$user" "$plugin"
    zplugin-show-report "$user" "$plugin"
}

# Main function with subcommands:
# - load
# - unload
zplugin() {
    zplugin-prepare-home

    case "$1" in
       (load)
           zplugin-load "$2"
           ;;
       (unload)
           ;;
       (*)
           ;;
    esac

}
