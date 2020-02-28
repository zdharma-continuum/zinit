# Introduction

In the document below you’ll find out how to:

  - use Oh My Zsh and Prezto,

  - manage completions,

  - use the Turbo mode,

  - use the ice-mods like `as"program"`,

and much more.

## Basic Plugin Loading

``` zsh
zinit load zdharma/history-search-multi-word
zinit light zsh-users/zsh-syntax-highlighting
```

Above commands show two ways of basic plugin loading. <code>load </code>  causes reporting to
be enabled – you can track what plugin does, view the information with `zinit
report {plugin-spec}` and then also unload the plugin with `zinit unload
{plugin-spec}`. `light` is a significantly faster loading without tracking and
reporting, by using which user resigns of the ability to view the plugin report
and to unload it.

!!!note
    **In Turbo mode the slowdown caused by tracking is negligible.**

## Oh My Zsh, Prezto

To load Oh My Zsh and Prezto plugins, use `snippet` feature. Snippets are single
files downloaded by `curl`, `wget`, etc. (an automatic detection of the download
tool is being performed) directly from URL. For example:

``` zsh
zinit snippet 'https://github.com/robbyrussell/oh-my-zsh/raw/master/plugins/git/git.plugin.zsh'
zinit snippet 'https://github.com/sorin-ionescu/prezto/blob/master/modules/helper/init.zsh'
```

Also, for Oh My Zsh and Prezto, you can use `OMZ::` and `PZT::` shorthands:

``` zsh
zinit snippet OMZ::plugins/git/git.plugin.zsh
zinit snippet PZT::modules/helper/init.zsh
```

Moreover, snippets support Subversion protocol, supported also by Github. This
allows to load snippets that are multi-file (for example, a Prezto module can
consist of two or more files, e.g. `init.zsh` and `alias.zsh`). Default files
that will be sourced are: `*.plugin.zsh`, `init.zsh`, `*.zsh-theme`:

``` zsh
# URL points to directory
zinit ice svn
zinit snippet PZT::modules/docker
```

## Snippets and Performance

Using `curl`, `wget`, etc. along with Subversion allows to almost completely
avoid code dedicated to Oh My Zsh and Prezto, and also to other frameworks. This
gives profits in performance of `Zinit`, it is really fast and also compact
(causing low memory footprint and short loading time).

## Some Ice-Modifiers

The command `zinit ice` provides Ice-modifiers for single next command (see
the README subsection
[**ice-modifiers**](https://github.com/zdharma/zinit#ice-modifiers)). The
logic is that "ice" is something something that’s added (e.g. to a drink or a
coffee) – and in the Zinit sense this means that ice is a modifier added to
the next Zinit command, and also something that melts (so it doesn’t last
long) – and in the Zinit use it means that the modifier lasts for only single
next Zinit command. Using one other Ice-modifier "**pick**" user can
explicitly **select the file to source**:

``` zsh
zinit ice svn pick"init.zsh"
zinit snippet PZT::modules/git
```

Content of Ice-modifier is simply put into `"…"`, `'…'`, or `$'…'`. No
need for `":"` after Ice-mod name (although it's allowed, so as the equal sign
`=`, so e.g. `pick="init.zsh"` or `pick=init.zsh` are being correctly
recognized) . This way editors like `vim` and `emacs` and also
`zsh-users/zsh-syntax-highlighting` and `zdharma/fast-syntax-highlighting` will
highlight contents of Ice-modifiers.

## as"program"

A plugin might not be a file for sourcing, but a command to be added to `$PATH`.
To obtain this effect, use Ice-modifier `as` with value `program` (or an alias
value `command`).

``` zsh
zinit ice as"program" cp"httpstat.sh -> httpstat" pick"httpstat"
zinit light b4b4r07/httpstat
```

Above command will add plugin directory to `$PATH`, copy file `httpstat.sh` into
`httpstat` and add execution rights (`+x`) to the file selected with `pick`,
i.e. to `httpstat`. Other Ice-mod exists, `mv`, which works like `cp` but
**moves** a file instead of **copying** it. `mv` is ran before `cp`.

!!!note
    **The `cp` and `mv` ices (and also as some other ones, like `atclone`) are
    being run when the plugin or snippet is being _installed_. To test them
    again first delete the plugin or snippet by `zinit delete
    PZT::modules/osx` (for example).**

## atpull"…"

Copying file is safe for doing later updates – original files of repository are
unmodified and `Git` will report no conflicts. However, `mv` also can be used,
if a proper `atpull` (an Ice–modifier ran at **update** of plugin) will be used:

``` zsh
zinit ice as"program" mv"httpstat.sh -> httpstat" \
      pick"httpstat" atpull'!git reset --hard'
zinit light b4b4r07/httpstat
```

If `atpull` starts with exclamation mark, then it will be run before `git pull`,
and before `mv`. Nevertheless, `atpull`, `mv`, `cp` are ran **only if new
commits are to be fetched**. So in summary, when user runs `zinit update
b4b4r07/httpstat` to update this plugin, and there are new commits, what happens
first is that `git reset --hard` is ran – and it **restores** original
`httpstat.sh`, **then** `git pull` is ran and it downloads new commits (doing
fast-forward), **then** `mv` is ran again so that the command is `httpstat` not
`httpstat.sh`. This way the `mv` ice can be used to induce a permanent changes
into the plugin's contents without blocking the ability to update it with `git`
(or with `subversion` in case of snippets, more on this below at
[**\*\***](#on_svn_revert)).

!!!note
    **For exclamation mark to not be expanded by Zsh in interactive session, use
    `'…'` not `"…"` to enclose contents of `atpull` Ice-mod.**

## Snippets-Commands

Commands can also be added to `$PATH` using **snippets**. For example:

``` zsh
zinit ice mv"httpstat.sh -> httpstat" \
        pick"httpstat" as"program"
zinit snippet \
    https://github.com/b4b4r07/httpstat/blob/master/httpstat.sh
```

<a id="on_svn_revert"></a>
(**\*\***) Snippets also support `atpull` Ice-mod, so it’s possible to do e.g.
`atpull'!svn revert'`. There’s also `atinit` Ice-mod, executed before each
loading of plugin or snippet.

## Snippets-Completions

By using the `as''` ice-mod with value `completion` you can point the `snippet`
subcommand directly to a completion file, e.g.:

``` zsh
zinit ice as"completion"
zinit snippet https://github.com/docker/cli/blob/master/contrib/completion/zsh/_docker
```

## Completion Management

Zinit allows to disable and enable each completion in every plugin. Try
installing a popular plugin that provides completions:

``` zsh
zinit ice blockf
zinit light zsh-users/zsh-completions
```

First command (the `blockf` ice) will block the traditional method of adding
completions. Zinit uses own method (based on symlinks instead of adding a
number of directories to `$fpath`). Zinit will automatically **install**
completions of a newly downloaded plugin. To uninstall the completions and
install them again, you would use:

``` zsh
zinit cuninstall zsh-users/zsh-completions   # uninstall
zinit creinstall zsh-users/zsh-completions   # install
```

### Listing Completions

!!!note
    **`zi` is an alias that can be used in interactive sessions.**

To see what completions **all** plugins provide, in tabular formatting and with
name of each plugin, use:

``` zsh
zi clist
```

This command is specially adapted for plugins like `zsh-users/zsh-completions`,
which provide many completions – listing will have `3` completions per line (so
that a smaller number of terminal pages will be occupied) like this:

``` zsh
...
atach, bitcoin-cli, bower    zsh-users/zsh-completions
bundle, caffeinate, cap      zsh-users/zsh-completions
cask, cf, chattr             zsh-users/zsh-completions
...
```

You can show more completions per line by providing an **argument** to `clist`,
e.g. `zi clist 6`, will show:

``` zsh
...
bundle, caffeinate, cap, cask, cf, chattr      zsh-users/zsh-completions
cheat, choc, cmake, coffee, column, composer   zsh-users/zsh-completions
console, dad, debuild, dget, dhcpcd, diana     zsh-users/zsh-completions
...
```

### Enabling and Disabling Completions

Completions can be disabled, so that e.g. original Zsh completion will be used.
The commands are very basic, they only need completion **name**:

```zsh
$ zi cdisable cmake
Disabled cmake completion belonging to zsh-users/zsh-completions
$ zi cenable cmake
Enabled cmake completion belonging to zsh-users/zsh-completions
```

That’s all on completions. There’s one more command, `zinit csearch`, that
will **search** all plugin directories for available completions, and show if
they are installed:

![#csearch screenshot](img/csearch.png)

This sums up to complete control over completions.

## Subversion for Subdirectories

In general, to use **subdirectories** of Github projects as snippets add
`/trunk/{path-to-dir}` to URL, for example:

``` zsh
zinit ice svn
zinit snippet https://github.com/zsh-users/zsh-completions/trunk/src

# For Oh My Zsh and Prezto, the OMZ:: and PZT:: prefixes work
# without the need to add the `/trunk/` infix (however the path
# should point to a directory, not to a file):
zinit ice svn; zinit snippet PZT::modules/docker
```

Snippets too have completions installed by default, like plugins.

## Turbo Mode (Zsh \>= 5.3)

The Ice-mod `wait` allows the user postponing loading of a plugin to the moment
when the processing of `.zshrc` is finished and the first prompt is being shown.
It is like Windows – during startup, it shows desktop even though it still loads
data in background. This has drawbacks, but is for sure better than blank screen
for 10 minutes. And here, in Zinit, there are no drawbacks of this approach – no
lags, freezes, etc. – the command line is fully usable while the plugins are
being loaded, for any number of plugins. 

!!!note
    **Turbo will speed up Zsh startup by <u>50%–80%</u>. For example, instead of 200 ms, it'll be 40 ms (!)**

Zsh 5.3 or greater is required. To use this Turbo mode add `wait` ice to the
target plugin in one of following ways:

``` zsh
PS1="READY > "
zinit ice wait'!0' 
zinit load halfo/lambda-mod-zsh-theme
```

This sets plugin `halfo/lambda-mod-zsh-theme` to be loaded `0` seconds after
`zshrc`. It will fire up after c.a. 1 ms of showing of the basic prompt `READY >`.
You probably won't load the prompt in such a way, however it is a good example
in which Turbo can be directly observed.

The exclamation mark causes Zinit to reset-prompt after loading plugin, so it
is needed for themes. The same with Prezto prompts, with a longer delay:

``` zsh
zi ice svn silent wait'!1' atload'prompt smiley'
zi snippet PZT::modules/prompt
```

Using `zsh-users/zsh-autosuggestions` without any drawbacks:

``` zsh
zinit ice wait lucid atload'_zsh_autosuggest_start'
zinit light zsh-users/zsh-autosuggestions
```

Explanation: Autosuggestions uses `precmd` hook, which is being called right
after processing `zshrc` – `precmd` hooks are being called **right before
displaying each prompt**. Turbo with the empty `wait` ice will postpone the
loading `1` ms after that, so `precmd` will not be called at that first prompt.
This makes autosuggestions inactive at the first prompt. **However** the given
`atload` Ice-mod fixes this, it calls the same function that `precmd` would,
right after loading autosuggestions, resulting in exactly the same behavior of
the plugin.

The ice `lucid` causes the under-prompt message saying `Loaded
zsh-users/zsh-autosuggestions` that normally appears for every Turbo-loaded
plugin to not show.

### Turbo-Loading Sophisticated Prompts

For some, mostly advanced themes the initialization of the prompt is being done
in a `precmd`-hook, i.e.; in a function that's gets called before each prompt.
The hook is installed by the
[add-zsh-hook](http://zdharma.org/zinit/wiki/zsh-plugin-standard/#use_of_add-zsh-hook_to_install_hooks)
Zsh function by adding its name to the `$precmd_functions` array.

To make the prompt fully initialized after Turbo loading in the middle of the
prompt (the same situation as with the `zsh-autosuggestions` plugin), the hook
should be called from `atload''` ice.

First, find the name of the hook function by examining the `$precmd_functions`
array. For example, for `robobenklein/zinc` theme, they'll be two functions:
`prompt_zinc_setup` and `prompt_zinc_precmd`:

```zsh
root@sg > ~ > print $precmd_functions                       < ✔ < 22:21:33
_zsh_autosuggest_start prompt_zinc_setup prompt_zinc_precmd
```

Then, add them to the ice-list in the `atload''` ice:

```zsh
zinit ice wait'!' lucid nocd \
    atload'!prompt_zinc_setup; prompt_zinc_precmd'
zinit load robobenklein/zinc
```

The exclamation mark in `atload'!…'` is to track the functions allowing the
plugin to be unloaded, as described [here](../atload-and-other-at-ices/). It
might be useful for the multi-prompt setup described next.

## Automatic Load/Unload on Condition

Ices `load` and `unload` allow to define when you want plugins active or
unactive. For example:

``` zsh
# Load when in ~/tmp

zinit ice load'![[ $PWD = */tmp* ]]' unload'![[ $PWD != */tmp* ]]' \
    atload"!promptinit; prompt sprint3"
zinit load psprint/zprompts

# Load when NOT in ~/tmp

zinit ice load'![[ $PWD != */tmp* ]]' unload'![[ $PWD = */tmp* ]]'
zinit load russjohnson/angry-fly-zsh
```

Two prompts, each active in different directories. This technique can be used to
have plugin-sets, e.g. by defining parameter `$PLUGINS` with possible values
like `cpp`, `web`, `admin` and by setting `load` / `unload` conditions to
activate different plugins on `cpp`, on `web`, etc.

!!!note
    **The difference with `wait` is that `load` / `unload` are constantly
    active, not only till first activation.**

Note that for unloading of a plugin to work the plugin needs to be loaded with
tracking (so `zinit load …`, not `zinit light …`). Tracking causes
slight slowdown, however this doesn’t influence Zsh startup time when using
Turbo mode.

**See also Wiki on [multiple prompts](../Multiple-prompts/).** It contains a
more real-world examples of a multi-prompt setup, which is being close to what
the author uses in own setup.

[]( vim:set ft=markdown tw=80: )
