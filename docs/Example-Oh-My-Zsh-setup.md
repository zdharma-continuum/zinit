``` zsh
# A.
setopt promptsubst

# B.
zinit ice wait lucid
zinit snippet OMZ::lib/git.zsh

# C.
zinit ice wait atload"unalias grv" lucid
zinit snippet OMZ::plugins/git/git.plugin.zsh

# D.
PS1="READY >" # provide a nice prompt till the theme loads
zinit ice wait'!' lucid
zinit snippet OMZ::themes/dstufft.zsh-theme

# E.
zinit ice wait lucid
zinit snippet OMZ::plugins/colored-man-pages/colored-man-pages.plugin.zsh

# F.
zinit ice wait as"completion" lucid
zinit snippet OMZ::plugins/docker/_docker

# G.
zinit ice wait atinit"zpcompinit" lucid
zinit light zdharma/fast-syntax-highlighting
```

**A** -  Most themes use this option.

**B** -  OMZ themes use this library.

**C** -  Some OMZ themes use this plugin. It provides many aliases – `atload''`
shows how to disable some of them (to use program `rgburke/grv`).

**D** -  Set OMZ theme.

**E** -  Example functional plugin.

**F** -  Load Docker completion.

**G** -  Normal plugin (syntax-highlighting, at the end, like it is suggested by
the plugin's README).

Completions provided by git plugin are catched, but ignored. They can be
executed using function `zpcdreplay` appended after `zpcompinit;` in `atinit''`
of **G**.

Above setup loads everything after prompt, because of preceding `wait` ice. That
is called **Turbo mode**, it shortens Zsh startup time by <u>50%-73%</u>, so
e.g. instead of 200 ms, you'll be getting your shell started up after **50 ms**
(!).

The same setup without Turbo mode (prompt will be initially set like in typical,
normal setup – **you can remove `wait` only from the theme plugin** to have the
same effect while still using Turbo mode for everything remaining):

``` zsh
# A.
setopt promptsubst

# B.
zinit snippet OMZ::lib/git.zsh

# C.
zinit ice atload"unalias grv"
zinit snippet OMZ::plugins/git/git.plugin.zsh

# D.
zinit snippet OMZ::themes/dstufft.zsh-theme

# E.
zinit snippet OMZ::plugins/colored-man-pages/colored-man-pages.plugin.zsh

# F.
zinit ice as"completion"
zinit snippet OMZ::plugins/docker/_docker

# G.
zinit ice atinit"zpcompinit"
zinit light zdharma/fast-syntax-highlighting
```

In general, Turbo mode can be optionally enabled only for a subset of plugins or
for all plugins. It needs Zsh \>= 5.3.

The **Introduction** contains [**more
information**](http://zdharma.org/zinit/wiki/INTRODUCTION/#turbo_mode_zsh_62_53) on Turbo mode.

[]( vim:set ft=markdown tw=80: )
