# Manage (remap) bindkeys with `bindmap''`

## Introduction

Sometimes plugins call `bindkey` to assign keyboard shortucts. This can cause
problems, because multiple plugins can bind the same keys. Also, the user might
want a different binding(s), which will require a complicated, additional
`bindkey` commands in `.zshrc`.

Zinit provides a solution to this problem – the ability to remap the bindkeys
with a short ice-modifier specification with the `bindmap''` ice.

## Examples

```zsh
# Map Ctrl-G instead of Ctrl-R for the history searcher.
zinit bindmap'^R -> ^G' for zdharma-continuum/history-search-multi-word

# Map Ctrl-Shift-Left and …-Right used by URxvt instead of the Xterms' ones.
#
# Load with the bindkey-tracking ↔ with light-loading for anything else.
#
# Could also separate the bindmaps with a semicolon, i.e.:
# bindmap'"\\e[1\;6D" -> \\e[1\;5D ; "\\e[1\;6C" -> ^[[1\;5C' \
zinit wait light-mode trackbinds bindmap'"\\e[1\;6D" -> \\e[1\;5D"' \
    bindmap'"\\e[1\;6C" -> ^[[1\;5C' pick'dircycle.zsh' for \
        michaelxmcbride/zsh-dircycle

# Map space to regular space and Ctrl-Space to the `globalias' widget, which
# expands the alias entered on the left (provided by OMZ globalias plugin).
zinit bindmap='!" " -> magic-space; !"^ " -> globalias' nocompletions \
    depth=1 pick=plugins/globalias/globalias.plugin.zsh for \
        ohmyzsh/ohmyzsh
```

## Explanation

As it can be seen, the `bindmap''` ice has two modes of operation: normal and
exclamation-mark (`bindmap'!…'`). In the first mode, the remapping is beind done
from-key to-key, i.e.: `bindmap'fromkey -> to-key'`. In this mode, the given key
is being changed to the second given key in the `bindkey` command that's being
actually issued when loading the plugin.

In the second mode, the remapping is being done from-key to-widget, i.e.:
`bindmap'!from-key -> to-widget'`. In this mode, the given key is being mapped
to the given widget instead of the widget specified in the `bindkey` command,
i.e.: instead of:

```zsh
bindkey "^ " magic-space
bindkey " " globalias
```

the actual call that'll be done will be:

```zsh
bindkey "^ " globalias
bindkey " " magic-space
```

(for the `bindmap='!" " -> magic-space; !"^ " -> globalias'` ice).

## Using The `UPAR`, Etc. Shorthands

There are four special values that can be used on the left side of the bind-map:
`UPAR`, `DOWNAR`, `LEFTAR`, `RIGHTAR`. They'll match up arrow, down arrow, etc.
So that it's possible to do:

```zsh
zinit bindmap='LEFTAR -> ^F; RIGHTAR -> ^G' …
```

The benefits of using the `UPAR`, … shorthands is that they cover multiple
possible cursor-key codes for each of the cursor key, so that they'll work
regardless of the terminal being used.

## Using `bindmap''` In Light Mode

When the investigation mode is on – i.e.: when the full loading mode is being
used (default in the `for` syntax and when `zinit load …` is used) – then the
`bindmap''` ice works normally. In the non-investigation, i.e.: the light mode
– activated when `zinit light …` or the `light-mode` ice is being used – the
`bindmap''` is unavailable, unless the `trackbinds` ice is specified, i.e.:

```zsh
# With use of the light-mode ice and the for-syntax:
zinit light-mode trackbinds bindmap'^R -> ^G' for zdharma-continuum/history-search-multi-word

# With use of the classic syntax:
zinit trackbinds bindmap'^R -> ^G' for zdharma-continuum/history-search-multi-word
zinit light zdharma-continuum/history-search-multi-word
```
[]( vim:set ft=markdown tw=80 fo+=a1n autoindent: )
