# News

Here are the new features and updates added to Zinit in the last 90 days.

To see the full history check [the changelog](doc/CHANGELOG.md) or check out [the latest commits](https://github.com/zdharma-continuum/zinit/commits/master)


- 16-07-2020

  - A new ice `null` which works exactly the same as `as"null"`, i.e.: it makes
    the plugin a *null*-one ↔ without any scripts sourced (by default, unless
    `src''` or `multisrc''` are given) and compiled, and without any completions
    searched / installed. Example use case:

    ```zsh
    zi null sbin"vims" for MilesCranmer/vim-stream
    ```

    instead of:

    ```zsh
    zi as"null" sbin"vims" for MilesCranmer/vim-stream
    ```

    .

  - A **new annex** [**Unscope**](https://github.com/zdharma-continuum/z-a-unscope) :)
    It's goal is: to allow the usage of the unscoped — i.e.: given without any
    GitHub user name — plugin IDs. Basically it allows to specify, e.g.: **zinit load
    _zsh-syntax-highlighting_** instead of **zinit load
    _zsh-users/zsh-syntax-highlighting_**. It'll automatically send a request to
    the GitHub API searching for the best candidate (max. # of stars and of
    forks). It also has an embedded, static database of short *nicknames* for
    some of the plugins out there (requests for addition are welcomed), e.g.:
    **vi-reg** for **zsh-vi-more/evil-registers**.

  - A fresh and elastic hook-based architecture has been implemented and
    deployed — the code is much cleaner and the development will be easier,
    i.e.: quicker :).

  - Set of small improvements: **a)** `silent''` mutes the `Snippet not loaded`
    error message, **b)** much shorter lag/pause after a plugin installation or
    update, **c)** the 256 color palette is being now used for plugin IDs, if
    available, **d)** if possible (a UTF-8 locale is needed to be set), the Unicode
    three-dots `…` will be used instead of `...` in the messages, **e)**
    nicer snippet IDs in the installation and update messages, **f)** the
    annexes can be now loaded in any order without influencing their operation
    in any way (there have been some issues with
    [Patch-Dl](https://github.com/zdharma-continuum/z-a-patch-dl) and
    [As-Monitor](https://github.com/zdharma-continuum/z-a-as-monitor) annexes), **g)**
    `compile''` can now obtain multiple patterns separated via semicolon (`;`).

- 25-06-2020

  - Ability to call the autoloaded function at the moment of loading it by
    `autoload'#fun'`, i.e.: by prefixing it with the hash sigh (`#`). So that
    it's possible to invoke e.g.:

    ```zsh
    zinit autoload'#manydots-magic' for knu/zsh-manydots-magic
    ```

    instead of:

    ```zsh
    zinit autoload'manydots-magic' atload'manydots-magic' for \
        knu/zsh-manydots-magic
    ```

- 20-06-2020

  - The [Bin-Gem-Node](https://github.com/zdharma-continuum/z-a-bin-gem-node) annex now
    has an explicit Cygwin support — it creates additional, **extra shim files**
    — Windows batch scripts that allow to run the shielded applications from
    e.g.: Windows run dialog — if the `~/.zinit/polaris/bin` directory is being
    added to the Windows `PATH` environment variable, for example (it is a good
    idea to do so, IMHO). The Windows shims (*shims* are command-wrapper scripts
    that are in general created with the `sbin''` ice of the annex) have the
    same name as the standard ones (which are also being created, normally) plus
    the `.cmd` extension. You can test the feature by e.g.: installing Firefox
    from the Zinit package via:

    ```zsh
    zinit pack=bgn for firefox
    ```

  - All cURL progress bars are now guaranteed to be single line — this is being
    done by a wrapper script.

  - I thought that I'll share an interesting function-type that I'm using within
    Zinit - a function that outputs messages with theming and colors easily
    available:

    ```zsh
    typeset -gA COLORS=(
        col-error  $'\e[31m'
        col-file   $'\e[38;5;110m'
        col-url    $'\e[38;5;45m'
        col-meta   $'\e[38;5;221m'
        col-meta2  $'\e[38;5;154m'
        col-data   $'\e[38;5;82m'
        col-data2  $'\e[38;5;50m'
        col-rst    $'\e[0m'
        col-can-be-empty ""
    )

    m() {
        builtin emulate -LR zsh -o extendedglob
        if [[ $1 = -* ]] { local opt=$1; shift } else { local opt }
        local msg=${(j: :)${@//(#b)([\[\{]([^\]\}]##)[\]\}])/${COLORS[col-$match[2]]-$match[1]}}}
        builtin print -Pr ${opt:#--} -- $msg
    }
    ```

    Usage is as follows:

    ```zsh
    m "{error}ERROR:{rst} The {meta}data{rst} has the value: {data}value{rst}"
    ```

    Effect:

    ![screenshot](https://raw.githubusercontent.com/zdharma-continuum/zinit/master/doc/img/m.png)

    The function is available in the `atinit''`, `atload''`, etc. hooks.

- 17-06-2020

  - `ziextract` and `extract''` now support Windows installers — currently the
    installer of Firefox. Let me know if any of your installers doesn't work.
    You can test the installer with the Firefox Developer Edition Zinit
    [package](https://github.com/zdharma-continuum/zsh-package-firefox-dev):

    ```zsh
    zinit pack"bgn" for firefox-dev
    ```

    The above command will work on Windows (at least on Cygwin), Linux and OS X.

- 13-06-2020

  - `ziextract` has a new `--move2` option, which moves files two levels up
    after unpacking. For example, if there will be an archive file with
    directory structure: `Pulumi/bin/{pulumi,pulumi2}`, then after `ziextract --move2 --auto` there will be the two files moved to the top level dir:
    `./{pulumi,pulumi2}`. To obtain the same effect using the `extract''` ice,
    pass two exclamation marks, i.e.: `extract'!!'`. A real-world example — it
    uses [z-a-as-monitor](https://github.com/zdharma-continuum/z-a-as-monitor) and
    [z-a-bin-gem-node](https://github.com/zdharma-continuum/z-a-bin-gem-node) annexes to
    download a Zip package that has the files inside two-level nested directory
    tree:

    ```zsh
    zi id-as`pulumi` as`monitor|null` mv`pulumi pulumi_` extract`!` \
        dlink=`https://get.pulumi.com/releases/sdk/pulumi-%VERSION%-windows-x64.zip` \
        sbin`pulumi*` for \
            https://www.pulumi.com/docs/get-started/install/versions/
    ```

- 12-06-2020

  - New options to `update`: `-s/--snippets` and `-l/--plugins` — they're
    limiting the `update --all` to only plugins or snippets. Example:

    ```zsh
    zinit update --plugins
    ```

    Work also with `-p/--parallel`.

- 15-05-2020

  - The `autoload''` ice can now rename the autoloaded functions, i.e.: load
    a function from a file `func-A` as a function `func-B` via: `autoload'func-A -> func-B; …'`.
  - Also, an alternate autoloading method - via: `eval "func-file() { $(<func-file); }"` — has been exposed — in order to use it, precede the
    ice contents with an exclamation mark, i.e.: `autoload'!func-file'`. The
    rename mode uses this method by default.

- 12-05-2020

  - A new feature — ability to substitute `stringA` → `stringB` in plugin source
    body before executing by `subst'A -> B'`. Works also for any nested `source`
    commands. Example — renaming the `dl''` ice into a `dload''` ice in the
    [Patch-Dl](https://github.com/zdharma-continuum/z-a-patch-dl) annex:

    ```zsh
    zinit subst"dl'' -> dload''" for zdharma-continuum/z-a-patch-dl
    ```

  - A new ice `autoload''` which invokes `autoload -Uz …` on the given
    files/functions. Example — a plugin that converts `cd ...` into
    `cd ../..` that lacks proper setup in any `*.plugin.zsh` file:

    ```zsh
    zinit as=null autoload=manydots-magic atload=manydots-magic for \
        knu/zsh-manydots-magic
    ```

- 09-05-2020

  - The `from'gh-r'` downloading of the binary files from GitHub releases can
    now download **multiple files** — if you specify multiple `bpick''` ices
    **or** separate the patterns with a semicolon (**`;`**). Example:

    ```zsh
    zinit from"gh-r" as"program" mv"krew-* -> krew" bpick"*.yaml" bpick"*.tar.gz" for \
    kubernetes-sigs/krew
    ```

  - A new ice `opts''` which takes options to **sticky-set** during sourcing of
    the plugin. This means that thee options will be also set for all of the
    *functions* that the plugin defines — **during their execution**
    (<i>**only**</i>). The option list is space separated. Example:

    ```zsh
    # Suppose the example test plugin has the following in test.plugin.zsh:
    #
    # print $options[kshglob] $options[shglob]
    #
    # Then:

    zinit opts"kshglob noshglob" for zdharma-continuum/test

    # Outputs:
    on off

    # Can mix with the standard emulation-ices: sh, bash, ksh, csh, zsh (the
    # default one)

    zinit sh opts"kshglob" for zdharma-continuum/test

    # Outputs `on' for the SH_GLOB, because sh-emulation sets this option
    on on
    ```

- 07-05-2020

  - A new `from''` value is available — `cygwin`. It'll cause to download
    a package from the Cygwin repository — from a random mirror, and then
    unpack it. Example use:

    ```zsh
    # Install gzip and expose it through Bin-Gem-Node annex's sbin'' ice
    zinit from"cygwin" sbin"usr/bin/gzip.exe -> gzip" for gzip
    ```

- 16-04-2020

  - Turbo plugins will now get gracefully preinstalled first before the prompt
    (i.e.: within `zshrc` processing) and then loaded **still** as Turbo plugins.

- 15-04-2020

  - The `…/name.plugin.zsh` and `…/init.zsh` can be now skipped from single-file
    (non-svn) snippet URLs utilizing the `OMZ::…`, etc. shorthands. Example:

    ```zsh
    # Instead of: zinit for OMZP::ruby/ruby.plugin.zsh
    zinit for OMZP::ruby
    # Instead of: zinit for PZTM::rails/init.zsh
    zinit for PZTM::rails
    # Instead of: zinit for OMZT::gnzh.zsh-theme
    zinit for OMZT::gnzh
    ```

  - New prefixes `OMZP::` **=** `OMZ::/plugins/`, `OMZT::` **=**
    `OMZ::/themes/`, `OMZL::` **=** `OMZ::lib/`, `PZTM::` **=** `PZT::modules/`,
    for both svn and single-file snippets. Example use:

    ```zsh
    zinit for OMZP::ruby/ruby.plugin.zsh
    zinit svn for OMZP::ruby
    ```

    (instead of:

    ```zsh
    zinit for OMZ::plugins/ruby/ruby.plugin.zsh
    zinit svn for OMZ::plugins/ruby
    ```

    ).

- 12-04-2020

  - A new document on the Wiki is available — about the [**bindmap''
    ice**](https://zdharma-continuum.github.io/zinit/wiki/Bindkeys/).
  - If `id-as''` will have no value, then it'll work as
    [**id-as'auto'**](https://zdharma-continuum.github.io/zinit/wiki/id-as/#id-asauto).

- 07-04-2020

  - A new feature — `param''` ice that defines params for the time of loading of
    the plugin or snippet. E.g.:

    ```zsh
    # Equivalent of `local myparam=1 myparam2=1' right before loading of the plugin
    zinit param'myparam → 1; myparam2 -> 1' for zdharma-continuum/null
    # Equivalent of `local myparam myparam2' before loading of the plugin
    zinit param'myparam; myparam2' for zdharma-continuum/null
    ```

  - The `atinit''` ice can now be investigated — if it'll be prepended with `!`,
    i.e.: `atinit'!…'`.

- 01-04-2020

  - As a user [noticed](https://github.com/zdharma-continuum/zinit/issues/293), Subversion
    isn't distributed with Xcode Command Line Tools anymore. Here's a [helpful
    snippet](https://www.reddit.com/r/zinit/wiki/gallery#wiki_building_and_installation_of_subversion)
    that installs Subversion with use of Zinit.

- 27-02-2020

  - An **important fix** has been pushed — due to a bug Turbo has been disabled
    for non-for syntax invocations of Zinit. Issue `zinit self-update` to
    resolve the mistake.
    - If you haven't updated yesterday, please restrain from running `zinit update` immediately after `self-update`. Support for reloading Zinit after
      `self-update` has been pushed yesterday and after pulling this feature,
      you'll be able to freely invoke `self-update` and `update`.

- 26-02-2020

  - From now on `zinit self-update` reloads Zinit for the current session (after
    updating the plugin manager), and `zinit update --all/-p/--parallel` detects
    that `self-update` has been run in **another session** and also reloads Zinit
    right before performing the update. This way the update code is always the
    newest and consistent.

- 26-02-2020

  - If the loaded object (plugin or snippet) is not already installed when
    loading, then Turbo gets automatically disabled for this single loading of
    the object — it'll be installed before prompt, not after it and also
    immediately (without waiting the number of seconds given to `wait''`), i.e.:
    during the normal processing of `zshrc`, which intuitively is the expected
    behavior.
  - The additional disk accesses for the checks cost about 10 ms out of 150 ms
    (i.e.: the Zsh startup time increases from 140 ms to 150 ms). If you want,
    you may disable the feature by setting `$ZINIT[OPTIMIZE_OUT_DISK_ACCESSES]`
    to `1`.
  - A bug in Turbo has been fixed that was delaying the objects' loadings,
    especially when there were no keystrokes issued.

- 20-02-2020

  - A new feature - **parallel updates** of all plugins and snippets — Zinit runs
    series of spawned concurrent-job groups of size 15 to speed up the update process.
    To activate, pass `-p`/`--parallel` to `update`, e.g.:

    ```zsh
    zinit update -p
    zinit update --parallel
    # Increase the number of jobs in a concurrent-set to 40
    zinit update --parallel 40
    ```

    See demos: [asciicast1](https://asciinema.org/a/303174),
    [asciicast2](https://asciinema.org/a/303184).

  - A new article is available on the Wiki — about the
    [**`extract`**](https://zdharma-continuum.github.io/zinit/wiki/extract-Ice/) ice.

- 19-02-2020

  The project has a fresh, new subreddit [r/zinit](https://www.reddit.com/r/zinit/).
  You can also visit the old subreddit [r/zplugin](https://www.reddit.com/r/zplugin/).

- 09-02-2020

  Note that the ice `extract` can handle files with spaces — to encode such a name use
  the non-breaking space (Right Alt + Space) in place of the in-filename spaces :).

- 07-02-2020

  - A new ice `extract` which extracts:
    - all files with recognized archive extensions like `zip`, `tar.gz`, etc.,
    - if no such files will be found, then: all files with recognized archive
      **types** (examined with the `file` command),
    - OR, IF GIVEN — the given files, e.g.: `extract'file1.zip file2.tgz'`,
    - the automatic searching for archives ignores files in sub-sub-directories and
      located deeper,
  - It has a `!` flag — i.e.: `extract'!…'` — it'll cause the files to be moved
    one directory-level up upon unpacking,
  - and also a `-` flag — i.e.: `extract'-…'` — it'll prevent removal of the archive
    after unpacking; useful to allow comparing timestamps with the server in case of
    snippet-downloaded file,
  - the flags can be combined, e.g.: `extract'!-'`,
  - also, the function `ziextract` has a new option `--auto`, which causes the
    automatic behavior identical to the empty `extract` ice.

- 21-01-2020

  - A few tips for the project rename following the field reports (the issues created
    by users):
    - the `ZPLGM` hash is now `ZINIT`,
    - the annexes are moved under [zdharma-continuum](https://github.com/zdharma-continuum)
      organization.

- 19-01-2020

  - The name has been changed to **Zinit** based on the results of the
    [poll](https://github.com/zdharma-continuum/zinit/issues/235).
  - In general, you don't have to do anything after the name change.
  - Only a run of `zinit update --all` might be necessary.
  - You might also want to rename your `zplugin` calls in `zshrc` to `zinit`.
  - Zinit will reuse `~/.zplugin` directory if it exists, otherwise it'll create
    `~/.zinit`.

- 15-01-2020

  - There's a new function, `ziextract`, which unpacks the given file. It supports many
    formats (notably also `dmg` images) — if there's a format that's unsupported please
    don't hesitate to [make a
    request](https://github.com/zdharma-continuum/zinit/issues/new?template=feature_request.md)
    for it to be added. A few facts:
    - the function is available only at the time of the plugin/snippet installation,
    - it's to be used within `atclone` and `atpull` ices,
    - it has an optional `--move` option which moves all the files from a subdirectory
      up one level,
    - one other option `--norm` prevents the archive from being deleted upon unpacking.
  - snippets now aren't re-downloaded unless they're newer on the HTTP server; use
    this with the `--norm` option of `ziextract` to prevent unnecessary updates; for
    example, the [firefox-dev package](https://github.com/zdharma-continuum/zsh-package-firefox-dev)
    uses this option for this purpose,
  - GitHub doesn't report proper `Last-Modified` HTTP server for the files in the
    repositories so the feature doesn't yet work with such files.

- 13-12-2019

  - The packages have been disconnected from NPM registry and now live only on Zsh
    Packages organization. Publishing to NPM isn't needed.

  - There are two interesting packages,
    [any-gem](https://github.com/zdharma-continuum/zsh-package-any-gem) and
    [any-node](https://github.com/zdharma-continuum/zsh-package-any-node). They allow to install any
    Gem(s) or Node module(s) locally in a newly created plugin directory. For example:

    ```zsh
    zinit pack param='GEM -> rails' for any-gem
    zinit pack param='MOD -> doctoc' for any-node
    # To have the command in zshrc, add an id-as'' ice so that
    # Zinit knows that the package is already installed
    # (also: the Unicode arrow is allowed)
    zinit id-as=jekyll pack param='GEM → jekyll' for any-gem
    ```

    The binaries will be exposed without altering the PATH via shims
    ([Bin-Gem-Node](https://github.com/zdharma-continuum/z-a-bin-gem-node) annex is needed).
    Shims are correctly removed when deleting a plugin with `zinit delete …`.

- 11-12-2019

  - Zinit now supports installing special-Zsh NPM packages! Bye-bye the long and
    complex ice-lists! Check out the
    [Wiki](https://zdharma-continuum.github.io/zinit/wiki/Zinit-Packages/) for an introductory document
    on the feature.

- 25-11-2019

  - A new subcommand `run` that executes a command in the given plugin's directory. It
    has an `-l` option that will reuse the previously provided plugin. So that it's
    possible to do:

    ```zsh
    zplg run my/plugin ls
    zplg run -l cat \*.plugin.zsh
    zplg run -l pwd
    ```

- 07-11-2019

  - Added a prefix-char: `@` that can be used before plugins if their name collides
    with one of the ice-names. For example `sharkdp/fd` collides with the `sh` ice
    (which causes the plugin to be loaded with the POSIX `sh` emulation applied). To
    load it, do e.g.:

    ```zsh
    zinit as"null" wait"2" lucid from"gh-r" for \
        mv"exa* -> exa" sbin"exa"  ogham/exa \
        mv"fd* -> fd" sbin"fd/fd"  @sharkdp/fd \
        sbin"fzf" junegunn/fzf-bin
    ```

    i.e.: precede the plugin name with `@`. Note: `sbin''` is an ice added by the
    [z-a-bin-gem-node](https://github.com/zinit/z-a-bin-gem-node) annex, it provides
    the command to the command line without altering `$PATH`.

    See the [Zinit Wiki](https://zdharma-continuum.github.io/zinit/wiki/For-Syntax/) for more
    information on the for-syntax.

- 06-11-2019

  - A new syntax, called for-syntax. Example:

    ```zsh
     zinit as"program" atload'print Hi!' for \
         atinit'print First!' zdharma-continuum/null \
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
    /root/.zinit/plugins/zdharma-continuum---null
    ```

    To load in light mode, use a new `light-mode` ice. More examples and information
    can be found on the [Zinit Wiki](https://zdharma-continuum.github.io/zinit/wiki/For-Syntax/).

- 03-11-2019

  - A new value for the `as''` ice — `null`. Specifying `as"null"` is like specifying
    `pick"/dev/null" nocompletions`, i.e.: it disables the sourcing of the default
    script file of a plugin or snippet and also disables the installation of
    completions.

- 30-10-2019

  - A new ice `trigger-load''` — create a function that loads given plugin/snippet,
    with an option (to use it, precede the ice content with `!`) to automatically
    forward the call afterwards. Example use:

    ```zsh
    # Invoking the command `crasis' will load the plugin that
    # provides the function `crasis', and it will be then
    # immediately invoked with the same arguments
    zinit ice trigger-load'!crasis'
    zinit load zdharma-continuum/zinit-crasis
    ```

- 22-10-2019

  - A new ice `countdown` — causes an interruptable (by Ctrl-C) countdown 5…4…3…2…1…0
    to be displayed before running the `atclone''`, `atpull''` and `make` ices.

- 21-10-2019

  - The `times` command has a new option `-m` — it shows the **moments** of the plugin
    load times — i.e.: how late after loading Zinit a plugin has been loaded.

- 20-10-2019

  - The `zinit` completion now completes also snippets! The command `snippet`, but
    also `delete`, `recall`, `edit`, `cd`, etc. all receive such completing.
  - The `ice` subcommand can now be skipped — just pass in the ices, e.g.:
    ```zsh
    zinit atload"zicompinit; zicdreplay" blockf
    zinit light zsh-users/zsh-completions
    ```
  - The `compile` command is able to compile snippets.
  - The plugins that add their subdirectories into `$fpath` can be now `blockf`-ed —
    the functions located in the dirs will be correctly auto-loaded.

- 12-10-2019

  - Special value for the `id-as''` ice — `auto`. It sets the plugin/snippet ID
    automatically to the last component of its spec, e.g.:

    ```zsh
    zinit ice id-as"auto"
    zinit load robobenklein/zinc
    ```

    will load the plugin as `id-as'zinc'`.

- 14-09-2019

  - There's a Vim plugin which extends syntax highlighting of zsh scripts with coloring
    of the Zinit commands. [Project
    homepage](https://github.com/zinit/zinit-vim-syntax).

- 13-09-2019

  - New ice `aliases` which loads plugin with the aliases mechanism enabled. Use for
    plugins that define **and use** aliases in their scripts.

- 11-09-2019

  - New ice-mods `sh`,`bash`,`ksh`,`csh` that load plugins (and snippets) with the
    **sticky emulation** feature of Zsh — all functions defined within the plugin will
    automatically switch to the desired emulation mode before executing and switch back
    thereafter. In other words it is now possible to load e.g. bash plugins with
    Zinit, provided that the emulation level done by Zsh is sufficient, e.g.:

    ```zsh
    zinit ice bash pick"bash_it.sh" \
            atinit"BASH_IT=${ZINIT[PLUGINS_DIR]}/Bash-it---bash-it" \
            atclone"yes n | ./install.sh"
    zinit load Bash-it/bash-it
    ```

    This script loads correctly thanks to the emulation, however it isn't functional
    because it uses `type -t …` to check if a function exists.

- 10-09-2019

  - A new ice-mod `reset''` that ivokes `git reset --hard` (or the provided command)
    before `git pull` and `atpull''` ice. It can be used it to implement altering (i.e.
    patching) of the plugin's files inside the `atpull''` ice — `git` will report no
    conflicts when doing `pull`, and the changes can be then again introduced by the
    `atpull''` ice.

  - Three new Zinit annexes (i.e.
    [extensions](https://zdharma-continuum.github.io/zinit/wiki/Annexes/)):

    - [z-a-man](https://github.com/zinit/z-a-man)

      Generates man pages and code-documentation man pages from plugin's README.md
      and source files (the code documentation is obtained from
      [Zshelldoc](https://github.com/zdharma-continuum/zshelldoc)).

    - [z-a-test](https://github.com/zinit/z-a-test)

      Runs tests (if detected `test` target in a `Makefile` or any `*.zunit` files)
      on plugin installation and non-empty update.

    - [z-a-patch-dl](https://github.com/zinit/z-a-patch-dl)

      Allows easy download and applying of patches, to e.g. aid building a binary
      program equipped in the plugin.

  - A new variable is being recognized by the installation script:
    `$ZPLG_BIN_DIR_NAME`. It configures the directory within `$ZPLG_HOME` to which
    Zinit should be cloned.

</details>
