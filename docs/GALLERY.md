# Gallery Of Zplugin Invocations

PRs welcomed :)

## Programs

```zsh
zplugin ice from"gh-r" as"program"
zplugin light junegunn/fzf-bin

# sharkdp/fd
zplugin ice as"command" from"gh-r" mv"fd* -> fd" pick"fd/fd"
zplugin light sharkdp/fd

# sharkdp/bat
zplugin ice as"command" from"gh-r" mv"bat* -> bat" pick"bat/bat"
zplugin light sharkdp/bat

# ogham/exa, replacement for ls
zplugin ice wait"2" lucid from"gh-r" as"program" mv"exa* -> exa"
zplugin light ogham/exa

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

# asciinema
zplugin ice as"command" wait lucid \
    atinit"export PYTHONPATH=$ZPFX/lib/python3.7/site-packages/" \
    atclone"PYTHONPATH=$ZPFX/lib/python3.7/site-packages/ \
    python3 setup.py --quiet install --prefix $ZPFX" \
    atpull'%atclone' test'0' \
    pick"$ZPFX/bin/asciinema"
zplugin load asciinema/asciinema.git
```

## Completions

```zsh
zplugin ice as"completion"
zplugin snippet https://github.com/docker/cli/blob/master/contrib/completion/zsh/_docker
```

## Scripts

```zsh
# ogham/exa also uses the definitions
zplugin ice wait"0c" lucid reset \
    atclone"local P=${${(M)OSTYPE:#*darwin*}:+g}
            \${P}sed -i \
            '/DIR/c\DIR 38;5;63;1' LS_COLORS; \
            \${P}dircolors -b LS_COLORS > c.zsh" \
    atpull'%atclone' pick"c.zsh" nocompile'!' \
    atload'zstyle ":completion:*" list-colors “${(s.:.)LS_COLORS}”'
zplugin light trapd00r/LS_COLORS

# revolver
zplugin ice wait"2" lucid as"program" pick"revolver"
zplugin light molovo/revolver

# zunit
zplugin ice wait"2" lucid as"program" pick"zunit" \
            atclone"./build.zsh" atpull"%atclone"
zplugin load molovo/zunit

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

# zsh-tag-search; after ^G, prepend with "/" for the regular search
zplugin ice wait lucid bindmap"^R -> ^G"
zplugin light -b zdharma/zsh-tag-search

# forgit
zplugin ice wait lucid
zplugin load 'wfxr/forgit'

# diff-so-fancy
zplugin ice wait"2" lucid as"program" pick"bin/git-dsf"
zplugin load zdharma/zsh-diff-so-fancy

# zsh-startify, a vim-startify like plugin
zplugin ice wait"0b" lucid atload"zsh-startify"
zplugin load zdharma/zsh-startify

# declare-zsh
zplugin ice wait"2" lucid
zplugin load zdharma/declare-zsh

# fzf-marks
zplugin ice wait lucid
zplugin load urbainvaes/fzf-marks

# zsh-autopair
zplugin ice wait lucid
zplugin load hlissner/zsh-autopair

zplugin ice wait"1" lucid
zplugin load psprint/zsh-navigation-tools

# zdharma/history-search-multi-word
zstyle ":history-search-multi-word" page-size "11"
zplugin ice wait"1" lucid
zplugin load zdharma/history-search-multi-word

# ZUI and Crasis
zplugin ice wait"1" lucid
zplugin load zdharma/zui

zplugin ice wait'[[ -n ${ZLAST_COMMANDS[(r)cra*]} ]]' lucid
zplugin load zdharma/zplugin-crasis

# Gitignore plugin – commands gii and gi
zplugin ice wait"2" lucid
zplugin load voronkovich/gitignore.plugin.zsh

# Autosuggestions & fast-syntax-highlighting
zplugin ice wait"1" lucid atinit"ZPLGM[COMPINIT_OPTS]=-C; zpcompinit; zpcdreplay"
zplugin light zdharma/fast-syntax-highlighting
# zsh-autosuggestions
zplugin ice wait"1" lucid atload"!_zsh_autosuggest_start"
zplugin load zsh-users/zsh-autosuggestions

# F-Sy-H automatic themes plugin – available for patrons:
# https://patreon.com/psprint
zplugin ice wait"1" lucid from"psprint@gitlab.com"
zplugin load psprint/fsh-auto-themes

# zredis together with some binding/tying
# – defines the variable $rdhash
zstyle ":plugin:zredis" configure_opts "--without-tcsetpgrp"
zstyle ":plugin:zredis" cflags  "-Wall -O2 -g -Wno-unused-but-set-variable"
zplugin ice wait"1" lucid \
    atload'ztie -d db/redis -a 127.0.0.1:4815/5 -zSL main rdhash'
zplugin load zdharma/zredis

# Github-Issue-Tracker – the notifier thread
zplugin ice lucid id-as"GitHub-notify" \
        on-update-of'~/.cache/zsh-github-issues/new_titles.log' \
        notify'New issue: $NOTIFY_MESSAGE'
zplugin light zdharma/zsh-github-issues
```

## Services

```zsh
# a service that runs the redis database, in background, single instance
zplugin ice wait"1" lucid service"redis"
zplugin light zservices/redis
```

```zsh
# Github-Issue-Tracker – the issue-puller thread
GIT_SLEEP_TIME=700
GIT_PROJECTS=zdharma/zsh-github-issues:zdharma/zplugin

zplugin ice wait"2" lucid service"GIT" pick"zsh-github-issues.service.zsh"
zplugin light zdharma/zsh-github-issues
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

zplugin ice wait'!' lucid nocompletions \
         compile"{zinc_functions/*,segments/*,zinc.zsh}" \
         atload'!prompt_zinc_setup; prompt_zinc_precmd'
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
