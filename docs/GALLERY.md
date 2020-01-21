# Gallery Of Zinit Invocations

PRs welcomed :)

## Programs

```zsh
zinit ice from"gh-r" as"program"
zinit light junegunn/fzf-bin

# sharkdp/fd
zinit ice as"command" from"gh-r" mv"fd* -> fd" pick"fd/fd"
zinit light sharkdp/fd

# sharkdp/bat
zinit ice as"command" from"gh-r" mv"bat* -> bat" pick"bat/bat"
zinit light sharkdp/bat

# ogham/exa, replacement for ls
zinit ice wait"2" lucid from"gh-r" as"program" mv"exa* -> exa"
zinit light ogham/exa

zinit ice from"gh-r" as"program" mv"docker* -> docker-compose"
zinit light docker/compose

zinit ice as"program" atclone"rm -f src/auto/config.cache; ./configure" \
    atpull"%atclone" make pick"src/vim"
zinit light vim/vim

zinit ice as"program" make'!' atclone'./direnv hook zsh > zhook.zsh' \
    atpull'%atclone' src"zhook.zsh"
zinit light direnv/direnv

zinit ice from"gh-r" as"program" mv"direnv* -> direnv"
zinit light direnv/direnv

zinit ice from"gh-r" as"program" mv"shfmt* -> shfmt"
zinit light mvdan/sh

zinit ice from"gh-r" as"program" mv"gotcha_* -> gotcha"
zinit light b4b4r07/gotcha

zinit ice as"program" pick"yank" make
zinit light mptre/yank

zinit ice wait"2" lucid as'command' pick'src/vramsteg' \
    atclone'cmake .' atpull'%atclone' make  # use Turbo mode
zinit light psprint/vramsteg-zsh

zinit ice atclone'PYENV_ROOT="$PWD" ./libexec/pyenv init - > zpyenv.zsh' \
    atinit'export PYENV_ROOT="$PWD"' atpull"%atclone" \
    as'command' pick'bin/pyenv' src"zpyenv.zsh" nocompile'!'
zinit light pyenv/pyenv

zinit ice as"program" pick"$ZPFX/sdkman/bin/sdk" id-as'sdkman' run-atpull \
    atclone"wget https://get.sdkman.io -O scr.sh; SDKMAN_DIR=$ZPFX/sdkman bash scr.sh" \
    atpull"SDKMAN_DIR=$ZPFX/sdkman sdk selfupdate" \
    atinit"export SDKMAN_DIR=$ZPFX/sdkman; source $ZPFX/sdkman/bin/sdkman-init.sh"
zinit light zdharma/null

# asciinema
zinit ice as"command" wait lucid \
    atinit"export PYTHONPATH=$ZPFX/lib/python3.7/site-packages/" \
    atclone"PYTHONPATH=$ZPFX/lib/python3.7/site-packages/ \
    python3 setup.py --quiet install --prefix $ZPFX" \
    atpull'%atclone' test'0' \
    pick"$ZPFX/bin/asciinema"
zinit load asciinema/asciinema.git
```

## Completions

```zsh
zinit ice as"completion"
zinit snippet https://github.com/docker/cli/blob/master/contrib/completion/zsh/_docker
```

## Scripts

```zsh
# ogham/exa also uses the definitions
zinit ice wait"0c" lucid reset \
    atclone"local P=${${(M)OSTYPE:#*darwin*}:+g}
            \${P}sed -i \
            '/DIR/c\DIR 38;5;63;1' LS_COLORS; \
            \${P}dircolors -b LS_COLORS > c.zsh" \
    atpull'%atclone' pick"c.zsh" nocompile'!' \
    atload'zstyle ":completion:*" list-colors “${(s.:.)LS_COLORS}”'
zinit light trapd00r/LS_COLORS

# revolver
zinit ice wait"2" lucid as"program" pick"revolver"
zinit light molovo/revolver

# zunit
zinit ice wait"2" lucid as"program" pick"zunit" \
            atclone"./build.zsh" atpull"%atclone"
zinit load molovo/zunit

zinit ice as"program" pick"$ZPFX/bin/git-*" make"PREFIX=$ZPFX" nocompile
zinit light tj/git-extras

zinit ice as"program" atclone'perl Makefile.PL PREFIX=$ZPFX' \
    atpull'%atclone' make'install' pick"$ZPFX/bin/git-cal"
zinit light k4rthik/git-cal

zinit ice as"program" id-as"git-unique" pick"git-unique"
zinit snippet https://github.com/Osse/git-scripts/blob/master/git-unique

zinit ice as"program" cp"wd.sh -> wd" mv"_wd.sh -> _wd" \
    atpull'!git reset --hard' pick"wd"
zinit light mfaerevaag/wd

zinit ice as"program" pick"bin/archey"
zinit load obihann/archey-osx
```

## Plugins

```zsh
zinit ice pick"h.sh"
zinit light paoloantinori/hhighlighter

# zsh-tag-search; after ^G, prepend with "/" for the regular search
zinit ice wait lucid bindmap"^R -> ^G"
zinit light -b zdharma/zsh-tag-search

# forgit
zinit ice wait lucid
zinit load 'wfxr/forgit'

# diff-so-fancy
zinit ice wait"2" lucid as"program" pick"bin/git-dsf"
zinit load zdharma/zsh-diff-so-fancy

# zsh-startify, a vim-startify like plugin
zinit ice wait"0b" lucid atload"zsh-startify"
zinit load zdharma/zsh-startify

# declare-zsh
zinit ice wait"2" lucid
zinit load zdharma/declare-zsh

# fzf-marks
zinit ice wait lucid
zinit load urbainvaes/fzf-marks

# zsh-autopair
zinit ice wait lucid
zinit load hlissner/zsh-autopair

zinit ice wait"1" lucid
zinit load psprint/zsh-navigation-tools

# zdharma/history-search-multi-word
zstyle ":history-search-multi-word" page-size "11"
zinit ice wait"1" lucid
zinit load zdharma/history-search-multi-word

# ZUI and Crasis
zinit ice wait"1" lucid
zinit load zdharma/zui

zinit ice wait'[[ -n ${ZLAST_COMMANDS[(r)cra*]} ]]' lucid
zinit load zdharma/zinit-crasis

# Gitignore plugin – commands gii and gi
zinit ice wait"2" lucid
zinit load voronkovich/gitignore.plugin.zsh

# Autosuggestions & fast-syntax-highlighting
zinit ice wait"1" lucid atinit"ZPLGM[COMPINIT_OPTS]=-C; zpcompinit; zpcdreplay"
zinit light zdharma/fast-syntax-highlighting
# zsh-autosuggestions
zinit ice wait"1" lucid atload"!_zsh_autosuggest_start"
zinit load zsh-users/zsh-autosuggestions

# F-Sy-H automatic themes plugin – available for patrons:
# https://patreon.com/psprint
zinit ice wait"1" lucid from"psprint@gitlab.com"
zinit load psprint/fsh-auto-themes

# zredis together with some binding/tying
# – defines the variable $rdhash
zstyle ":plugin:zredis" configure_opts "--without-tcsetpgrp"
zstyle ":plugin:zredis" cflags  "-Wall -O2 -g -Wno-unused-but-set-variable"
zinit ice wait"1" lucid \
    atload'ztie -d db/redis -a 127.0.0.1:4815/5 -zSL main rdhash'
zinit load zdharma/zredis

# Github-Issue-Tracker – the notifier thread
zinit ice lucid id-as"GitHub-notify" \
        on-update-of'~/.cache/zsh-github-issues/new_titles.log' \
        notify'New issue: $NOTIFY_MESSAGE'
zinit light zdharma/zsh-github-issues
```

## Services

```zsh
# a service that runs the redis database, in background, single instance
zinit ice wait"1" lucid service"redis"
zinit light zservices/redis
```

```zsh
# Github-Issue-Tracker – the issue-puller thread
GIT_SLEEP_TIME=700
GIT_PROJECTS=zdharma/zsh-github-issues:zdharma/zinit

zinit ice wait"2" lucid service"GIT" pick"zsh-github-issues.service.zsh"
zinit light zdharma/zsh-github-issues
```

## Snippets

```zsh
zinit ice svn pick"completion.zsh" src"git.zsh"
zinit snippet OMZ::lib

zinit ice svn wait"0" lucid atinit"local ZSH=\$PWD" \
    atclone"mkdir -p plugins; cd plugins; ln -sfn ../. osx"
zinit snippet OMZ::plugins/osx

# Or with most recent Zinit and with ~/.zinit/snippets
# directory pruned (rm -rf -- ${ZPLGM[SNIPPETS_DIR]}):
zinit ice svn
zinit snippet OMZ::plugins/osx
```

## Themes

```zsh
GEOMETRY_COLOR_DIR=152
zinit ice wait"0" lucid atload"geometry::prompt"
zinit light geometry-zsh/geometry

zinit ice pick"async.zsh" src"pure.zsh"
zinit light sindresorhus/pure

zinit light mafredri/zsh-async  # dependency
zinit ice svn silent atload'prompt sorin'
zinit snippet PZT::modules/prompt

zinit ice atload"fpath+=( \$PWD );"
zinit light chauncey-garrett/zsh-prompt-garrett
zinit ice svn atload"prompt garrett" silent
zinit snippet PZT::modules/prompt

zinit ice wait'!' lucid nocompletions \
         compile"{zinc_functions/*,segments/*,zinc.zsh}" \
         atload'!prompt_zinc_setup; prompt_zinc_precmd'
zinit load robobenklein/zinc

# ZINC git info is already async, but if you want it
# even faster with gitstatus in Turbo mode:
# https://github.com/romkatv/gitstatus
zinit ice wait'1' atload'zinc_optional_depenency_loaded'
zinit load romkatv/gitstatus

# After finishing the configuration wizard change the atload'' ice to:
# -> atload'source ~/.p10k.zsh; _p9k_precmd'
zinit ice wait'!' lucid atload'true; _p9k_precmd' nocd
zinit light romkatv/powerlevel10k
```

[]( vim:set ft=markdown tw=80: )
