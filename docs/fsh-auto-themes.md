# fsh-auto-themes

## Introduction

In-short, `fsh-auto-themes` is a plugin that implements Zshell per-directory
themes for
[zdharma/fast-syntax-highlighting](https://github.com/zdharma-continuum/fast-syntax-highlighting),
i.e.: for a plugin that applies colors to the commands you type in the shell,
(see a [screenshot](http://zdharma.org/assets/x-paragon.png)). With
`fsh-auto-themes` you'll be able to switch the FSH theme at the moment of
entering a particular directory.

## Operation

This plugin activates after changing current directory in the shell session.  It
then searches for `.fsh-theme` file in that new directory or in any upper
directory. Example `.fsh-theme` file contents:

```
q-jmnemonic
```

1. **First line**: a name of a theme or a path to a theme. The path can use the
shorthands supported by `fast-theme`, e.g.: `XDG:x-paragon` will point to the
file `~/.config/fsh/x-paragon.ini` (unless the `$XDG_CONFIG_HOME` is being set
to different directory than `~/.config`). See `fast-theme --help` for more
information and other shorthands.

2. **Second line**: a name or a path of an overlay (an overlay is a theme-like
file that overwrites every theme's settings; you can use it to impose your own
customizations over any theme).

The plugin will switch current theme to the one in the file and also apply the
overlay found in the file. One of the lines can be empty.

If `.fsh-theme` will not be found, the default theme (the one currently set with
the `fast-theme` tool) will be restored.

## Example

Example operation of the plugin:

![Asciinema
Video](https://raw.githubusercontent.com/zdharma/fast-syntax-highlighting/master/images/203654.gif)

## Installation

Example `zdharma/zinit` invocation:

```zsh
zinit ice from"<USERNAME>@github.com"
zinit light psprint/fsh-auto-themes
```

With [Turbo
Mode](http://zdharma.org/zinit/wiki/INTRODUCTION/#turbo_mode_zsh_62_53):

```zsh
zinit ice wait'1' lucid from"<USERNAME>@github.com"
zinit light psprint/fsh-auto-themes
```

[]( vim:set ft=markdown tw=80 fo+=a2n autoindent: )
