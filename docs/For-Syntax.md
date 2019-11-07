# The For-Syntax

## Introduction

The [Introduction](../INTRODUCTION/) covers the classic Zplugin invocation
syntax, which is:

```zsh
zplugin ice …
zplugin load … # or zplugin light, zplugin snippet
```

It is a fundamental Zplugin syntax. However, a more concise, optimized syntax,
called *for-syntax*, is also available. It is best presented by a real-world
example:


```zsh
zplugin as"null" wait"3" lucid for \
    sbin"git-recall"   Fakerr/git-recall \
    sbin"git-open"     paulirish/git-open \
    sbin"git-recent"   paulirish/git-recent \
    sbin"git-my"       davidosomething/git-my \
    make"PREFIX=$ZPFX install"   iwata/git-now \
    make"PREFIX=$ZPFX"           tj/git-extras
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
  `@`, e.g.: `@sharkdp/fd` (collides with the `sh` ice, Zplugin will take the
  plugin name as `sh"arkdp/fd"`), see the next section for an example.

## Examples

Load a few useful binary (i.e.: binary packages from the GitHub Releases) utils:

```zsh
zplugin as"null" wait"2" lucid from"gh-r" for \
    mv"exa* -> exa" sbin"exa"  ogham/exa \
    mv"fd* -> fd" sbin"fd/fd"  @sharkdp/fd \
    sbin"fzf"  junegunn/fzf-bin
```

Note: `sbin''` is an ice added by the
[z-a-bin-gem-node](https://github.com/zplugin/z-a-bin-gem-node) annex, it
provides the command to the command line without altering `$PATH`.

Turbo load some plugins, without any plugin-specific ices:

```zsh
zplugin wait lucid for \
            hlissner/zsh-autopair \
            urbainvaes/fzf-marks
```

Load two Oh My Zsh files as snippets, in Turbo:

```zsh
zplugin wait lucid for \
                        OMZ::lib/git.zsh \
    atload"unalias grv" OMZ::plugins/git/git.plugin.zsh
```

[]( vim:set ft=markdown tw=80 fo+=a1n autoindent: )
