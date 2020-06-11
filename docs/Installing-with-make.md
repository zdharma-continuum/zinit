```zsh
zinit ice as"program" pick"$ZPFX/bin/git-*" make"PREFIX=$ZPFX"
zinit light tj/git-extras
```

 - `Makefile` of this project has only one needed target – `install`, which is called by default,
 - it also does building of the scripts that it installs, so it does 2 tasks,
 - for `Makefile` with 2 targets, one could use `make"all install PREFIX=…"`,
 - `pick'…'` will `chmod +x` all matching files and add `$ZPFX/bin/` to `$PATH`,
 - `$ZPFX` is provided by Zinit, it is `~/.zinit/polaris` by default, can be also customized.

[]( vim:set ft=markdown tw=80: )
