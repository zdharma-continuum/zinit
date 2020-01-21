```zsh
zinit ice as"program" atclone"rm -f src/auto/config.cache; ./configure" \
    atpull"%atclone" make pick"src/vim"
zinit light vim/vim
```

- `as"program"` – add file selected by `pick''` to `$PATH`, do not source it,
- `atclone"…"` – execute code after downloading,
- `atpull"%atclone"` – execute the same code `atclone''` is given, but after successful update,
- `make` – run `make` after `atclone''` and `atpull''` (note: `make'!'` will execute before them),
- `pick"src/vim"` – set executable flag on `src/vim`, hint that `src/` should be added to `$PATH`.

***

The same but with **installation** (i.e. `make install` is being run) under
`$ZPFX` (`~/.zinit/polaris` by default):

```zsh
zinit ice as"program" atclone"rm -f src/auto/config.cache; \
    ./configure --prefix=$ZPFX" atpull"%atclone" \
    make"all install" pick"$ZPFX/bin/vim"
zinit light vim/vim
```

- `as"program"` – as above,
- `atclone"…"` – as above **plus** pass `--prefix=$ZPFX` to `./configure`, to
  set the installation directory,
- `atpull"%atclone"` – as above,
- `make` – as above, but also run the `install` target,
- `pick"src/vim"` – as above, but for different path (`$ZPFX/bin/vim`).

***

```zsh
zinit ice as"program" make'!' atclone'./direnv hook zsh > zhook.zsh' \
    atpull'%atclone' src"zhook.zsh"
zinit light direnv/direnv
```

- `make'!'` – execute `make` before `atclone''` and before `atpull''` (see `make` above),
- `src"zhook.zsh"` – source file `zhook.zsh`.

In general, Direnv works by hooking up to Zsh. The code that does this is
provided by program `direnv` (built by `make''`). Above `atclone''` puts this
code into file `zhook.zsh`, `src''` sources it. This way `direnv hook zsh` is
executed only on clone and update, and Zsh starts faster.

[]( vim:set ft=markdown tw=80: )
