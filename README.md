![zew logo](http://imageshack.com/a/img907/2224/62TFk9.png)

# Zplugin

Zplugin gives **reports** from plugin load. Plugins are no longer black boxes,
report will tell what aliases, functions, bindkeys, Zle widgets, zstyles,
completions, `PATH` and `FPATH` elements a plugin has set up. Supported is
**unloading** of plugin and ability to list, uninstall, reinstall and selectively
disable, enable plugin's completions. The system doesn't use `$FPATH`, it's kept
clean!

Zplugin in action:

![zplugin](http://imageshack.com/a/img905/5575/n3p47o.gif)

Completion handling:

![zplugin](http://imageshack.com/a/img907/2167/CATuag.gif)

## Introduction

Example use:

```
% . ~/github/zplugin/zplugin.zsh
% zplugin load zsh-users/zsh-syntax-highlighting
% zplugin load psprint/zsh-cmd-architect
```

Example plugin report:

```
% zpl report psprint/zsh-cmd-architect
Plugin report for psprint/zsh-cmd-architect
-------------------------------------------
Source zsh-cmd-architect.plugin.zsh
Autoload h-list
Autoload h-list-input
Autoload h-list-draw
Autoload zca
Autoload zca-usetty-wrapper
Autoload zca-widget
Zle -N zca-widget
Bindkey ^T zca-widget

Functions created:
h-list             h-list-draw
h-list-input       zca
zca-usetty-wrapper zca-widget

Options changed:
autolist     was unset
menucomplete was unset

PATH elements added:
/Users/sgniazdowski/github/zsh-cmd-architect/bin

FPATH elements added:
/Users/sgniazdowski/github/zsh-cmd-architect

Completions:
_xauth [disabled]
```

![report example](http://imageshack.com/a/img923/4237/OHC0i5.png)

Example plugin unload:

```
% zpl unload psprint/zsh-cmd-architect
Deleting function h-list
Deleting function h-list-draw
Deleting function h-list-input
Deleting function zca
Deleting function zca-usetty-wrapper
Deleting function zca-widget
Deleting bindkey ^T zca-widget
Setting option autolist
Setting option menucomplete
Removing PATH element /Users/sgniazdowski/github/zsh-cmd-architect/bin
Removing FPATH element /Users/sgniazdowski/github/zsh-cmd-architect
Unregistering plugin psprint/zsh-cmd-architect
Plugin's report saved to $LASTREPORT
```

![unload example](http://imageshack.com/a/img921/9896/rMMnQ1.png)

## Installation

Execute:

```sh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/psprint/zplugin/master/doc/install.sh)"
```

To update run the command again.

`Zplugin` will be installed into `~/.zplugin/bin`. `.zshrc` will be updated with
single line of code that will be added to the bottom (it will be sourcing
`zplugin.zsh` for you). Completion will be available, for command `zplugin` and
aliases `zpl`, `zplg`.

To manually install `Zplugin` clone the repo to e.g. `~/.zplugin/bin`:

```sh
mkdir ~/.zplugin
git clone https://github.com/psprint/zplugin.git ~/.zplugin/bin
```

and source it from `.zshrc`:

```sh
source ~/.zplugin/bin/zplugin.zsh
```

After installing and reloading shell give `Zplugin` a quick try with `zplugin help`.

## Usage

```
% zpl help
Usage:
-h|--help|help           - usage information
self-update              - updates Zplugin
load {plugin-name}       - load plugin
light {plugin-name}      - light plugin load, without reporting
unload {plugin-name}     - unload plugin
update {plugin-name}     - update plugin (Git)
update-all               - update all plugins (Git)
status {plugin-name}     - status for plugin (Git)
status-all               - status for all plugins (Git)
report {plugin-name}     - show plugin's report
all-reports              - show all plugin reports
loaded|list [keyword]    - show what plugins are loaded (filter with `keyword')
clist|completions        - list completions in use
cdisable {cname}         - disable completion `cname'
cenable  {cname}         - enable completion `cname'
creinstall {plugin-name} - install completions for plugin
cuninstall {plugin-name} - uninstall completions for plugin
csearch                  - search for available completions from any plugin
compinit                 - refresh installed completions
```
