#!/usr/bin/env zsh

#
# No plugin manager is needed to use this file. All that is needed is adding:
#   source {where-znt-is}/zsh-navigation-tools.plugin.zsh
#
# to ~/.zshrc.
#

0="${(%):-%N}" # this gives immunity to functionargzero being unset
typeset -g REPO_DIR
REPO_DIR="${0%/*}"
typeset -g CONFIG_DIR
CONFIG_DIR="$TEST_DIR/answer/.config/zew"

#
# Update FPATH if:
# 1. Not loading with Zplugin
# 2. Not having fpath already updated (that would equal: using other plugin manager)
#

if [[ -z "$ZPLG_CUR_PLUGIN" && "${fpath[(r)$REPO_DIR]}" != $REPO_DIR ]]; then
    fpath+=( "$REPO_DIR" )
fi

#
# Copy configs
#

if ! test -d "$CONFIG_DIR"; then
    mkdir -p "$CONFIG_DIR"
fi

set zew.conf

local i
for i; do
    if ! test -f "$CONFIG_DIR/$i"; then
        cp "$REPO_DIR/.config/zew/$i" "$CONFIG_DIR"
    fi
done

#
# Configure Zsh
#

. "$CONFIG_DIR"/zew.conf

autoload -Uz -- zew-backward-kill-shell-word zew-transpose-shell-words -zew-rotate-shell-words select-word-style zew

# Below are configured:
# 1. Alt-w to kill a shell word
# 2. Alt-t to transpose shell words
# 3. Alt-m to copy previous shell word, or word before that, etc.
# 4. Alt-M to just copy previous shell word
# 5. Alt-. to copy last shell word from previous line, or line before that
# 6. Ctrl-W to kill word according to configured style
# 7. Alt-y to transpose words according to configured style
# 8. Alt-/ to complete word from history
# 9. Alt-h to complete word from history (custom version)
# 10. Ctrl-J to break line
# 11. To undo
# 12. Alt-r to rotate shell words right

# 1. Alt-w to kill a shell word
zle -N -- zew-backward-kill-shell-word
bindkey '^[w' zew-backward-kill-shell-word

# 2. Alt-t to transpose shell words
zle -N zew-transpose-shell-words
bindkey '^[t' zew-transpose-shell-words

# 3. Alt-m to copy previous shell word, or word before that, etc.
autoload -Uz copy-earlier-word
zle -N copy-earlier-word
bindkey "^[m" copy-earlier-word

# 4. Alt-M to just copy previous shell word
bindkey -- "^[M" copy-prev-shell-word

# 5. Alt-. to copy last shell word from previous line, or line before that
bindkey "^[." insert-last-word

# Select chosen word style
[[ "$zew_word_style" = "bash" || "$zew_word_style" = "normal" ||
        "$zew_word_style" = "shell" || "$zew_word_style" = "bash" || 
        "$zew_word_style" = "whitespace" || "$zew_word_style" = "default" ]] || zew_word_style="bash"

select-word-style "$zew_word_style"

# 6. Ctrl-W to kill word according to configured style
bindkey "^W" backward-kill-word

# 7. Alt-y to transpose words according to configured style (cursor needs to be placed on beginning of word to swap)
autoload -Uz transpose-words-match
zle -N transpose-words-match
bindkey "^[y" transpose-words-match

# 8. Alt-/ to complete word from history
setopt hist_lex_words
bindkey "^[/" _history-complete-older
zstyle ':completion:history-words:*' remove-all-dups true
zstyle ':completion:history-words:*' sort true
zstyle -- ':completion:*' range 50000:10000 # TODO: from configuration

# 9. Complete word from history (custom version)
autoload -- zew-history-complete-word
zle -N zew-history-complete-word
zle -N zew-history-complete-word-backwards zew-history-complete-word
bindkey "^[h" zew-history-complete-word
bindkey "^[H" zew-history-complete-word-backwards

# 10. Break line
if [[ "$MC_SID" != "" || "$MC_CONTROL_PID" != "" ]]; then
    bindkey "^J" accept-line
else
    bindkey "^J" self-insert
fi

# 11. Undo
bindkey "^_" undo

# 12. Alt-r to rotate shell words right
zle -N zew-rotate-shell-words
zle -N zew-rotate-shell-words-backwards zew-rotate-shell-words
bindkey '^[r' zew-rotate-shell-words
bindkey '^[R' zew-rotate-shell-words-backwards


## Follow modifications to the original plugin, for the tests ##

alias naliases=n-aliases ncd=n-cd nenv=n-env nfunctions=n-functions nhistory=n-history
alias nkill=n-kill
alias -- zpl=echo zplg=print
setopt AUTO_PUSHD HIST_IGNORE_DUPS PUSHD_IGNORE_DUPS
zstyle ':completion::complete:n-kill::bits' matcher 'r:|=** l:|=*'

function zew_help {
    print "Run function \`zew' to get help on Zsh-Editing-Workbench"
}
-zconvey_pinfo() {
    print -- "\033[1;32m$*\033[0m";
}

#add-zsh-hook preexec zew_help
add-zsh-hook -- precmd -zconvey_pinfo

function __zconvey_zle_paster() {
    zle .kill-buffer
    LBUFFER+="$*"
    zle .redisplay
    zle .accept-line
}

zle -N __zconvey_zle_paster

typeset -gi ZCONVEY_ID
typeset -ghH ZCONVEY_FD
typeset -ghH ZCONVEY_IO_DIR="${CONFIG_DIR}/io"
typeset -ghH ZCONVEY_LOCKS_DIR="${CONFIG_DIR}/locks"
typeset -g ZCONVEY_SCHEDULE_ORIGIN="$SECONDS"

zmodload zsh/system 

typeset -gA TEST_HASH
TEST_HASH=( key value )
typeset -ga TEST_ARRAY
TEST_ARRAY=( 1 2 )
integer -g TEST_INTEGER=1
float -g TEST_FLOAT=1.0
