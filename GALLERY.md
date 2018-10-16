# Gallery Of Zplugin Invocations

```zsh
# PRs welcomed :)

# Programs

zplugin ice from"gh-r" as"program"
zplugin light junegunn/fzf-bin

zplugin ice from"gh-r" as"program" mv"docker* -> docker-compose"
zplugin light docker/compose

zplugin ice as"program" atclone"rm -f src/auto/config.cache; ./configure" atpull"%atclone" make pick"src/vim"
zplugin light vim/vim

zplugin ice as"program" make'!' atclone'./direnv hook zsh > zhook.zsh' atpull'%atclone' src"zhook.zsh"
zplugin light direnv/direnv

zplugin ice from"gh-r" as"program" mv"direnv* -> direnv"; zplugin light direnv/direnv

zplugin ice from"gh-r" as"program" mv"shfmt* -> shfmt"
zplugin light mvdan/sh

zplugin ice from"gh-r" as"program" mv"gotcha_* -> gotcha"
zplugin light b4b4r07/gotcha

zplugin ice as"program" pick"yank" make
zplugin light mptre/yank

zplugin ice wait"2" lucid as'command' pick'src/vramsteg' atclone'cmake .' atpull'%atclone' make  # use turbo-mode
zplugin light psprint/vramsteg-zsh

# Scripts

zplugin ice as"program" pick"$ZPFX/bin/git-*" make"PREFIX=$ZPFX" nocompile
zplugin light tj/git-extras

zplugin ice as"program" atclone'perl Makefile.PL PREFIX=$ZPFX' atpull'%atclone' make'install' pick"$ZPFX/bin/git-cal"
zplugin light k4rthik/git-cal

zplugin ice as"program" cp"wd.sh -> wd" pick"wd"
zplugin light mfaerevaag/wd

zplugin ice as"program" pick"bin/archey"
zplugin load obihann/archey-osx

# Plugins

zplugin ice pick"h.sh"
zplugin light paoloantinori/hhighlighter

# Snippets

zplugin ice svn pick"completion.zsh" src"git.zsh"
zplugin snippet OMZ::lib

zplugin ice svn wait"0" lucid atinit"local ZSH=\$PWD" \
    atclone"mkdir -p plugins; cd plugins; ln -sfn ../. osx"
zplugin snippet OMZ::plugins/osx

# Themes

GEOMETRY_COLOR_DIR=152
zplugin ice wait"0" lucid atload"prompt_geometry_render"
zplugin light geometry-zsh/geometry

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

zplugin ice from"gitlab" nocompletions atinit'fpath+=($PWD/p10k_functions $PWD/segments)'
zplugin load robobenklein/p10k
```
