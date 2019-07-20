``` zsh
# A.
setopt promptsubst

# B.
zplugin ice wait"0" lucid
zplugin snippet OMZ::lib/git.zsh

# C.
zplugin ice wait"0" atload"unalias grv" lucid
zplugin snippet OMZ::plugins/git/git.plugin.zsh

# D.
zplugin ice wait"0" lucid
zplugin snippet OMZ::plugins/colored-man-pages/colored-man-pages.plugin.zsh

# E.
zplugin wait"0" lucid
zplugin snippet OMZ::themes/dstufft.zsh-theme

# F.
zplugin ice wait"0" as"completion" lucid
zplugin snippet OMZ::plugins/docker/_docker

# G.
zplugin ice wait"0" atinit"zpcompinit" lucid
zplugin light zdharma/fast-syntax-highlighting
```

1.  Most themes use this option.

2.  OMZ themes use this library.

3.  Some OMZ themes use this plugin. It provides many aliases –
    `atload''` shows how to disable some of them (to use program
    `rgburke/grv`).

4.  Example functional plugin.

5.  Set OMZ theme.

6.  Load Docker completion

7.  Normal plugin (syntax-highlighting, at the end, like it is
    suggested).

Completions provided by git plugin are catched, but ignored. They can be
executed using function `zpcdreplay` appended after `zpcompinit;` in
`atinit''` of G.

Above setup loads everything after prompt, because of preceding
`wait"0"` ice. That is called turbo-mode, it shortens Zsh startup time
by 39%-50%. The same setup without turbo mode (prompt will be initially
set):

``` zsh
setopt promptsubst
zplugin snippet OMZ::lib/git.zsh
zplugin ice atload"unalias grv"
zplugin snippet OMZ::plugins/git/git.plugin.zsh
zplugin snippet OMZ::plugins/colored-man-pages/colored-man-pages.plugin.zsh
zplugin snippet OMZ::themes/dstufft.zsh-theme
zplugin ice as"completion"
zplugin snippet OMZ::plugins/docker/_docker
zplugin ice atinit"zpcompinit"
zplugin light zdharma/fast-syntax-highlighting
```

Turbo mode can be optionally enabled only for a subset of plugins or for
all plugins. It needs Zsh \>= 5.3.
