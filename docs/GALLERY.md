# Gallery Of Zplugin Invocations

PRs welcomed :)

## Programs

```zsh
zplugin ice from"gh-r" as"program"
zplugin light junegunn/fzf-bin

zplugin ice from"gh-r" as"program" mv"docker* -> docker-compose"
zplugin light docker/compose

zplugin ice as"program" atclone"rm -f src/auto/config.cache; ./configure" \
    atpull"%atclone" make pick"src/vim"
zplugin light vim/vim

zplugin ice as"program" make'!' atclone'./direnv hook zsh > zhook.zsh' \
    atpull'%atclone' src"zhook.zsh"
zplugin light direnv/direnv

zplugin ice from"gh-r" as"program" mv"direnv* -> direnv"
zplugin light direnv/direnv

zplugin ice from"gh-r" as"program" mv"shfmt* -> shfmt"
zplugin light mvdan/sh

zplugin ice from"gh-r" as"program" mv"gotcha_* -> gotcha"
zplugin light b4b4r07/gotcha

zplugin ice as"program" pick"yank" make
zplugin light mptre/yank

zplugin ice wait"2" lucid as'command' pick'src/vramsteg' \
    atclone'cmake .' atpull'%atclone' make  # use Turbo mode
zplugin light psprint/vramsteg-zsh

zplugin ice atclone"./libexec/pyenv init - > zpyenv.zsh" \
    atinit'export PYENV_ROOT="$PWD"' atpull"%atclone" \
    as'command' pick'bin/pyenv' src"zpyenv.zsh" nocompile'!'
zplugin light pyenv/pyenv

zplugin ice as"program" pick"$ZPFX/sdkman/bin/sdk" id-as'sdkman' run-atpull \
    atclone"wget https://get.sdkman.io -O scr.sh; SDKMAN_DIR=$ZPFX/sdkman bash scr.sh" \
    atpull"SDKMAN_DIR=$ZPFX/sdkman sdk selfupdate" \
    atinit"export SDKMAN_DIR=$ZPFX/sdkman; source $ZPFX/sdkman/bin/sdkman-init.sh"
zplugin light zdharma/null
```

## Completions

```zsh
zplugin ice as"completion"
zplugin snippet https://github.com/docker/cli/blob/master/contrib/completion/zsh/_docker
```

## Scripts

```zsh
# For GNU ls (the binaries can be gls, gdircolors, e.g. on OS X when installing the
# coreutils package from Homebrew or using https://github.com/ogham/exa)
zplugin ice atclone"dircolors -b LS_COLORS > c.zsh" \
    atpull'%atclone' pick"c.zsh" nocompile'!' \
    atload'zstyle ":completion:*" list-colors “${(s.:.)LS_COLORS}”' # Style the Zsh completion
zplugin light trapd00r/LS_COLORS

zplugin ice as"program" pick"$ZPFX/bin/git-*" make"PREFIX=$ZPFX" nocompile
zplugin light tj/git-extras

zplugin ice as"program" atclone'perl Makefile.PL PREFIX=$ZPFX' \
    atpull'%atclone' make'install' pick"$ZPFX/bin/git-cal"
zplugin light k4rthik/git-cal

zplugin ice as"program" id-as"git-unique" pick"git-unique"
zplugin snippet https://github.com/Osse/git-scripts/blob/master/git-unique

zplugin ice as"program" cp"wd.sh -> wd" mv"_wd.sh -> _wd" \
    atpull'!git reset --hard' pick"wd"
zplugin light mfaerevaag/wd

zplugin ice as"program" pick"bin/archey"
zplugin load obihann/archey-osx
```

## Plugins

```zsh
zplugin ice pick"h.sh"
zplugin light paoloantinori/hhighlighter
```

## Snippets

```zsh
zplugin ice svn pick"completion.zsh" src"git.zsh"
zplugin snippet OMZ::lib

zplugin ice svn wait"0" lucid atinit"local ZSH=\$PWD" \
    atclone"mkdir -p plugins; cd plugins; ln -sfn ../. osx"
zplugin snippet OMZ::plugins/osx

# Or with most recent Zplugin and with ~/.zplugin/snippets 
# directory pruned (rm -rf -- ${ZPLGM[SNIPPETS_DIR]}):
zplugin ice svn
zplugin snippet OMZ::plugins/osx
```

## Themes

```zsh
GEOMETRY_COLOR_DIR=152
zplugin ice wait"0" lucid atload"geometry::prompt"
zplugin light geometry-zsh/geometry

zplugin ice pick"async.zsh" src"pure.zsh"
zplugin light sindresorhus/pure

zplugin light mafredri/zsh-async  # dependency
zplugin ice svn silent atload'prompt sorin'
zplugin snippet PZT::modules/prompt

zplugin ice atload"fpath+=( \$PWD );"
zplugin light chauncey-garrett/zsh-prompt-garrett
zplugin ice svn atload"prompt garrett" silent
zplugin snippet PZT::modules/prompt

zplugin ice nocompletions compile"{zinc_functions/*,segments/*,zinc.zsh}"
zplugin load robobenklein/zinc

# ZINC git info is already async, but if you want it 
# even faster with gitstatus in Turbo mode:
# https://github.com/romkatv/gitstatus
zplugin ice wait'1' atload'zinc_optional_depenency_loaded'
zplugin load romkatv/gitstatus

# After finishing the configuration wizard change the atload'' ice to:
# -> atload'source ~/.p10k.zsh; _p9k_precmd'
zplugin ice wait'!' lucid atload'true; _p9k_precmd' nocd
zplugin light romkatv/powerlevel10k
```

[]( vim:set ft=markdown tw=80: )
