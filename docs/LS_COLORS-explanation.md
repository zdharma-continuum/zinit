A plugin [**trapd00r/LS_COLORS**](https://github.com/trapd00r/LS_COLORS) provides a file with color definitions for GNU `ls` command (and also for [**ogham/exa**](https://github.com/ogham/exa)). Typically one does `eval $( dircolors -b $HOME/LS_COLORS )` to process this file and set environment for `ls`. However this means `dircolors` is ran every shell startup.

This costs much time, because a fork has to be done and the program (i.e. `dircolors`) binary needs to be loaded and executed, and because `dircolors` loads the colors' definitions and processes them. Following Zplugin invocation solves this problem:

```zsh
zplugin ice atclone"dircolors -b LS_COLORS > clrs.zsh" \
    atpull'%atclone' pick"clrs.zsh" nocompile'!'
zplugin light trapd00r/LS_COLORS
```

- `atclone"..."` – generate shell script, but instead of passing it to `eval`, save it to file,
- `atpull'%atclone'` – do the same at any update of plugin (the `atclone` is being ran on the *installation* while the `atpull` hook is being ran on an *update* of the [**trapd00r/LS_COLORS**](https://github.com/trapd00r/LS_COLORS) plugin); the `%atclone` is just a special string that denotes that the `atclone''` hook should be copied onto the `atpull''` hook,
- `pick"clrs.zsh"` – source file `clrs.zsh`, the one that is generated,
- `nocompile'!'` – invokes compilation **after** the `atclone''` ice-mod (the exclamation mark causes this).

This way, except for the plugin installation and update, `dircolors` isn't ran, just normal sourcing is done. The every-day sourced file (i.e. `c.zsh`) is even being compiled to speed up the loading.
