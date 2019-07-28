The project [**direnv/direnv**](https://github.com/direnv/direnv) registers itself in Zshell to modify environment on directory change. This registration is most often done by `eval "$(direnv hook zsh)"` added to zshrc.

Drawback of this standard procedure is that `direnv` binary is ran on every shell startup and significantly slows it down. Zplugin allows to solve this in following way:

```zsh
zplugin ice as"program" make'!' atclone'./direnv hook zsh > zhook.zsh' \
    atpull'%atclone' pick"direnv" src"zhook.zsh"
zplugin light direnv/direnv
```

 - `make'!'` – compile `direnv` (it's written in Go lang); the exclamation mark means: run the `make` first, before `atclone` and `atpull` hooks,
 - `atclone'...'` – initially (right after installing the plugin) generate the registration code and save it to `zhook.zsh` (instead of passing to `eval`),
 - `atpull'%atclone'` – regenerate the registration code also on update (`atclone''` runs on *installation* while `atpull` runs on *update* of the plugin),
 - `src"zhook.zsh"` – load (`source`) the generated registration code,
 - `pick"direnv"` – ensure `+x` permission on the binary,
 - `as"program"` – the plugin is a program, there's no main file to source.

This way registration code is generated once every installation and update, to then be simply sourced without running `direnv`.

***

The project is also available as binary Github release. This distribution can be installed by:

```zsh
zplugin ice from"gh-r" as"program" mv"direnv* -> direnv" \
    './direnv hook zsh > zhook.zsh' atpull'%atclone' pick"direnv"
zplugin light direnv/direnv
```

 - `from"gh-r"` – install from Github **releases**,
 - `mv"..."` – after installation, rename `direnv.linux-386` or similar file to `direnv`,
 - `atclone'...'`, `atpull'...'` – as in previous example,
 - `pick"direnv"` – as in previous example,
 - `as"program"` – as in previous example.
