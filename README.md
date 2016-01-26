# Zplugin

Zplugin in action:

![zplugin](http://imageshack.com/a/img903/3610/lO3yDy.gif)

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
Plugins report saved to $LASTREPORT
```

