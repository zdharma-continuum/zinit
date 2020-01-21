# The For-Syntax

## Introduction

The [Introduction](../INTRODUCTION/) covers the classic Zinit invocation
syntax, which is:

```zsh
zinit ice …
zinit load … # or zinit light, zinit snippet
```

It is a fundamental Zinit syntax. However, a more concise, optimized syntax,
called *for-syntax*, is also available. It is best presented by a real-world
example:


```zsh
zinit as"null" wait"3" lucid for \
    sbin  Fakerr/git-recall \
    sbin  paulirish/git-open \
    sbin  paulirish/git-recent \
    sbin  davidosomething/git-my \
    make"PREFIX=$ZPFX install"  iwata/git-now \
    make"PREFIX=$ZPFX"          tj/git-extras
```

Above single command installs 6 plugins (Git extension-packages), with the base
ices `as"null" wait"3" lucid` that are common to all of the plugins and
6 plugin-specific add-on ices.

## A Few Remarks

* The syntax automatically detects if the object is a snippet or a plugin, by
  checking if the object is an URL, i.e.: if it starts with `http*://` or
  `OMZ::`, etc.
* To load a local-file snippet (which will be treaten as a local-directory
  plugin by default) use the `is-snippet` ice,
* To load a plugin in `light` mode use the `light-mode` ice.
* If the plugin name collides with an ice name, precede the plugin name with
  `@`, e.g.: `@sharkdp/fd` (collides with the `sh` ice, Zinit will take the
  plugin name as `sh"arkdp/fd"`), see the next section for an example.

## Examples

Load a few useful binary (i.e.: binary packages from the GitHub Releases) utils:

```zsh
zinit as"null" wait"2" lucid from"gh-r" for \
    mv"exa* -> exa" sbin       ogham/exa \
    mv"fd* -> fd" sbin"fd/fd"  @sharkdp/fd \
    sbin"fzf"  junegunn/fzf-bin
```

Note: `sbin''` is an ice added by the
[z-a-bin-gem-node](https://github.com/zinit/z-a-bin-gem-node) annex, it
provides the command to the command line without altering `$PATH`. If the name
of the command is the same as the name of the plugin, the ice contents can be
skipped.

Turbo load some plugins, without any plugin-specific ices:

```zsh
zinit wait lucid for \
            hlissner/zsh-autopair \
            urbainvaes/fzf-marks
```

Load two Oh My Zsh files as snippets, in Turbo:

```zsh
zinit wait lucid for \
                        OMZ::lib/git.zsh \
    atload"unalias grv" OMZ::plugins/git/git.plugin.zsh
```

[]( vim:set ft=markdown tw=80 fo+=a1n autoindent: )
