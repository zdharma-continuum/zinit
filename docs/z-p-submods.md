## Introduction

An annex (i.e. a plugin for zinit) that allows Zplugin to clone additional
submodules when installing a plugin or snippet. The submodules are then 
automatically updated on the `zinit update…` command.

This annex adds the `submods''` ice to Zinit which has the following syntax:

```zsh
submods'{user}/{plugin} -> {output directory}; …'
```

An example command utilizing the z-plugin and its ice:

```zsh
# Load zsh-autosuggestions plugin via Prezto module: autosuggestions
zinit ice svn submods'zsh-users/zsh-autosuggestions -> external'
zinit snippet PZT::modules/autosuggestions
```

![screenshot](img/z-p-submods.png)

## Installation

Simply load as a plugin. The following command will install the annex:

```zsh
zinit light zdharma-continuum/z-p-submods
```

After executing this command you can then use the `submods''` ice. The command
should be placed in `~/.zshrc`.

[]( vim:set ft=markdown tw=80: )
