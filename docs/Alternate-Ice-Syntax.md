# Alternate Ice Syntax

## The Standard Syntax

The normal way of specifying ices and their values is by concatenating the ice
name and its value quoted, i.e.:

```zsh
zinit wait"1" from"gh-r" atload"print Hello World"
zinit load …
```

(note that there's no `ice` subcommand - that is currently being fully allowed)

## The Alternative Syntaxes

However, Zinit supports also other syntaxes: the equal (`=`) syntax:

```zsh
zinit wait=1 from=gh-r atload="print Hello World"
zinit load …
```

the colon (`:`) syntax:

```zsh
zinit wait:1 from:gh-r atload:"print Hello World"
zinit load …
```

and also – with conjunction with all of the above – the GNU syntax:

```zsh
zinit --wait=1 --from=gh-r --atload="print Hello World"
zinit load …
```

## Summary

It's up to the user which syntax to choose. The original motivation behind the
standard syntax was: to utilize the syntax highlighting of editors like Vim –
and have the strings following ice names colorized with a distinct color and
this way separated from them. However, with the
[zdharma-continuum/zinit-vim-syntax](https://github.com/zdharma-continuum/zinit-vim-syntax)
syntax definition this motivation can be superseded with the Zinit-specific
highlighting, at least for Vim.  NOTE: the Vim syntax doesn't yet support the
alternate syntaxes, it will soon (PR welcomed).

[]( vim:set ft=markdown tw=80 fo+=a2n autoindent: )
