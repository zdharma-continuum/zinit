![zew logo](http://imageshack.com/a/img907/2224/62TFk9.png)

# Zplugin

Zplugin in action:

![zplugin](http://imageshack.com/a/img905/5575/n3p47o.gif)

Completion handling:

![zplugin](http://imageshack.com/a/img907/2167/CATuag.gif)

## Introduction

Example use:

```
% . ~/github/zplugin/zplugin.zsh
% zplugin load psprint/zsh-cmd-architect
```

Example plugin report:

```
% zplugin report psprint/zsh-cmd-architect
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
            h-list        h-list-draw
      h-list-input                zca
zca-usetty-wrapper         zca-widget
```

Example plugin unload:

```
% zplugin unload psprint/zsh-cmd-architect
Deleting function h-list
Deleting function h-list-draw
Deleting function h-list-input
Deleting function zca
Deleting function zca-usetty-wrapper
Deleting function zca-widget
Deleting bindkey ^T zca-widget
Unregistering plugin psprint/zsh-cmd-architect
Plugin's report saved to $LASTREPORT
```

