!!!note
    **Turbo mode, i.e. the `wait` ice that implements it needs Zsh >= 5.3.**

```zsh
zplugin ice wait'0' # or just: zplugin ice wait
zplugin light wfxr/forgit
```

 - waits for prompt,
 - instantly ("0" seconds) after prompt loads given plugin.

***

```zsh
zplugin ice wait'[[ -n ${ZLAST_COMMANDS[(r)cras*]} ]]'
zplugin light zdharma/zplugin-crasis
```

 - `$ZLAST_COMMANDS` is an array build by [**fast-syntax-highlighting**](https://github.com/zdharma/fast-syntax-highlighting), it contains commands currently entered at prompt,
 - `(r)` searches for element that matches given pattern (`cras*`) and returns it,
 - `-n` means: not-empty, so it will be true when users enters "cras",
 - after 1 second or less, Zplugin will detect that `wait''` condition is true, and load the plugin, which provides command *crasis*,
 - [![screencast](https://asciinema.org/a/149725.svg)](https://asciinema.org/a/149725) that presents the feature.

***

```zsh
zplugin ice wait'[[ $PWD = */github || $PWD = */github/* ]]'
zplugin load unixorn/git-extra-commands
```
- waits until user enters a `github` directory.
