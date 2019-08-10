# Introduction

A z-plugin (i.e. a plugin for the Zplugin – [more information](../Z-PLUGINS/))
that allows Zplugin to clone additional submodules when installing a plugin or
snippet. The submodules are then automatically updated on the `zplugin update
...`
command.

This z-plugin adds `submods''` ice to Zplugin which has the following syntax:

```zsh
submods'{user}/{plugin} -> {output directory}; ...'
```

An example command utilizing the z-plugin and its ice:

```zsh
# Load zsh-autosuggestions plugin via Prezto module: autosuggestions
zplugin ice svn submods'zsh-users/zsh-autosuggestions -> external'
zplugin snippet PZT::modules/autosuggestions
```

![screenshot](img/z-p-submods.png)

# Installation

Simply load as a plugin. The following command will install the z-plugin within
Zplugin:

```zsh
zplugin light zdharma/z-p-submods
```

After executing this command you can then use the `submods''` ice. The command
should be placed in `~/.zshrc`.

[]( vim:set ft=markdown tw=80: )
