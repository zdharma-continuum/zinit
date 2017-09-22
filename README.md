![zplugin logo](https://raw.githubusercontent.com/psprint/zplugin/master/doc/img/zplugin.png)

[![paypal](https://www.paypalobjects.com/en_US/i/btn/btn_donateCC_LG.gif)](https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=D6XDCHDSBDSDG)

# Zplugin

Zplugin gives **reports** from plugin load. Plugins are no longer black boxes,
report will tell what aliases, functions, bindkeys, Zle widgets, zstyles,
completions, variables, `PATH` and `FPATH` elements a plugin has set up. Supported is
**unloading** of plugin and ability to list, uninstall, reinstall and selectively
disable, enable plugin's completions. Also, every plugin is compiled and user
can control this function. The system does not use `$FPATH`, it's kept clean!

Code is immune to `KSH_ARRAYS`, `emulate sh`, `emulate ksh`, thoroughly tested to
support any user setup, be as transparent as plain `source` command. Completion
management functionality is provided to allow user call `compinit` only once in
`.zshrc`.

# Quick start

To install, execute:

```SystemVerilog
sh -c "$(curl -fsSL https://raw.githubusercontent.com/psprint/zplugin/master/doc/install.sh)"
```

Then add to `~/.zshrc`, at bottom:

```SystemVerilog
zplugin load psprint zsh-navigation-tools
zplugin ice from"notabug" atload"echo loaded zui" if"(( 1 ))"
zplugin load zdharma/zui
zplugin load zsh-users/zsh-autosuggestions
zplugin light zsh-users/zsh-syntax-highlighting
# This one to be ran just once, in interactive session
zplugin creinstall %HOME/my_completions  # Handle completions without loading the plugin, see "clist" command
```

(No need to add:

```SystemVerilog
source "$HOME/.zplugin/bin/zplugin.zsh"
```

because the install script does this.)

`ZNT` – multi-word searching of history (Ctrl-R), `zui` – textual UI library for Zshell.
The `ice` subcommand – modifiers for following single command. `notabug` – the site `notabug.org`

# News
* 20-09-2017
  - New feature - **plugin load time statistics**

    ```SystemVerilog
    % zplg times
    Plugin loading times:
    0.002 sec - psprint/history-search-multi-word
    0.005 sec - psprint/zsh-navigation-tools
    0.002 sec - rimraf/k
    0.020 sec - zdharma/fast-syntax-highlighting
    0.005 sec - zsh-users/zsh-autosuggestions
    ```

* 13-06-2017
  - Plugins can now be absolute paths:

    ```SystemVerilog
    % zplg load %HOME/github/{directory}
    % zplg load /Users/sgniazdowski/github/{directory}
    % zplg load %/Users/sgniazdowski/github/{directory}
    ```

    Completions are not automatically managed, but user can run `zplg creinstall %HOME/github/{directory}`, etc.

* 23-05-2017
  - New `ice` modifier: `if`, to which you can provide a conditional expression

    ```SystemVerilog
    % zplg ice if"(( 0 ))"
    % zplg snippet --command https://github.com/b4b4r07/httpstat/blob/master/httpstat.sh
    % zplg ice if"(( 1 ))"
    % zplg snippet --command https://github.com/b4b4r07/httpstat/blob/master/httpstat.sh
    Setting up snippet httpstat.sh
    Downloading httpstat.sh...
    ```

* 16-05-2017
  - A very slick feature: **adding ice to commands**. Ice is something added and something that
    melts. You add modifiers to single next command, and the format (using quotes) guarantees
    you will see syntax highlighting in editors:

    ```SystemVerilog
    % zplg ice from"notabug" atload"echo --Loaded--" atclone"echo --Cloned--"
    % zplg load zdharma/zui
    Downloading zdharma/zui...
    ...
    Checking connectivity... done.
    --Cloned--
    Compiling zui.plugin.zsh...
    --Loaded--
    % grep notabug ~/.zplugin/plugins/zdharma---zui/.git/config
        url = https://notabug.org/zdharma/zui
    ```

    One other `ice` is `proto`. Use `proto"git"` with Github to be able to use private repositories.

  - Completion-management supports completions provided in subdirectory, like in `zsh-users/zsh-completions`
    plugin. With `ice` modifier `blockf` (block-fpath), you can manage such completions:

    ```SystemVerilog
    % zplg ice blockf
    % zplg load zsh-users/zsh-completions
    ...
    Symlinking completion `_ack' to /Users/sgniazdowski/.zplugin/completions
    Forgetting completion `_ack'...

    Symlinking completion `_afew' to /Users/sgniazdowski/.zplugin/completions
    Forgetting completion `_afew'...
    ...
    Compiling zsh-completions.plugin.zsh...
    % echo $fpath
    /Users/sgniazdowski/.zplugin/completions /usr/local/share/zsh/site-functions
    % zplg cdisable vagrant
    Disabled vagrant completion belonging to zsh-users/zsh-completions
    Forgetting completion `_vagrant'...

    Initializing completion system (compinit)...
    ```

* 14-05-2017
  - The `all`-variants of commands (e.g. `update-all`) have been merged into normal variants (with `--all` switch)

* 13-05-2017
  - Bug fixes related to local plugins
  - `100` `ms` gain in performance
  - When updating plugin a list of new commits is shown
  - `lftp` as fallback transport support for snippets
  - Snippets support `ftp` and `scp` protocols
  - With snippets you can load a file as **command** that is added to PATH:

    ```SystemVerilog
    % zplg snippet --command https://github.com/b4b4r07/httpstat/blob/master/httpstat.sh
    % httpstat.sh
    too few arguments
    ```

  - Snippets are updated on `update --all` command

# Screencasts

**Dtrace:**

![dtrace](http://imageshack.com/a/img924/2539/eCfnUD.gif)

**Code recognition with recently, changes, glance, report, stress:**

![code recognition](http://imageshack.com/a/img923/6404/5mOUl2.gif)

# Introduction

![zplugin-refcard](http://imageshack.com/a/img924/7014/KKkzny.png)

**Example use:**

```SystemVerilog
% . ~/github/zplugin/zplugin.zsh
% zplugin light zsh-users/zsh-syntax-highlighting
% zplugin load psprint/zsh-cmd-architect
```

**Example plugin report:**

![report example](http://imageshack.com/a/img923/4237/OHC0i5.png)

**Example plugin unload:**

![unload example](http://imageshack.com/a/img921/9896/rMMnQ1.png)

**Example `csearch` invocation (completion management):**

![csearch example](http://imageshack.com/a/img921/5741/QJaO8q.png)

**Example `compile` invocation:**

![compile example](http://imageshack.com/a/img923/6655/gexv8M.png)

**Example `create` invocation:**

![create example](http://imageshack.com/a/img921/8966/NURP24.png)

# Ice Modifiers

Following `ice` modifiers are passed to `zplg ice ...` to obtain described effects.

|  Modifier | Description |
|-----------|-------------|
| `from`    | Clone from given site (Github is the default), supported are `from"gitlab"`, `..."bitbucket"`, `..."notabug"` (short names: `gh`, `gl`, `bb`, `nb`) |
| `blockf`  | Disallow plugin to modify `fpath` |
| `atclone` | Run command after cloning, within plugin's directory, e.g. `zplg ice atclone"echo Cloned"` |
| `atload`  | Run command after loading, within plugin's directory |
| `atpull`  | Run command after updating, within plugin's directory |
| `if`      | Load plugin or snippet when condition is meet, e.g. `zplg ice if'[[ -n "$commands[otool]" ]]'; zplugin load ...` |
| `proto`   | Change protocol to `git`,`ftp`,`ftps`,`ssh`, etc. |

# Installation

Execute:

```sh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/psprint/zplugin/master/doc/install.sh)"
```

To update run the command again (or just execute `doc/install.sh`) or run `zplugin self-update`.

`Zplugin` will be installed into `~/.zplugin/bin`. `.zshrc` will be updated with
three lines of code that will be added to the bottom (the lines will be sourcing
`zplugin.zsh` and setting up completion).

Completion will be available, for command **zplugin** and aliases **zpl**, **zplg**.

After installing and reloading shell give `Zplugin` a quick try with `zplugin help`.

## Manual installation

To manually install `Zplugin` clone the repo to e.g. `~/.zplugin/bin`:

```sh
mkdir ~/.zplugin
git clone https://github.com/psprint/zplugin.git ~/.zplugin/bin
```

and source it from `.zshrc` (**above compinit**):

```sh
source ~/.zplugin/bin/zplugin.zsh
```

If you place the `source` below `compinit`, then add those two lines after the `source`:
```sh
autoload -Uz _zplugin
(( ${+_comps} )) && _comps[zplugin]=_zplugin
```

After installing and reloading shell give `Zplugin` a quick try with `zplugin help`.

# Compilation
It's good to compile `zplugin` into `Zsh` bytecode:

```sh
zcompile ~/.zplugin/bin/zplugin.zsh
```

Zplugin will compile each newly downloaded plugin. You can clear compilation of
a plugin by invoking `zplugin uncompile {plugin-spec}`. There are also commands
`compile`, `compiled` that control the functionality of compiling plugins.

# Usage

```
% zpl help
Usage:
-h|--help|help           - usage information
man                      - manual
self-update              - updates Zplugin
zstatus                  - overall Zplugin status
times                    - statistics on plugin loading times
load {plugin-name}       - load plugin, can also receive absolute local path
light {plugin-name}      - light plugin load, without reporting (faster)
unload {plugin-name}     - unload plugin (needs reporting)
snippet [-f] [--command] {url} - source (or add to PATH with --command) local or remote file (-f: force - don't use cache)
update {plugin-name}     - Git update plugin (or all plugins and snippets if --all passed)
status {plugin-name}     - Git status for plugin (or all plugins if --all passed)
report {plugin-name}     - show plugin's report (or all plugins' if --all passed)
loaded|list [keyword]    - show what plugins are loaded (filter with `keyword')
cd {plugin-name}         - cd into plugin's directory (does completion on TAB)
create {plugin-name}     - create plugin (also together with Github repository)
edit {plugin-name}       - edit plugin's file with $EDITOR
glance {plugin-name}     - look at plugin's source (pygmentize, highlight, GNU source-highlight)
stress {plugin-name}     - test plugin for compatibility with set of options
changes {plugin-name}    - view plugin's git log
recently [time-spec]     - show plugins that changed recently, argument is e.g. 1 month 2 days
clist|completions        - list completions in use
cdisable {cname}         - disable completion `cname'
cenable  {cname}         - enable completion `cname'
creinstall {plugin-name} - install completions for plugin; can also receive absolute local path
cuninstall {plugin-name} - uninstall completions for plugin
csearch                  - search all for available completions from any plugin, even unused ones
compinit                 - reload installed completions
dtrace|dstart            - start tracking what's going on in session
dstop                    - stop tracking what's going on in session
dunload                  - revert changes recorded between dstart and dstop
dreport                  - report what was going on in session
dclear                   - clear report of what was going on in session
compile  {plugin-name}   - compile plugin (or all plugins if --all passed)
uncompile {plugin-name}  - remove compiled version of plugin (or of all plugins if --all passed)
compiled                 - list plugins that are compiled
```

To use themes created for `Oh-My-Zsh` you might want to first source the `git` library there:

```sh
zplugin snippet 'http://github.com/robbyrussell/oh-my-zsh/raw/master/lib/git.zsh'
```

Then you can use the themes as snippets (`zplugin snippet {file path or Github URL}`).
Some themes require not only
`Oh-My-Zsh's` `git` library, but also `git` plugin (error about function `current_branch` appears).
Source it as snippet directly from `Oh-My-Zsh`:

```sh
zplugin snippet 'https://github.com/robbyrussell/oh-my-zsh/raw/master/plugins/git/git.plugin.zsh'
```

Such lines should be added to `.zshrc`. Snippets are cached locally, use `-f` option to download
a fresh version of a snippet.

Most themes require `promptsubst` option (`setopt promptsubst` in `zshrc`), if it isn't set prompt
will appear as something like: `$(build_prompt)`.

You might want to supress completions provided by the git plugin by issuing `zplugin cdclear -q`
(`-q` is for quiet) – see below **Ignoring Compdefs**.

To summarize:

```SystemVerilog
zplugin snippet 'http://github.com/robbyrussell/oh-my-zsh/raw/master/lib/git.zsh'
zplugin snippet 'https://github.com/robbyrussell/oh-my-zsh/raw/master/plugins/git/git.plugin.zsh'
zplugin cdclear -q # <- forget completions provided up to this moment
setopt promptsubst
# Load theme
zplugin snippet 'https://github.com/robbyrussell/oh-my-zsh/blob/master/themes/dstufft.zsh-theme'
# Load plugin-theme depending on OMZ git library
zplugin light NicoSantangelo/Alpharized
```

# Calling compinit

Compinit should be called after loading of all plugins and before possibly calling `cdreply`.
`Zplugin` takes control over completions, symlinks them to `~/.zplugin/completions` and adds
this directory to `$FPATH`. You manage those completions via commands starting with `c`:
`csearch`, `clist`, `creinstall`, `cuninstall`, `cenable`, `cdisable`.
All this brings order to `$FPATH`, there is only one directory there. 
Also, plugins aren't allowed to simply run `compdefs`. You can decide whether to run `compdefs`
by issuing `zplugin cdreplay` (`compdef`-replay). To summarize:

```sh
source ~/.zplugin/bin/zplugin.zsh

zplugin load "some/plugin"
...
zplugin load "other/plugin"

autoload -Uz compinit
compinit

zplugin cdreplay -q # -q is for quiet
```

This allows to call compinit once.
Performance gains are huge, example shell startup time with double `compinit`: **0.980** sec, with
`cdreplay` and single `compinit`: **0.156** sec.

# Ignoring Compdefs

If you want to ignore `compdef`s provided by some plugins or snippets, place their load commands
before commands loading other plugins or snippets, and issue `zplugin cdclear`:

```sh
source ~/.zplugin/bin/zplugin.zsh
zplugin snippet https://github.com/robbyrussell/oh-my-zsh/blob/master/plugins/git/git.plugin.zsh
zplugin cdclear -q # <- forget completions provided up to this moment

zplugin load "some/plugin"
...
zplugin load "other/plugin"

autoload -Uz compinit
compinit
zplugin cdreplay -q # <- execute compdefs provided by rest of plugins
zplugin cdlist # look at gathered compdefs
```

# Non-Github (local) plugins

Use `create` command with user name `_local` (the default) to create plugin's
skeleton. It will be not connected with Github repository (because of user name
being `_local`). To enter the plugin's directory use `cd` command with just
plugin's name (without `_local`).

The special user name `_local` is optional also for other commands, e.g. for
`load` (i.e. `zplugin load myplugin` is sufficient, there's no need for
`zplugin load _local/myplugin`).

# Customizing paths

Following variables can be set to custom values, before sourcing Zplugin:

```
local -A ZPLGM # (initial Zplugin hash definition)
ZPLGM[BIN_DIR] – where Zplugin code resides, e.g.: "/home/user/.zplugin/bin"
ZPLGM[HOME_DIR] – where Zplugin should create all working directories, e.g.: "/home/user/.zplugin"
ZPLGM[PLUGINS_DIR] – override single working directory – for plugins, e.g. "/opt/zsh/zplugin/plugins"
ZPLGM[COMPLETIONS_DIR] – as above, for completion files, e.g. "/opt/zsh/zplugin/root_completions"
ZPLGM[SNIPPETS_DIR] – as above, for snippets
```

# IRC channel
Simply connect to [chat.freenode.net:6697](ircs://chat.freenode.net:6697/%23zplugin) (SSL) or [chat.freenode.net:6667](irc://chat.freenode.net:6667/%23zplugin) and join #zplugin.

Following is a quick access via Webchat [![IRC](https://kiwiirc.com/buttons/chat.freenode.net/zplugin.png)](https://kiwiirc.com/client/chat.freenode.net:+6697/#zplugin)
