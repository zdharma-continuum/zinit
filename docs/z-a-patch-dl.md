## Introduction

A Zsh-Zplugin extension (i.e. an
[annex](http://zdharma.org/zplugin/wiki/Annexes/)) that downloads files and
applies patches. It adds two ice modifiers:

```zsh
zplugin ice dl'{URL} [-> {optional-output-file-name}]; …' …
```

and

```zsh
zplugin ice patch'{file-name-with-the-patch-to-apply}; …' …
```

The annex (i.e. Zplugin extension) will download the given `{URL}` under the
path `{optional-output-file-name}` (if no file name given, then it is taken from
last segment of the URL) in case of the `dl''` ice-mod, and apply a patch given
by the `{file-name-with-the-patch-to-apply}` in case of the `patch''` ice-mod.

You can use this functionality to download and apply patches. For example, to
install `fbterm`, two patches are being needed, one to fix the operation, the
other one to fix the build:

```zsn
zplugin ice \
    as"command" pick"$ZPFX/bin/fbterm" \
    dl"https://bugs.archlinux.org/task/46860?getfile=13513 -> ins.patch" \
    dl"https://aur.archlinux.org/cgit/aur.git/plain/0001-Fix-build-with-gcc-6.patch?h=fbterm-git" \
    patch"ins.patch; 0001-Fix-build-with-gcc-6.patch" \
    atclone"./configure --prefix=$ZPFX" \
    atpull"%atclone" \
    make"install" reset
zplugin load izmntuk/fbterm
```

This command will result in:

![fbterm
example](https://raw.githubusercontent.com/zplugin/z-a-patch-dl/master/images/fbterm-ex.png)

## Installation

Simply load like a plugin, i.e. the following will add the annex to Zplugin:

```zsh
zplugin light zplugin/z-a-patch-dl
```

After executing this command you can then use the `dl''` and `patch''` ice-mods.

<!-- vim:set ft=markdown tw=80 et sw=4 sts=4: -->
