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
 - Screencast that presents the feature:
    [![screencast](https://asciinema.org/a/149725.svg)](https://asciinema.org/a/149725)

***

```zsh
zplugin ice wait'[[ $PWD = */github || $PWD = */github/* ]]'
zplugin load unixorn/git-extra-commands
```

- waits until user enters a `github` directory.

***

Turbo mode also support a suffix – the letter `a`, `b` or `c`. The meaning is
illustrated by the following example:

```
zplugin ice wait"0b" as"command" pick"wd.sh" atinit"echo Firing 1" lucid
zplugin light mfaerevaag/wd
zplugin ice wait"0a" as"command" pick"wd.sh" atinit"echo Firing 2" lucid
zplugin light mfaerevaag/wd

# The output
Firing 2
Firing 1
```

As it can be seen, the second plugin has been loaded first. That's because there
are now three sub-slots (the `a`, `b` and `c`) in which the plugin/snippet
loadings can be put into. Plugins from the same time-slot with suffix `a` will
be loaded before plugins with suffix `b`, etc.

In other words, instead of `wait'1'` you can enter `wait'1a'`, `wait'1b'` and
`wait'1c'` – to this way **impose order** on the loadings **regardless of the
order of `zplugin` commands**. 



[]( vim:set ft=markdown tw=80: )
