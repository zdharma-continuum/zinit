# Gallery Of Zplugin Invocations

```zsh
# PRs welcomed :)

# Commands

zplugin ice from"gh-r" as"command"
zplugin light junegunn/fzf-bin

zplugin ice from"gh-r" as"command" mv"docker* -> docker-compose"
zplugin light docker/compose

zplugin ice as"command" atclone"rm -f src/auto/config.cache; ./configure" atpull"%atclone" make pick"src/vim"
zplugin light vim/vim

zplugin ice as"command" pick"${ZPLGM[HOME_DIR]}/cmd/bin/git-*" make"PREFIX=${ZPLGM[HOME_DIR]}/cmd"
zplugin light tj/git-extras

zplugin ice as"command" make'!' atclone'./direnv hook zsh > zhook.zsh' atpull'%atclone' src"zhook.zsh"
zplugin light direnv/direnv

zplugin ice from"gh-r" as"command" mv"direnv* -> direnv"; zplugin light direnv/direnv

zplugin ice from"gh-r" as"command" mv"shfmt* -> shfmt"
zplugin light mvdan/sh

zplugin ice from"gh-r" as"command" mv"gotcha_* -> gotcha"
zplugin light b4b4r07/gotcha

zplugin ice as"command" cp"wd.sh -> wd" pick"wd"
zplugin light mfaerevaag/wd

# Plugins

zplugin ice pick"h.sh"
zplugin light paoloantinori/hhighlighter

# Snippets

zplugin ice svn pick"completion.zsh" src"git.zsh"
zplugin snippet OMZ::lib

# Themes

zplugin ice pick"async.zsh" src"pure.zsh"
zplugin light sindresorhus/pure

zplugin ice pick"powerless.zsh" src"utilities.zsh"
zplugin light martinrotter/powerless

zplugin light mafredri/zsh-async  # dependency
zplugin ice svn silent atload'prompt sorin'
zplugin snippet PZT::modules/prompt

zplugin ice atload"fpath+=( \$PWD );"
zplugin light chauncey-garrett/zsh-prompt-garrett
zplugin ice svn atload"prompt garrett"
zplugin snippet PZT::modules/prompt
```
