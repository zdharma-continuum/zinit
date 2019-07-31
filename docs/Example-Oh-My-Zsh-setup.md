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

A -  Most themes use this option.

B -  OMZ themes use this library.

C -  Some OMZ themes use this plugin. It provides many aliases –
    `atload''` shows how to disable some of them (to use program
    `rgburke/grv`).

D -  Example functional plugin.

E -  Set OMZ theme.

F -  Load Docker completion.

G -  Normal plugin (syntax-highlighting, at the end, like it is
    suggested).

Completions provided by git plugin are catched, but ignored. They can be
executed using function `zpcdreplay` appended after `zpcompinit;` in
`atinit''` of G.

Above setup loads everything after prompt, because of preceding
`wait"0"` ice. That is called Turbo-mode, it shortens Zsh startup time
by 39%-50%. The same setup without Turbo mode (prompt will be initially
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
