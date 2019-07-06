<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**  *generated with [DocToc](https://github.com/thlorenz/doctoc)*

- [Changelog](#changelog)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

# Changelog
All notable changes to this project will be documented in this file.

* 02-07-2019
  - [Cooperation of Fast-Syntax-Highlighting and
    Zplugin](https://asciinema.org/a/254630) – a new precise highlighting for
    Zplugin in F-Sy-H.

* 01-07-2019
  - `atclone''`, `atpull''` & `make''` get run in the same subshell, thus an e.g.
    export done in `atclone''` will be visible during the `make`.

* 26-06-2019
  - `notify''` contents gets evaluated, i.e. can contain active code like `$(tail -1
    /var/log/messages)`, etc.

* 23-06-2019
  - New ice mod `subscribe''`/`on-update-of''` which works like the
    `wait''` ice-mod, i.e. defers loading of a plugin, but it **looks at
    modification time of the given file(s)**, and when it changes, it then
    triggers loading of the plugin/snippet:

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

* 22-06-2019
  - New ice mod `reset-prompt` that will issue `zle .reset-prompt` after loading the
    plugin or snippet, causing the prompt to be recomputed. Useful with themes &
    turbo-mode.

  - New ice-mod `notify''` which will cause to display an under-prompt notification
    when the plugin or snippet gets loaded. E.g.:

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

* 29-05-2019
  - Turbo-Mode, i.e. the `wait''` ice-mode now supports a suffix – the letter `a`, `b`
    or `c`. The meaning is illustrated by the following example:

    ```zsh
    zplugin ice wait"0b" as"command" pick"wd.sh" atinit"echo Firing 1" lucid
    zplugin light mfaerevaag/wd
    zplugin ice wait"0a" as"command" pick"wd.sh" atinit"echo Firing 2" lucid
    zplugin light mfaerevaag/wd

    # The output
    Firing 2
    Firing 1
    ```

    As it can be seen, the second plugin has been loaded first. That's because there
    are now three sub-slots (the `a`, `b` and `c`) in which the plugin/snippet loadings
    can be put into. Plugins from the same time-slot with suffix `a` will be loaded
    before plugins with suffix `b`, etc.

    In other words, instead of `wait'1'` you can enter `wait'1a'`,
    `wait'1b'` and `wait'1c'` – to this way **impose order** on the loadings
    **regardless of the order of `zplugin` commands**. 
* 26-05-2019
  - Turbo-Mode now divides the scheduled events (i.e. loadings of plugins or snippets)
    into packs of 5. In other words, after loading each series of 5 plugins or snippets
    the prompt is activated, i.e. it is feed an amount of CPU time. This will help to
    deliver the promise of background loading without interferences visible to the
    user. If you have some two slow-loading plugins and/or snippets, you can put them
    into some separate blocks of 5 events.

* 18-05-2019
  - New ice-mod `nocd` – it prevents changing current directory into the plugin's directory
    before evaluating `atinit''`, `atload''` etc. ice-mods.

* 12-03-2019
  - Finally reorganizing the `README.md`. Went on asciidoc path, the
    side-documents are written in it and the `README.md` will also be
    converted (example page: [Introduction](doc/INTRODUCTION.adoc))
* 12-10-2018
  - New `id-as''` ice-mod. You can nickname a plugin or snippet, to e.g. load it twice, with different `pick''`
    ice-mod, or from Github binary releases and regular Github repository at the same time. More information
    in [blog post](http://zdharma.org/2018-10-12/Nickname-a-plugin-or-snippet).

* 30-08-2018
  - New `as''` ice-mod value: `completion`. Can be used to install completion-only "plugins", even single
    files:
    ```zsh
    zplugin ice as"completion" mv"hub* -> _hub"
    zplugin snippet https://github.com/github/hub/blob/master/etc/hub.zsh_completion
    ```

  - Uplift of Git-output, it now has an animated progress-bar:

  ![image](https://raw.githubusercontent.com/zdharma/zplugin/images/zplg-progress-bar.gif)

* 15-08-2018
  - New `$ZPLGM` field `COMPINIT_OPTS` (also see [Customizing Paths](#customizing-paths--other)). You can pass
    `-C` or `-i` there to mute the `insecure directories` messages. Typical use case could be:
    ```zsh
    zplugin ice wait"5" atinit"ZPLGM[COMPINIT_OPTS]=-C; zpcompinit; zpcdreplay" lucid
    zplugin light zdharma/fast-syntax-highlighting
    ```

* 13-08-2018
  - `self-update` (subcommand used to update Zplugin) now lists new commits downloaded by the update:
  ![image](https://raw.githubusercontent.com/zdharma/zplugin/images/zplg-self-update.png)

  - New subcommand `bindkeys` that lists what bindkeys each plugin has set up.

* 25-07-2018
  - If you encountered a problem with loading Turbo-Mode plugins, it is fixed now. This occurred in versions
  available between `10` and `23` of July. Issue `zplugin self-update` if you installed/updated in this period.
  - New bug-fix release `v2.07`.

* 13-07-2018
  - New `multisrc''` ice, it allows to specify multiple files for sourcing and  it uses brace expansion syntax, so for example you can:
    ```zsh
    zplugin ice depth"1" multisrc="lib/{functions,misc}.zsh" pick"/dev/null"; zplugin load robbyrussell/oh-my-zsh
    zplugin ice svn multisrc"{functions,misc}.zsh" pick"/dev/null"; zplugin snippet OMZ::lib
    array=( {functions,misc}.zsh ); zplg ice svn multisrc"\${array[@]}" pick"/dev/null"; zplugin snippet OMZ::lib
    array=( {functions,misc}.zsh ); zplg ice svn multisrc"${array[@]}" pick"/dev/null"; zplugin snippet OMZ::lib
    array=( {functions,misc}.zsh ); zplg ice svn multisrc"\$array" pick"/dev/null"; zplugin snippet OMZ::lib
    array=( {functions,misc}.zsh ); zplg ice svn multisrc"$array" pick"/dev/null"; zplugin snippet OMZ::lib
    zplugin ice svn multisrc"misc.zsh functions.zsh" pick"/dev/null"; zplugin snippet OMZ::lib
    ```
* 12-07-2018
  - For docker and new machine provisioning, there's a trick that allows to install all [turbo-mode](#turbo-mode-zsh--53)
    plugins by scripting:

    ```zsh
    zsh -i -c -- '-zplg-scheduler burst'
    ```

* 10-07-2018
  - Ice `wait'0'` now means actually short time – you can load plugins and snippets **very quickly** after prompt.

* 02-03-2018
  - Zplugin exports `$ZPFX` parameter. Its default value is `~/.zplugin/polaris` (user can
    override it before sourcing Zplugin). This directory is like `/usr/local`, a prefix
    for installed software, so it's possible to use ice like `make"PREFIX=$ZPFX"` or
    `atclone"./configure --prefix=$ZPFX"`. Zplugin also setups `$MANPATH` pointing to the
    `polaris` directory. Checkout [gallery](GALLERY.md) for examples.
  - [New README section](#hint-extending-git) about extending Git with Zplugin.

* 05-02-2018
  - I work much on this README however multi-file Wiki might be better to read – it
    [just has been created](https://github.com/zdharma/zplugin/wiki).

* 16-01-2018
  - New ice-mod `compile` which takes pattern to select additional files to compile, e.g.
    `zplugin ice compile"(hsmw-*|history-*)"` (for `zdharma/history-search-multi-word` plugin).
    See [Ice Modifiers](#ice-modifiers).

* 14-01-2018
  - Two functions have been exposed: `zpcdreplay` and `zpcompinit`. First one invokes compdef-replay,
    second one is equal to `autoload compinit; compinit` (it also respects `$ZPLGM[ZCOMPDUMP_PATH]`).
    You can use e.g. `atinit'zpcompinit'` ice-mod in a syntax-highlighting plugin, to initialize
    completion right-before setting up syntax highlighting (because that should be done at the end).

* 13-01-2018
  - New customizable path `$ZPLGM[ZCOMPDUMP_PATH]` that allows to point zplugin to non-standard
    `.zcompdump` location.
  - Tilde-expansion is now performed on the [customizable paths](#customizing-paths--other) – you can
    assign paths like `~/.zplugin`, there's no need to use `$HOME/.zplugin`.

* 31-12-2017
  - For the new year there's a new feature: user-services spawned by Zshell :) Check out
    [available services](https://github.com/zservices). They are configured like their
    READMEs say, and controlled via:

    ```
    % zplugin srv redis next    # current serving shell will drop the service, next Zshell will pick it up
    % zplugin srv redis quit    # the serving shell will quit managing the service, next Zshell will pick it up
    % zplugin srv redis stop    # stop serving, do not pass it to any shell, just hold the service
    % zplugin srv redis start   # start stopped service, without changing the serving shell
    % zplugin srv redis restart # restart service, without changing the serving shell
    ```

    This feature allows to configure everything in `.zshrc`, without the the need to deal with `systemd` or
    `launchd`, and can be useful e.g. to configure shared-variables (across Zshells), stored in `redis` database
    (details on [zservices/redis](https://github.com/zservices/redis)).

* 24-12-2017
  - Xmas present – [fast-syntax-highlighting](https://github.com/zdharma/fast-syntax-highlighting)
    now highlights the quoted part in `atinit"echo Initializing"`, i.e. it supports ICE syntax :)

* 08-12-2017
  - SVN snippets are compiled on install and update
  - Resolved how should ice-mods be remembered – general rule is that using `zplugin ice ...` makes
    memory-saved and disk-saved ice-mods not used, and replaced on update. Calling e.g. `zplugin
    update ...` without preceding `ice` uses memory, then disk-saved ices.

* 07-12-2017
  - New subcommand `delete` that obtains plugin-spec or URL and deletes plugin or snippet from disk.
    It's good to forget wrongly passed Ice-mods (which are storred on disk e.g. for `update --all`).

* 04-12-2017
  - It's possible to set plugin loading and unloading on condition. ZPlugin supports plugin unloading,
    so it's possible to e.g. **unload prompt and load another one**, on e.g. directory change. Checkout
    [full story](#automatic-loadunload-on-condition) and [Asciinema video](https://asciinema.org/a/150825).

* 29-11-2017
  - **[Turbo Mode](https://github.com/zdharma/zplugin#turbo-mode-zsh--53)** – **39-50% or more faster Zsh startup!**
  - Subcommand `update` can update snippets, via given URL (up to this point snippets were updated via
    `zplugin update --all`).
  - Completion management is enabled for snippets (not only plugins).

* 13-11-2017
  - New ice modifier – `make`. It causes the `make`-command to be executed after cloning or updating
    plugins and snippets. For example there's `Zshelldoc` that uses `Makefile` to build final scripts:

    ```SystemVerilog
    zplugin ice as"program" pick"build/zsd*" make; zplugin light zdharma/zshelldoc
    ```

    The above doesn't trigger the `install` target, but this does:

    ```SystemVerilog
    zplugin ice as"program" pick"build/zsd*" make"install PREFIX=/tmp"; zplugin light zdharma/zshelldoc
    ```

  - Fixed problem with binary-release selection (`from"gh-r"`) by adding Ice-mod `bpick`, which
    should be used for this purpose instead of `pick`, which selects file within plugin tree.

* 06-11-2017
  - The subcommand `clist` now prints `3` completions per line (not `1`). This makes large amount
    of completions to look better. Argument can be given, e.g. `6`, to increase the grouping.
  - New Ice-mod `silent` that mutes `stderr` & `stdout` of a plugin or snippet.

* 04-11-2017
  - New subcommand `ls` which lists snippets-directory in a formatted and colorized manner. Example:

  ![zplugin-ls](https://raw.githubusercontent.com/zdharma/zplugin/images/zplg-ls.png)

* 29-10-2017
  - Subversion protocol (supported by Github) can be used to clone **subdirectories** when using
    snippets. This allows to load multi-file snippets. For example:

    ```SystemVerilog
    zstyle ':prezto:module:prompt' theme smiley
    zplugin ice svn silent; zplugin snippet PZT::modules/prompt
    ```

  - Snippets support `Prezto` modules (with dependencies), and can use **PZT::** URL-shorthand,
    like in the example above. One can load `Prezto` module as single file snippet, or use Subversion
    to download whole directory (see also description of [Ice Modifiers](#ice-modifiers)):

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

* 13-10-2017
  - Snippets can use "**OMZ::**" prefix to easily point to `Oh-My-Zsh` plugins and libraries, e.g.:

    ```SystemVerilog
    zplugin snippet OMZ::lib/git.zsh
    zplugin snippet OMZ::plugins/git/git.plugin.zsh
    ```

* 12-10-2017
  - The `cd` subcommand can now obtain URL and move session to **snippet** directory
  - The `times` subcommand now includes statistics on snippets. Also, entries
    are displayed in order of loading:

    ```zsh
    % zplugin times
    Plugin loading times:
    0.010 sec - OMZ::lib/git.zsh
    0.001 sec - OMZ::plugins/git/git.plugin.zsh
    0.003 sec - zdharma/history-search-multi-word
    0.003 sec - rimraf/k
    0.003 sec - zsh-users/zsh-autosuggestions
    ```

* 24-09-2017
  - **[Code documentation](zsdoc)** for contributors and interested people.

* 13-06-2017
  - Plugins can now be absolute paths:

    ```SystemVerilog
    zplugin load %HOME/github/{directory}
    zplugin load /Users/sgniazdowski/github/{directory}
    zplugin load %/Users/sgniazdowski/github/{directory}
    ```

    Completions are not automatically installed, but user can run `zplg creinstall %HOME/github/{directory}`, etc.

* 23-05-2017
  - New `ice` modifier: `if`, to which you can provide a conditional expression:

    ```SystemVerilog
    % zplugin ice if"(( 0 ))"
    % zplugin snippet --command https://github.com/b4b4r07/httpstat/blob/master/httpstat.sh
    % zplugin ice if"(( 1 ))"
    % zplugin snippet --command https://github.com/b4b4r07/httpstat/blob/master/httpstat.sh
    Setting up snippet httpstat.sh
    Downloading httpstat.sh...
    ```
