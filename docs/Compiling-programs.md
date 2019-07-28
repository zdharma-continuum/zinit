```zsh
zplugin ice as"program" atclone"rm -f src/auto/config.cache; ./configure" \
    atpull"%atclone" make pick"src/vim"
zplugin light vim/vim
```

- `as"program"` – add file selected by `pick''` to `$PATH`, do not source it,
- `atclone"..."` – execute code after downloading,
- `atpull"%atclone"` – execute the same code `atclone''` is given, but after successful update,
- `make` – run `make` after `atclone''` and `atpull''`. `make'!'` will execute before them,
- `pick"src/vim"` – set executable flag on `src/vim`, hint that `src/` should be added to `$PATH`.

***

```zsh
zplugin ice as"program" make'!' atclone'./direnv hook zsh > zhook.zsh' \
    atpull'%atclone' src"zhook.zsh"
zplugin light direnv/direnv
```
- `make'!'` – execute `make` before `atclone''` and before `atpull''` (see `make` above),
- `src"zhook.zsh"` – source file `zhook.zsh`.

Direnv is hooked up to Zsh. The code that does this is provided by program `direnv` (build by `make''`). Above `atclone''` puts this code into file `zhook.zsh`, `src''` sources it. This way `direnv hook zsh` is executed only on clone and update, and Zsh starts faster.
