<!-- START doctoc generated TOC please keep comment here to allow auto update -->

<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->

**Table of Contents** *generated with [DocToc](https://github.com/thlorenz/doctoc)*

- [Changelog](#changelog)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

# Changelog

All notable changes to this project will be documented in this file.

- 29-11-2021
  - zinit calls no longer silently fail when ices such as `atclone`, `atpull` or `compile` fail. Any hook returning with
    != 0 will log a warning to stdout at runtime:

```zsh
zinit null atclone'echo "intentional failure"; return 69' \
  for zdharma-continuum/null
echo $?
69
```

- 28-11-2021
  - **‼️ BREAKING CHANGE** zinit now requires [jq](https://github.com/stedolan/jq) for JSON parsing. This only affects
    the `pack` ice. Users who do not have jq installed will be greeted with a warning when they try to install packages.
    To install jq with zinit, you can follow
    [these instructions in the wiki](https://github.com/zdharma-continuum/zinit/wiki/%F0%9F%A7%8A-Recommended-ices#jq)
  - `zinit pack` now better supports installation from local files (previously only relative paths worked), and **custom
    repositories!** By default, zinit uses
    [zhdarma-continuum/zinit-packages](https://github.com/p/zdharma-continuum/zinit-packages).

To use a custom repo you can set `ZINIT[PACKAGES_REPO]=github_org/repo`.

For installing from a specific branch you can:

1. Leverage the `ver` ice (eg: `ver"my-branch`)
1. Override zinit's default branch with `ZINIT[PACKAGES_BRANCH]=my-branch`

zinit package repos that are not hosted on GitHub can be installed from the local filesystem like so:
`zinit pack"local/path/to/package.json:profile" for mypackage`

- 22-11-2021
  - We updated zinit's main branch from `master` to `main`. `zinit self-update` will try to update the branch locally.
    If it fails please try to:

```zsh
cd ${ZINIT[BIN_DIR]}
git branch -m master main
git fetch origin
git branch -u origin/main main
git remote set-head origin -a
```

- 21-11-2021

  - [(z)unit tests](https://github.com/zdharma-continuum/zinit/actions/workflows/tests.yaml) have been added to our dear
    repository. This should help us to sniff out some bugs and improve the overall quality of zinit. Stay tuned! More
    information available [here](https://github.com/zdharma-continuum/zinit/pull/96).

- 20-11-2021

  - zinit is now [XDG compliant](https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html). This
    means that the default value of `ZINIT[HOME_DIR]` is now `XDG_DATA_HOME/zinit`, ie `HOME/.local/share/zinit`, we
    won't clutter your `HOME` anymore! Fear not though: if you update zinit without moving your config to the new
    default location it will still fall back to `HOME/.zinit` if this directory exists. In the same spirit, if you
    overrode `ZINIT[HOME_DIR]` yourself in your `zshrc` we will use that value instead. NOTE: Since its rewrite the
    installer has been installing zinit's repo to `XDG_DATA_HOME/zinit/zinit.git` (see 16-11-2021 entry)

- 18-11-2021

  - The packages (`zinit pack`) have all been migrated to
    [a new repository](https://github.com/zdharma-continuum/zinit-packages). Nothing fundamentally changes for users,
    the original repos have only been archived and not deleted, so that older zinit versions can still use these.

For more information, please refer to [this issue](https://github.com/zdharma-continuum/zinit/issues/69) and/or to
[the corresponding PR](https://github.com/zdharma-continuum/zinit/pull/75)

- The zinit module has been relocated to [its own repository](https://github.com/zdharma-continuum/zinit-module)

* 17-11-2021
  - Containers! If you want to try out zinit inside a container, you can now. Several versions of zsh are available, as
    well as arm64. Check out the available tags on
    [ghcr](https://github.com/zdharma-continuum/zinit/pkgs/container/zinit).

```shell
docker run -it --rm ghcr.io/zdharma-continuum/zinit:latest
```

- 16-11-2021
  - A brand-new installer has been developed. A few new features have been added. There are a bunch of new env vars you
    can set:

    - `NO_INPUT=1`: non-interactive mode (`NO_INPUT=1`)
    - `NO_EDIT=1`: do not modify `.zshrc`
    - `ZSHRC=/home/user01/.config/zsh/zshrc`: custom path to your `.zshrc`
    - `ZINIT_REPO=zdharma-continuum/zinit`: Install zinit from a custom GitHub repo
    - `ZINIT_BRANCH=master`: zinit branch to install
    - `ZINIT_COMMIT=master`: zinit commit to install (takes precedence over `ZINIT_BRANCH`)
    - `ZINIT_INSTALL_DIR=~/.local/share/zinit/zinit.git`: Where to install the zinit repo

⚠️ Please note that the download URL for the installer has changed. It is now:
https://raw.githubusercontent.com/zdharma-continuum/zinit/HEAD/scripts/install.sh

For more details check out [PR #61](https://github.com/zdharma-continuum/zinit/pull/61)

- 11-11-2021

  - The annexes repos have been renamed to improve discoverability. They used to be called `z-a-${name}` and have been
    renamed to `zinit-annex-${name}`. You don't *need* to update your configs right away since GitHub redirects to the
    new URLs.

- 06-11-2021

  - 🚧 zinit has a new home: https://github.com/zdharma-continuum/zinit
    - The migration from @zdharma, @Zsh-Packages and @zinit-zsh is still in progress. If you are interested in helping
      or want to let us know that a particular project is missing, please head to
      [I_WANT_TO_HELP](https://github.com/zdharma-continuum/I_WANT_TO_HELP/issues?q=is%3Aissue+is%3Aopen+sort%3Aupdated-desc)
  - 📚 zinit now ensures that the man dirs under `$ZPFX/man` are created on startup. Please note that these directories
    will not necessarily be part of your `manpath`. You may need to set `$MANPATH`. See #8 (and #7) for more details.

- 21-01-2020

  - A few tips for the project rename following the field reports (the issues created by users):
    - the `ZPLGM` hash is now `ZINIT`,
    - the annexes are moved under [zinit-zsh](https://github.com/zinit-zsh) organization (it needs a logo, could you
      create one, if you're skilled in graphics?).

- 19-01-2020

  - The name has been changed to **Zinit** based on the results of the
    [poll](https://web.archive.org/web/20201008014128/https://github.com/zdharma/zinit/issues/235)
  - In general, you don't have to do anything after the name change.
  - Only a run of `zinit update --all` might be necessary.
  - You might also want to rename your `zplugin` calls in `zshrc` to `zinit`.
  - Zinit will reuse `~/.zplugin` directory if it exists, otherwise it'll create `~/.zinit`.

- 15-01-2020

  - There's a new function, `zpextract`, which unpacks the given file. It supports many formats (notably also `dmg`
    images) – if there's a format that's unsupported please don't hesitate to
    [make a request](https://github.com/zdharma-continuum/zinit/issues/new?assignees=&labels=%F0%9F%8E%81+feature+request%2C%F0%9F%8E%B2+triage&template=feature-request.yml&title=%F0%9F%8E%81+Feature+request%3A+)
    for it to be added. A few facts:
    - the function is available only at the time of the plugin/snippet installation,
    - it's to be used within `atclone` and `atpull` ices,
    - it has an optional `--move` option which moves all the files from a subdirectory up one level,
    - one other option `--norm` prevents the archive from being deleted upon unpacking.
  - snippets now aren't re-downloaded unless they're newer on the HTTP server; use this with the `--norm` option of
    `zpextract` to prevent unnecessary updates; for example, the
    [firefox-dev package](https://github.com/zdharma-continuum/zsh-package-firefox-dev) uses this option for this
    purpose,
  - GitHub doesn't report proper `Last-Modified` HTTP server for the files in the repositories so the feature doesn't
    yet work with such files.

- 13-12-2019

  - The packages have been disconnected from NPM registry and now live only on Zsh Packages organization. Publishing to
    NPM isn't needed.

  - There are two interesting packages, [any-gem](https://github.com/zdharma-continuum/zsh-package-any-gem) and
    [any-node](https://github.com/zdharma-continuum/zsh-package-any-node). They allow to install any Gem(s) or Node
    module(s) locally in a newly created plugin directory. For example:

    ```zsh
    zinit pack param='GEM -> rails' for any-gem
    zinit pack param='MOD -> doctoc' for any-node
    # To have the command in zshrc, add an id-as'' ice so that
    # Zinit knows that the package is already installed
    # (also: the Unicode arrow is allowed)
    zinit id-as=jekyll pack param='GEM → jekyll' for any-gem
    ```

    The binaries will be exposed without altering the PATH via shims
    ([Bin-Gem-Node](https://github.com/zinit-zsh/zinit-annex-bin-gem-node) annex is needed). Shims are correctly removed
    when deleting a plugin with `zinit delete …`.

- 11-12-2019

  - Zinit now supports installing special-Zsh NPM packages! Bye-bye the long and complex ice-lists! Check out the
    [Wiki](https://zdharma-continuum.github.io/zinit/wiki/NPM-Packages/) for an introductory document on the feature.

- 25-11-2019

  - A new subcommand `run` that executes a command in the given plugin's directory. It has an `-l` option that will
    reuse the previously provided plugin. So that it's possible to do:

    ```zsh
    zplg run my/plugin ls
    zplg run -l cat \*.plugin.zsh
    zplg run -l pwd
    ```

- 07-11-2019

  - Added a prefix-char: `@` that can be used before plugins if their name collides with one of the ice-names. For
    example `sharkdp/fd` collides with the `sh` ice (which causes the plugin to be loaded with the POSIX `sh` emulation
    applied). To load it, do e.g.:

    ```zsh
    zinit as"null" wait"2" lucid from"gh-r" for \
        mv"exa* -> exa" sbin"exa"  ogham/exa \
        mv"fd* -> fd" sbin"fd/fd"  @sharkdp/fd \
        sbin"fzf" junegunn/fzf-bin
    ```

    i.e.: precede the plugin name with `@`. Note: `sbin''` is an ice added by the
    [zinit-annex-bin-gem-node](https://github.com/zinit/zinit-annex-bin-gem-node) annex, it provides the command to the
    command line without altering `$PATH`.

    See the [Zinit Wiki](https://zdharma-continuum.github.io/zinit/wiki/For-Syntax/) for more information on the
    for-syntax.

- 06-11-2019

  - A new syntax, called for-syntax. Example:

    ```zsh
     zinit as"program" atload'print Hi!' for \
         atinit'print First!' zdharma/null \
         atinit'print Second!' svn OMZ::plugins/git
    ```

    The output:

    ```
    First!
    Hi!
    Second!
    Hi!
    ```

    And also:

    ```zsh
    % print -rl $path | egrep -i '(/git|null)'
    /root/.zinit/snippets/OMZ::plugins/git
    /root/.zinit/plugins/zdharma---null
    ```

    To load in light mode, use a new `light-mode` ice. More examples and information can be found on the
    [Zinit Wiki](https://zdharma-continuum.github.io/zinit/wiki/For-Syntax/).

- 03-11-2019

  - A new value for the `as''` ice – `null`. Specifying `as"null"` is like specifying `pick"/dev/null" nocompletions`,
    i.e.: it disables the sourcing of the default script file of a plugin or snippet and also disables the installation
    of completions.

- 30-10-2019

  - A new ice `trigger-load''` – create a function that loads given plugin/snippet, with an option (to use it, precede
    the ice content with `!`) to automatically forward the call afterwards. Example use:

    ```zsh
    # Invoking the command `crasis' will load the plugin that
    # provides the function `crasis', and it will be then
    # immediately invoked with the same arguments
    zinit ice trigger-load'!crasis'
    zinit load zdharma/zinit-crasis
    ```

- 22-10-2019

  - A new ice `countdown` – causes an interruptable (by Ctrl-C) countdown 5…4…3…2…1…0 to be displayed before running the
    `atclone''`, `atpull''` and `make` ices.

- 21-10-2019

  - The `times` command has a new option `-m` – it shows the **moments** of the plugin load times – i.e.: how late after
    loading Zinit a plugin has been loaded.

- 20-10-2019

  - The `zinit` completion now completes also snippets! The command `snippet`, but also `delete`, `recall`, `edit`,
    `cd`, etc. all receive such completing.
  - The `ice` subcommand can now be skipped – just pass in the ices, e.g.:
    ```zsh
    zinit atload"zicompinit; zicdreplay" blockf
    zinit light zsh-users/zsh-completions
    ```
  - The `compile` command is able to compile snippets.
  - The plugins that add their subdirectories into `$fpath` can be now `blockf`-ed – the functions located in the dirs
    will be correctly auto-loaded.

- 12-10-2019

  - Special value for the `id-as''` ice – `auto`. It sets the plugin/snippet ID automatically to the last component of
    its spec, e.g.:

    ```zsh
    zinit ice id-as"auto"
    zinit load robobenklein/zinc
    ```

    will load the plugin as `id-as'zinc'`.

- 14-09-2019

  - There's a Vim plugin which extends syntax highlighting of zsh scripts with coloring of the Zinit commands.
    [Project homepage](https://github.com/zinit/zinit-vim-syntax).

- 13-09-2019

  - New ice `aliases` which loads plugin with the aliases mechanism enabled. Use for plugins that define **and use**
    aliases in their scripts.

- 11-09-2019

  - New ice-mods `sh`,`bash`,`ksh`,`csh` that load plugins (and snippets) with the **sticky emulation** feature of Zsh –
    all functions defined within the plugin will automatically switch to the desired emulation mode before executing and
    switch back thereafter. In other words it is now possible to load e.g. bash plugins with Zinit, provided that the
    emulation level done by Zsh is sufficient, e.g.:

    ```zsh
    zinit ice bash pick"bash_it.sh" \
            atinit"BASH_IT=${ZINIT[PLUGINS_DIR]}/Bash-it---bash-it" \
            atclone"yes n | ./install.sh"
    zinit load Bash-it/bash-it
    ```

    This script loads correctly thanks to the emulation, however it isn't functional because it uses `type -t …` to
    check if a function exists.

- 10-09-2019

  - A new ice-mod `reset''` that ivokes `git reset --hard` (or the provided command) before `git pull` and `atpull''`
    ice. It can be used it to implement altering (i.e. patching) of the plugin's files inside the `atpull''` ice – `git`
    will report no conflicts when doing `pull`, and the changes can be then again introduced by the `atpull''` ice..

  - Three new Zplugin annexes (i.e. [extensions](https://zdharma-continuum.github.io/zplugin/wiki/Annexes/)):

    - [zinit-annex-man](https://github.com/zplugin/zinit-annex-man)

      Generates man pages and code-documentation man pages from plugin's README.md and source files (the code
      documentation is obtained from [Zshelldoc](https://github.com/zdharma/zshelldoc)).

    - [zinit-annex-test](https://github.com/zplugin/zinit-annex-test)

      Runs tests (if detected `test' target in a `Makefile`or any`\*.zunit\` files) on plugin installation and non-empty
      update.

    - [zinit-annex-patch-dl](https://github.com/zplugin/zinit-annex-patch-dl)

      Allows easy download and applying of patches, to e.g. aid building a binary program equipped in the plugin.

  - A new variable is being recognized by the installation script: `$ZPLG_BIN_DIR_NAME`. It configures the directory
    within `$ZPLG_HOME` to which Zplugin should be cloned.

- 09-08-2019

  - A new ice-mod `wrap-track''` which gets `;`-separated list of functions that are to be tracked **once** when
    executing. In other words you can extend the tracking beyond the moment of loading of a plugin.
  - The unloading of Zle widgets is now more smart – it takes into account the chains of plugins that can overload the
    Zle widgets, and solves the interactions that result out of it.

- 29-07-2019

  - `delete` now supports following options:
    - `--all` – deletes all plugins and snippets (a purge, similar to
      `rm -rf ${ZPLGM[PLUGINS_DIR]} ${ZPLGM[SNIPPETS_DIR]}`)
    - `--clean` – deletes only plugins and snippets that are **currently not loaded** in the current session.

- 09-07-2019

  - Zplugin can now have **its own plugins**, called **z-plugins**! Check out an example but fully functional z-plugin
    [zdharma/z-p-submods](https://github.com/zdharma/z-p-submods) and a document that explains on how to implement your
    own z-plugin ([here](../../wiki/Z-PLUGINS)).

- 08-07-2019

  - You can now do `zplugin ice wait ...` and it will work as `zplugin ice wait'0' ...` :) I.e. when there's no value to
    the `wait''` ice then a value of `0` is being substituted.

- 02-07-2019

  - [Cooperation of Fast-Syntax-Highlighting and Zplugin](https://asciinema.org/a/254630) – a new precise highlighting
    for Zplugin in F-Sy-H.

- 01-07-2019

  - `atclone''`, `atpull''` & `make''` get run in the same subshell, thus an e.g. export done in `atclone''` will be
    visible during the `make`.

- 26-06-2019

  - `notify''` contents gets evaluated, i.e. can contain active code like `$(tail -1 /var/log/messages)`, etc.

- 23-06-2019

  - New ice mod `subscribe''`/`on-update-of''` which works like the `wait''` ice-mod, i.e. defers loading of a plugin,
    but it **looks at modification time of the given file(s)**, and when it changes, it then triggers loading of the
    plugin/snippet:

    ```zsh
    % zplugin ice on-update-of'{~/files-*,/tmp/files-*}' lucid \
        atload"echo I have been loaded" \
        notify"Yes that's true :)"
    % zplugin load zdharma/null
    % touch ~/files-1
    The plugin has been loaded
    %
    Yes that's true :)
    ```

    The plugin/snippet will be sourced as many times as the file gets updated.

- 22-06-2019

  - New ice mod `reset-prompt` that will issue `zle .reset-prompt` after loading the plugin or snippet, causing the
    prompt to be recomputed. Useful with themes & turbo-mode.

  - New ice-mod `notify''` which will cause to display an under-prompt notification when the plugin or snippet gets
    loaded. E.g.:

    ```zsh
    % zplugin ice wait"0" lucid notify"zdharma/null has been loaded"
    % zplugin light zdharma/null
    %
    zdharma/null has been loaded
    ```

    In case of problems with the loading a warning message will be output:

    ```
    % zplugin ice notify atload'return 7'
    % zplugin light zdharma/null
    %
    notify: Plugin not loaded / loaded with problem, the return code: 7
    ```

    Refer to [Ice Modifiers](#ice-modifiers) section for a complete description.

- 29-05-2019

  - Turbo-Mode, i.e. the `wait''` ice-mode now supports a suffix – the letter `a`, `b` or `c`. The meaning is
    illustrated by the following example:

    ```zsh
    zplugin ice wait"0b" as"command" pick"wd.sh" atinit"echo Firing 1" lucid
    zplugin light mfaerevaag/wd
    zplugin ice wait"0a" as"command" pick"wd.sh" atinit"echo Firing 2" lucid
    zplugin light mfaerevaag/wd

    # The output
    Firing 2
    Firing 1
    ```

    As it can be seen, the second plugin has been loaded first. That's because there are now three sub-slots (the `a`,
    `b` and `c`) in which the plugin/snippet loadings can be put into. Plugins from the same time-slot with suffix `a`
    will be loaded before plugins with suffix `b`, etc.

    In other words, instead of `wait'1'` you can enter `wait'1a'`, `wait'1b'` and `wait'1c'` – to this way **impose
    order** on the loadings **regardless of the order of `zplugin` commands**.

- 26-05-2019

  - Turbo-Mode now divides the scheduled events (i.e. loadings of plugins or snippets) into packs of 5. In other words,
    after loading each series of 5 plugins or snippets the prompt is activated, i.e. it is feed an amount of CPU time.
    This will help to deliver the promise of background loading without interferences visible to the user. If you have
    some two slow-loading plugins and/or snippets, you can put them into some separate blocks of 5 events.

- 18-05-2019

  - New ice-mod `nocd` – it prevents changing current directory into the plugin's directory before evaluating
    `atinit''`, `atload''` etc. ice-mods.

- 12-03-2019

  - Finally reorganizing the `README.md`. Went on asciidoc path, the side-documents are written in it and the
    `README.md` will also be converted (example page: [Introduction](doc/INTRODUCTION.adoc))

- 12-10-2018

  - New `id-as''` ice-mod. You can nickname a plugin or snippet, to e.g. load it twice, with different `pick''` ice-mod,
    or from Github binary releases and regular Github repository at the same time. More information in
    [blog post](https://zdharma-continuum.github.io/2018-10-12/Nickname-a-plugin-or-snippet).

- 30-08-2018

  - New `as''` ice-mod value: `completion`. Can be used to install completion-only "plugins", even single files:

    ```zsh
    zplugin ice as"completion" mv"hub* -> _hub"
    zplugin snippet https://github.com/github/hub/blob/master/etc/hub.zsh_completion
    ```

  - Uplift of Git-output, it now has an animated progress-bar:

  ![image](https://raw.githubusercontent.com/zdharma/zplugin/images/zplg-progress-bar.gif)

- 15-08-2018

  - New `$ZPLGM` field `COMPINIT_OPTS` (also see [Customizing Paths](#customizing-paths--other)). You can pass `-C` or
    `-i` there to mute the `insecure directories` messages. Typical use case could be:
    ```zsh
    zplugin ice wait"5" atinit"ZPLGM[COMPINIT_OPTS]=-C; zpcompinit; zpcdreplay" lucid
    zplugin light zdharma/fast-syntax-highlighting
    ```

- 13-08-2018

  - `self-update` (subcommand used to update Zplugin) now lists new commits downloaded by the update:
    ![image](https://raw.githubusercontent.com/zdharma/zplugin/images/zplg-self-update.png)

  - New subcommand `bindkeys` that lists what bindkeys each plugin has set up.

- 25-07-2018

  - If you encountered a problem with loading Turbo-Mode plugins, it is fixed now. This occurred in versions available
    between `10` and `23` of July. Issue `zplugin self-update` if you installed/updated in this period.
  - New bug-fix release `v2.07`.

- 13-07-2018

  - New `multisrc''` ice, it allows to specify multiple files for sourcing and it uses brace expansion syntax, so for
    example you can:
    ```zsh
    zplugin ice depth"1" multisrc="lib/{functions,misc}.zsh" pick"/dev/null"; zplugin load robbyrussell/oh-my-zsh
    zplugin ice svn multisrc"{functions,misc}.zsh" pick"/dev/null"; zplugin snippet OMZ::lib
    array=( {functions,misc}.zsh ); zplg ice svn multisrc"\${array[@]}" pick"/dev/null"; zplugin snippet OMZ::lib
    array=( {functions,misc}.zsh ); zplg ice svn multisrc"${array[@]}" pick"/dev/null"; zplugin snippet OMZ::lib
    array=( {functions,misc}.zsh ); zplg ice svn multisrc"\$array" pick"/dev/null"; zplugin snippet OMZ::lib
    array=( {functions,misc}.zsh ); zplg ice svn multisrc"$array" pick"/dev/null"; zplugin snippet OMZ::lib
    zplugin ice svn multisrc"misc.zsh functions.zsh" pick"/dev/null"; zplugin snippet OMZ::lib
    ```

- 12-07-2018

  - For docker and new machine provisioning, there's a trick that allows to install all
    [turbo-mode](#turbo-mode-zsh--53) plugins by scripting:

    ```zsh
    zsh -i -c -- '-zplg-scheduler burst'
    ```

- 10-07-2018

  - Ice `wait'0'` now means actually short time – you can load plugins and snippets **very quickly** after prompt.

- 02-03-2018

  - Zplugin exports `$ZPFX` parameter. Its default value is `~/.zplugin/polaris` (user can override it before sourcing
    Zplugin). This directory is like `/usr/local`, a prefix for installed software, so it's possible to use ice like
    `make"PREFIX=$ZPFX"` or `atclone"./configure --prefix=$ZPFX"`. Zplugin also setups `$MANPATH` pointing to the
    `polaris` directory. Checkout [gallery](GALLERY.md) for examples.
  - [New README section](#hint-extending-git) about extending Git with Zplugin.

- 05-02-2018

  - I work much on this README however multi-file Wiki might be better to read – it
    [just has been created](https://github.com/zdharma/zplugin/wiki).

- 16-01-2018

  - New ice-mod `compile` which takes pattern to select additional files to compile, e.g.
    `zplugin ice compile"(hsmw-*|history-*)"` (for `zdharma/history-search-multi-word` plugin). See
    [Ice Modifiers](#ice-modifiers).

- 14-01-2018

  - Two functions have been exposed: `zpcdreplay` and `zpcompinit`. First one invokes compdef-replay, second one is
    equal to `autoload compinit; compinit` (it also respects `$ZPLGM[ZCOMPDUMP_PATH]`). You can use e.g.
    `atinit'zpcompinit'` ice-mod in a syntax-highlighting plugin, to initialize completion right-before setting up
    syntax highlighting (because that should be done at the end).

- 13-01-2018

  - New customizable path `$ZPLGM[ZCOMPDUMP_PATH]` that allows to point zplugin to non-standard `.zcompdump` location.
  - Tilde-expansion is now performed on the [customizable paths](#customizing-paths--other) – you can assign paths like
    `~/.zplugin`, there's no need to use `$HOME/.zplugin`.

- 31-12-2017

  - For the new year there's a new feature: user-services spawned by Zshell :) Check out
    [available services](https://github.com/zservices). They are configured like their READMEs say, and controlled via:

    ```
    % zplugin srv redis next    # current serving shell will drop the service, next Zshell will pick it up
    % zplugin srv redis quit    # the serving shell will quit managing the service, next Zshell will pick it up
    % zplugin srv redis stop    # stop serving, do not pass it to any shell, just hold the service
    % zplugin srv redis start   # start stopped service, without changing the serving shell
    % zplugin srv redis restart # restart service, without changing the serving shell
    ```

    This feature allows to configure everything in `.zshrc`, without the the need to deal with `systemd` or `launchd`,
    and can be useful e.g. to configure shared-variables (across Zshells), stored in `redis` database (details on
    [zservices/redis](https://github.com/zservices/redis)).

- 24-12-2017

  - Xmas present – [fast-syntax-highlighting](https://github.com/zdharma/fast-syntax-highlighting) now highlights the
    quoted part in `atinit"echo Initializing"`, i.e. it supports ICE syntax :)

- 08-12-2017

  - SVN snippets are compiled on install and update
  - Resolved how should ice-mods be remembered – general rule is that using `zplugin ice ...` makes memory-saved and
    disk-saved ice-mods not used, and replaced on update. Calling e.g. `zplugin update ...` without preceding `ice` uses
    memory, then disk-saved ices.

- 07-12-2017

  - New subcommand `delete` that obtains plugin-spec or URL and deletes plugin or snippet from disk. It's good to forget
    wrongly passed Ice-mods (which are storred on disk e.g. for `update --all`).

- 04-12-2017

  - It's possible to set plugin loading and unloading on condition. ZPlugin supports plugin unloading, so it's possible
    to e.g. **unload prompt and load another one**, on e.g. directory change. Checkout
    [full story](#automatic-loadunload-on-condition) and [Asciinema video](https://asciinema.org/a/150825).

- 29-11-2017

  - **[Turbo Mode](https://github.com/zdharma/zplugin#turbo-mode-zsh--53)** – **39-50% or more faster Zsh startup!**
  - Subcommand `update` can update snippets, via given URL (up to this point snippets were updated via
    `zplugin update --all`).
  - Completion management is enabled for snippets (not only plugins).

- 13-11-2017

  - New ice modifier – `make`. It causes the `make`-command to be executed after cloning or updating plugins and
    snippets. For example there's `Zshelldoc` that uses `Makefile` to build final scripts:

    ```SystemVerilog
    zplugin ice as"program" pick"build/zsd*" make; zplugin light zdharma/zshelldoc
    ```

    The above doesn't trigger the `install` target, but this does:

    ```SystemVerilog
    zplugin ice as"program" pick"build/zsd*" make"install PREFIX=/tmp"; zplugin light zdharma/zshelldoc
    ```

  - Fixed problem with binary-release selection (`from"gh-r"`) by adding Ice-mod `bpick`, which should be used for this
    purpose instead of `pick`, which selects file within plugin tree.

- 06-11-2017

  - The subcommand `completions` now prints `3` completions per line (not `1`). This makes large amount of completions to look
    better. Argument can be given, e.g. `6`, to increase the grouping.
  - New Ice-mod `silent` that mutes `stderr` & `stdout` of a plugin or snippet.

- 04-11-2017

  - New subcommand `ls` which lists snippets-directory in a formatted and colorized manner. Example:

  ![zplugin-ls](https://raw.githubusercontent.com/zdharma/zplugin/images/zplg-ls.png)

- 29-10-2017

  - Subversion protocol (supported by Github) can be used to clone **subdirectories** when using snippets. This allows
    to load multi-file snippets. For example:

    ```SystemVerilog
    zstyle ':prezto:module:prompt' theme smiley
    zplugin ice svn silent; zplugin snippet PZT::modules/prompt
    ```

  - Snippets support `Prezto` modules (with dependencies), and can use **PZT::** URL-shorthand, like in the example
    above. One can load `Prezto` module as single file snippet, or use Subversion to download whole directory (see also
    description of [Ice Modifiers](#ice-modifiers)):

    ```zsh
    # Single file snippet, URL points to file

    zplg snippet PZT::modules/helper/init.zsh

    # Multi-file snippet, URL points to directory to clone with Subversion
    # The file to source (init.zsh) is automatically detected

    zplugin ice svn; zplugin snippet PZT::modules/prompt

    # Use of Subversion to load an OMZ plugin

    zplugin ice svn; zplugin snippet OMZ::plugins/git
    ```

  - Fixed a bug with `cURL` usage (snippets) for downloading, it will now be properly used

- 13-10-2017

  - Snippets can use "**OMZ::**" prefix to easily point to `Oh-My-Zsh` plugins and libraries, e.g.:

    ```SystemVerilog
    zplugin snippet OMZ::lib/git.zsh
    zplugin snippet OMZ::plugins/git/git.plugin.zsh
    ```

- 12-10-2017

  - The `cd` subcommand can now obtain URL and move session to **snippet** directory

  - The `times` subcommand now includes statistics on snippets. Also, entries are displayed in order of loading:

    ```zsh
    % zplugin times
    Plugin loading times:
    0.010 sec - OMZ::lib/git.zsh
    0.001 sec - OMZ::plugins/git/git.plugin.zsh
    0.003 sec - zdharma/history-search-multi-word
    0.003 sec - rimraf/k
    0.003 sec - zsh-users/zsh-autosuggestions
    ```

- 24-09-2017

  - **[Code documentation](zsdoc)** for contributors and interested people.

- 13-06-2017

  - Plugins can now be absolute paths:

    ```SystemVerilog
    zplugin load %HOME/github/{directory}
    zplugin load /Users/sgniazdowski/github/{directory}
    zplugin load %/Users/sgniazdowski/github/{directory}
    ```

    Completions are not automatically installed, but user can run `zplg creinstall %HOME/github/{directory}`, etc.

- 23-05-2017

  - New `ice` modifier: `if`, to which you can provide a conditional expression:

    ```SystemVerilog
    % zplugin ice if"(( 0 ))"
    % zplugin snippet --command https://github.com/b4b4r07/httpstat/blob/master/httpstat.sh
    % zplugin ice if"(( 1 ))"
    % zplugin snippet --command https://github.com/b4b4r07/httpstat/blob/master/httpstat.sh
    Setting up snippet httpstat.sh
    Downloading httpstat.sh...
    ```
