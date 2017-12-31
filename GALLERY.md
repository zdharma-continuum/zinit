# Gallery Of Zplugin Invocations

```zsh
# PRs welcomed :)

# Commands

zplugin ice from"gh-r" as"command"
zplugin load junegunn/fzf-bin

zplugin ice from"gh-r" as"command" mv"docker* -> docker-compose"
zplugin load docker/compose

zplugin ice as"command" atclone"./configure" atpull"%atclone" make pick"src/vim"
zplugin light vim/vim

zplugin ice as"command" pick"${ZPLGM[HOME_DIR]}/cmd/bin/git-*" make"PREFIX=${ZPLGM[HOME_DIR]}/cmd"
zplugin light tj/git-extras

zplugin ice as"command" make'!' atclone'./direnv hook zsh > zhook.zsh' atpull'%atclone' src"zhook.zsh"
zplugin light direnv/direnv

zplugin ice from"gh-r" as"command" mv"shfmt* -> shfmt"
zplugin light mvdan/sh

zplugin ice from"gh-r" as"command" mv"gotcha_* -> gotcha"
zplugin light b4b4r07/gotcha

zplg ice as"command" cp"wd.sh -> wd" pick"wd"
zplg light mfaerevaag/wd

# Snippets

zplg ice svn pick"completion.zsh" src"git.zsh"
zplg snippet OMZ::lib

# Themes

zplugin ice pick"async.zsh" src"pure.zsh"
zplugin light sindresorhus/pure

zplg ice pick"powerless.zsh" src"utilities.zsh"
zplg load martinrotter/powerless

zplg light mafredri/zsh-async  # dependency
zplg ice svn silent atload'prompt sorin'
zplg snippet PZT::modules/prompt

```
