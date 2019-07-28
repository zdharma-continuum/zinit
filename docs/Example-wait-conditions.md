`wait''` ice needs Zsh >= 5.3.

```zsh
zplugin ice wait'0' # or just: zplugin ice wait
zplugin light zdharma/zconvey
```

 - waits for prompt,
 - 0 seconds after prompt loads given plugin.

***

```zsh
zplugin ice wait'[[ -n ${ZLAST_COMMANDS[(r)cras*]} ]]'
zplugin light zdharma/zplugin-crasis
```

 - `$ZLAST_COMMANDS` is an array build by [**fast-syntax-highlighting**](https://github.com/zdharma/fast-syntax-highlighting), it contains commands currently entered at prompt,
 - `(r)` searches for element that matches given pattern (`cras*`) and returns it,
 - `-n` means: not-empty, so it will be true when users enters "cras",
 - after 1 second or less, Zplugin will detect that `wait''` condition is true, and load the plugin, which provides command *crasis*.

***

```zsh
zplugin ice wait'[[ $PWD = */github* ]]'
zplugin load unixorn/git-extra-commands
```
- Waits until user enters directory with string "github*".
