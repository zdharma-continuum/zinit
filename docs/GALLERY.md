# Gallery Of Zinit Invocations

PRs welcomed :)

## Programs

```zsh
# junegunn/fzf-bin
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

# All of the above using the for-syntax and also z-a-bin-gem-node annex
zinit wait"1" lucid from"gh-r" as"null" for \
     sbin"fzf"          junegunn/fzf-bin \
     sbin"**/fd"        @sharkdp/fd \
     sbin"**/bat"       @sharkdp/bat \
     sbin"exa* -> exa"  ogham/exa

zinit ice from"gh-r" as"program" mv"docker* -> docker-compose"
zinit light docker/compose

# jarun/nnn, a file browser, using the for-syntax
zinit pick"misc/quitcd/quitcd.zsh" sbin make light-mode for jarun/nnn

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
    atclone"wget https://get.sdkman.io/?rcupdate=false -O scr.sh; SDKMAN_DIR=$ZPFX/sdkman bash scr.sh" \
    atpull"SDKMAN_DIR=$ZPFX/sdkman sdk selfupdate" \
    atinit"export SDKMAN_DIR=$ZPFX/sdkman; source $ZPFX/sdkman/bin/sdkman-init.sh"
zinit light zdharma-continuum/null

# asciinema
zinit ice as"command" wait lucid \
    atinit"export PYTHONPATH=$ZPFX/lib/python3.7/site-packages/" \
    atclone"PYTHONPATH=$ZPFX/lib/python3.7/site-packages/ \
    python3 setup.py --quiet install --prefix $ZPFX" \
    atpull'%atclone' test'0' \
    pick"$ZPFX/bin/asciinema"
zinit load asciinema/asciinema.git

# Installation of Rust compiler environment via the z-a-rust annex
zinit id-as"rust" wait=1 as=null sbin="bin/*" lucid rustup \
    atload="[[ ! -f ${ZINIT[COMPLETIONS_DIR]}/_cargo ]] && zi creinstall -q rust; \
    export CARGO_HOME=\$PWD; export RUSTUP_HOME=\$PWD/rustup" for \
        zdharma-continuum/null
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
zinit light -b zdharma-continuum/zsh-tag-search

# forgit
zinit ice wait lucid
zinit load 'wfxr/forgit'

# diff-so-fancy
zinit ice wait"2" lucid as"program" pick"bin/git-dsf"
zinit load zdharma-continuum/zsh-diff-so-fancy

# zsh-startify, a vim-startify like plugin
zinit ice wait"0b" lucid atload"zsh-startify"
zinit load zdharma-continuum/zsh-startify

# declare-zsh
zinit ice wait"2" lucid
zinit load zdharma-continuum/declare-zsh

# fzf-marks
zinit ice wait lucid
zinit load urbainvaes/fzf-marks

# zsh-autopair
zinit ice wait lucid
zinit load hlissner/zsh-autopair

zinit ice wait"1" lucid
zinit load psprint/zsh-navigation-tools

# zdharma-continuum/history-search-multi-word
zstyle ":history-search-multi-word" page-size "11"
zinit ice wait"1" lucid
zinit load zdharma-continuum/history-search-multi-word

# ZUI and Crasis
zinit ice wait"1" lucid
zinit load zdharma-continuum/zui

zinit ice wait'[[ -n ${ZLAST_COMMANDS[(r)cra*]} ]]' lucid
zinit load zdharma-continuum/zinit-crasis

# Gitignore plugin – commands gii and gi
zinit ice wait"2" lucid
zinit load voronkovich/gitignore.plugin.zsh

# Autosuggestions & fast-syntax-highlighting
zinit ice wait lucid atinit"ZPLGM[COMPINIT_OPTS]=-C; zpcompinit; zpcdreplay"
zinit light zdharma-continuum/fast-syntax-highlighting
# zsh-autosuggestions
zinit ice wait lucid atload"!_zsh_autosuggest_start"
zinit load zsh-users/zsh-autosuggestions

# F-Sy-H automatic per-directory themes plugin – available for patrons:
# https://patreon.com/psprint
zinit ice wait"1" lucid from"psprint@gitlab.com"
zinit load psprint/fsh-auto-themes

# zredis together with some binding/tying
# – defines the variable $rdhash
zstyle ":plugin:zredis" configure_opts "--without-tcsetpgrp"
zstyle ":plugin:zredis" cflags  "-Wall -O2 -g -Wno-unused-but-set-variable"
zinit ice wait"1" lucid \
    atload'ztie -d db/redis -a 127.0.0.1:4815/5 -zSL main rdhash'
zinit load zdharma-continuum/zredis

# Github-Issue-Tracker – the notifier thread
zinit ice lucid id-as"GitHub-notify" \
        on-update-of'~/.cache/zsh-github-issues/new_titles.log' \
        notify'New issue: $NOTIFY_MESSAGE'
zinit light zdharma-continuum/zsh-github-issues
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
zinit light zdharma-continuum/zsh-github-issues
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

# Loading a local snippet located at $HOME/external/snippet.zsh
# using symlinks (instead of copying the snippet)
zinit ice link
zinit snippet $HOME/external/snippet.zsh

# For-syntax for symlinking local snippets
zinit light-mode for \
    is-snippet link id-as'mysnippet' \
        $HOME/external/snippet.zsh

# Complex example
# A bit convoluted -- mainly here to demonstrate some zinit-fu.
#
# sharkdp/vivid's latest gh-r doesn't package all the themes found in its master
# branch.  But, we definitely don't want to compile it from scratch (or, if you
# do, see z-a-rust).  So, we use a plugin with id-as'vivid-bin' to download the
# release from github, and we use z-a-bin-gem-node to sbin it into our PATH.
# Next, we still want to clone the repo, so we use another plugin, but this time
# with id-as'vivid-themes' to clone the repo.
#
# Through the rest of this section, I'll refer to ZINIT[PLUGIN_DIR] as ZPD, and
# ZINIT[SNIPPETS_DIR] as ZSD.

zinit depth'3' light-mode for \
    zdharma-continuum/zinit-annex-bin-gem-node \
    zdharma-continuum/zinit-annex-default-ice \
    NICHOLAS85/z-a-eval \
    ;

zinit default-ice -q depth'3' lucid light-mode

zinit wait as'null' for \
    id-as'vivid-bin' from'gh-r' sbin"**/vivid" \
        @sharkdp/vivid \
    id-as'vivid-themes' \
        @sharkdp/vivid

# So far, this has nothing to do with snippets or the link ice.  But, now we
# have a vivid shim in $ZPFX/bin/vivid, the vivid binary extracted at
# ZPD/vivid-bin/ and the vivid repo containing the latest themese cloned at
# ZPD/vivid-themes.
#
# We can now use a snippet to symlink it into the snippet cache so that we can
# call vivid to generate our LS_COLORS.

zinit for \
    wait'
        (( $+commands[vivid] )) &&
        [[ -f $ZINIT[PLUGINS_DIR]/vivid-themes/themes/ayu.yml ]]
    ' \
    is-snippet \
    id-as'vivid-theme-ayu' \
    link \
    as'null' \
    nocompile \
    eval'echo "export LS_COLORS=\"$(vivid generate vivid-theme-ayu)\""' \
    atload'zstyle ":completion:*" list-colors "${(s.:.)LS_COLORS}"' \
        ${ZINIT[PLUGINS_DIR]}/vivid-themes/themes/ayu.yml

# Here's a step-by-step breakdown of what's going on here:
#
# 1. wait'...'
#
# Allows us to (1) wait until the vivid command is available, and (b) wait until
# we have cloned our repo and our theme file exists.
#
# 2. is-snippet
#    id-as'vivid-theme-ayu'
#    link
#
# Here, we declare that we're loading a snippet and that it's id should be
# vivid-theme-ayu.  This will prompt zinit to create a directory
# ZSD/vivid-theme-ayu and cache the snippet into that directory under the
# filename ZSD/vivid-theme-ayu/vivid-theme-ayu.  Note, it uses the id-as
# both for the directory name as well as the filename.
#
# Now, since we're using the link ice, we don't actually copy the file, but
# instead symlink it.  Previously, we used the vivid-themes plugin to clone
# the vivid repository, so we can expect to find our ayu theme at:
#
#     ZPD/vivid-themes/themes/ayu.yml
#
# So far, our snippet directory looks like:
#
#     ZSD/vivid-theme-ayu/vivid-theme-ayu -> ZPD/vivid-themes/themes/ayu.yml
#
# Note, in reality the symlink is relative (not absolute).  Assuming your ZSD
# and ZPD directories are next to each other, the actual link target should
# look something like ../../plugins/vivid-themes/themes/ayu.yml
#
# 3. as'null'
#    nocompile
#
# The snippet we're loading isn't actually a script at all.  It's the theme file
# for vivid.  This disables the loading.  Obviously, we don't want to compile
# this.
#
# 4. eval'echo "export LS_COLORS=\"$(vivid generate vivid-theme-ayu)\""'
#
# Now we're getting really cool.  We add z-a-eval as well so that we don't make
# vivid regenerate the LS_COLORS output at each new shell.  We just need to
# cache the output.  Luckily, this is exactly what z-a-eval does.
#
# z-a-eval will cache the output of the eval ice and store it in the snippet
# directory as evalcache.zsh.
#
#     ZSD/vivid-theme-ayu/evalcache.zsh
#
# The eval command itself is invoked from the context of the snippet's
# directory, and our snippet has taken care of symlinking the ayu theme into
# our snippet directory as vivid-theme-ayu.  Note, there's no .yml because the
# snippet always takes the id-as name of the snippet.
#
# Now, on each subsequent invocation of the shell, we won't run vivid anymore,
# but will simply source the evalcache which will load our LS_COLORS.
#
# 5. atload'...'
#
# Lastly, we can still take advantage of an atload (which is not affected by
# z-a-eval's caching) to run zstyle to convert our LS_COLORS into list-colors
# style for zsh's completion system.
#
# Extra Credit:
#
# Technically, we don't need to wait on the vivid command to be available on
# subsequent invocations of the shell.  We can alter our wait condition to:
#
#    wait'
#        (( $+commands[vivid] )) &&
#        [[ -f $ZINIT[PLUGINS_DIR]/vivid-themes/themes/ayu.yml ]] ||
#        [[ -f $ZINIT[SNIPPETS_DIR]/vivid-theme-ayu/evalcache.zsh ]]
#    ' \
#
# If for some reason, we delete our vivid binary, our LS_COLORS won't wait until
# it is available again to load.
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
