```zsh
zplugin ice atinit'zmodload zsh/zprof' \
    atload'zprof | head; zmodload -u zsh/zprof'
zplugin light zdharma/fast-syntax-highlighting
```

 - `atinit''` loads `zsh/zprof` module before loading plugin – this starts profiling,
 - `atload''` works after loading the plugin – shows profiling results (`zprof | head`), unloads `zsh/zprof`,
 - the `light` loads without reporting enabled, so less Zplugin code is being run.

[]( vim:set ft=markdown tw=80: )
