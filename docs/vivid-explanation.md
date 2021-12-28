[vivid][1] is a theme generator that makes it easy to generate the LS_COLORS
environment variable used by the GNU `ls` (as well as [ogham/exa][2] and
[Peltoche/lsd][3]). The LS_COLORS format can also be easily manipulated to style
the zsh completion system.

While vivid isn't nearly as slow as its predecessors (see [LS_COLORS
Explanation][4]), it can still be optimized by caching its output.

Frustratingly, vivid's latest Github release doesn't package all the themes
found in its master branch. Neither are we interested in compiling it from
scratch (or, if you are, see [z-a-rust][5]).

This example is a bit complex, but serves as a good example the power and
flexibility of zinit.

To start, we load several annexes that we'll be using, and configure default
ices:

```zsh
zinit depth'3' light-mode for \
    zdharma-continuum/zinit-annex-bin-gem-node \
    zdharma-continuum/zinit-annex-default-ice \
    NICHOLAS85/z-a-eval \
    ;

zinit default-ice -q depth'3' lucid light-mode
```

Next, we add the `@sharkdp/vivid` plugin twice, but using two different `id-as`
ices:

```zsh
zinit wait as'null' for \
    id-as'vivid-bin' from'gh-r' sbin"**/vivid" \
        @sharkdp/vivid \
    id-as'vivid-themes' \
        @sharkdp/vivid
```

The first plugin (`id-as'vivid-bin'`) uses the `gh-r` `sbin` and `as` ices to
download the latest vivid relase and create a shim in `$ZPFX/bin` to make the
vivid binary available. This pattern has been covered quite well in the wiki.

```zsh
$ tree $ZPFX
$ZPFX
├── bin
│   ├── …
│   ├── vivid
│   └── …
├── etc
├── man
└── share

$ tree $ZINIT[PLUGINS_DIR]/vivid-bin
$ZINIT[PLUGINS_DIR]/vivid-bin
└── vivid-v0.7.0-x86_64-apple-darwin
    ├── …
    ├── share
    │   └── vivid
    │       ├── filetypes.yml
    │       └── themes
    │           ├── ayu.yml
    │           ├── jellybeans.yml
    │           ├── molokai.yml
    │           ├── one-dark.yml
    │           ├── one-light.yml
    │           ├── snazzy.yml
    │           ├── solarized-dark.yml
    │           └── solarized-light.yml
    └── vivid
```

Notice that 0.7.0 doesn't package [nord.yml][6].

So, the second plugin we load (`id-as'vivid-themes'`) as a regular Git
repository, but still with the `as'null'` ice. This will clone the vivid
repository and but not load anything from it. Note, that the name of the
directory is `vivid-themes`, as specified by the `id-as` ice.

```zsh
$ tree $ZINIT[PLUGINS_DIR]/vivid-themes
$ZINIT[PLUGINS_DIR]/vivid-themes/
├── …
└── themes
    ├── ayu.yml
    ├── iceberg-dark.yml
    ├── jellybeans.yml
    ├── lava.yml
    ├── molokai.yml
    ├── nord.yml
    ├── one-dark.yml
    ├── one-light.yml
    ├── snazzy.yml
    ├── solarized-dark.yml
    └── solarized-light.yml
```

Now, we *could* directly use vivid to generate a theme using something odd like
`zdharma-continuum/null`:

```zsh
zinit for \
    eval'echo "export LS_COLORS=\"$(vivid generate $ZINIT[PLUGINS_DIR]/vivid-themes/themes/nord.yml)\""' \
        zdharma-continuum/null
```

But, `zdharma-continuum/null` is a bit of a smell.  A snippet here is more
appropriate:

```zsh
zinit for \
    wait'
        (( $+commands[vivid] )) &&
        [[ -f ${ZINIT[PLUGINS_DIR]}/vivid-themes/themes/nord.yml ]]
    ' \
    is-snippet \
    id-as'vivid-theme-nord' \
    link \
    as'null' \
    nocompile \
    eval'echo "export LS_COLORS=\"$(vivid generate vivid-theme-nord)\""' \
    atload'zstyle ":completion:*" list-colors "${(s.:.)LS_COLORS}"' \
        ${ZINIT[PLUGINS_DIR]}/vivid-themes/themes/nord.yml
```

So, let's break this down step-by-step:

```zsh
1. is-snippet
   id-as'vivid-theme-nord' \
   link
       ${ZINIT[PLUGINS_DIR]}/vivid-themes/themes/nord.yml
```

Here, we declare that we're loading a *local* snippet located *in the repo* that
we previously cloned through the `vivid-themes` plugin.  The `link` ice will
symlink the file, instead of copying it.  The result:

```zsh
$ tree $ZINIT[SNIPPETS_DIR]/vivid-theme-nord
$ZINIT[SNIPPETS_DIR]/vivid-theme-nord
└── vivid-theme-nord -> ../../plugins/vivid-themes/themes/nord.yml
```

```zsh
2. as'null'
   nocompile
```

The snippet we're loading isn't actuall a shell script.  It's a theme file for
vivid.  We use the `as'null'` ice to disable loading; and obviously, we don't
want to compile it.

```zsh
3. eval'echo "export LS_COLORS=\"$(vivid generate vivid-theme-nord)\""'
```

Since we don't want vivid to regenerate the LS_COLOR definition with *each* new
shell, we take advantage of [z-a-eval][7] which will cache the *output* of the
`eval` ice.  The filename of the cache is `evalcache.zsh`.

```zsh
$ tree $ZINIT[SNIPPETS_DIR]/vivid-theme-nord
$ZINIT[SNIPPETS_DIR]/vivid-theme-nord
├── evalcache.zsh
└── vivid-theme-nord -> ../../plugins/vivid-themes/themes/nord.yml
```

The eval command is invoked from within the context of the snippet's directory.
This is where we have symlinked the theme file from the vivid repository
earlier.

Now on each subsequent shell, we simply source `evalcache.zsh` and we get our
LS_COLORS without even needing vivid.

```zsh
4. atload'zstyle ":completion:*" list-colors "${(s.:.)LS_COLORS}"'
```

The `eval` ice doesn't interfere with load order, so we can still take advantage
of the `atload` ice to set our zstyle list-colors using our LS_COLORS values for
zsh's completion system.

```zsh
5. wait'
       (( $+commands[vivid] )) &&
       [[ -f ${ZINIT[PLUGINS_DIR]}/vivid-themes/themes/nord.yml ]]
   '
```

Lastly, we put this entire block inside a `wait` ice to ensure that the other
plugins have had a chance to download the vivid binary and clone the vivid
repository.

Extra Credit:

Technically, we don't need the vivid binary once the evalcache has been
generated.  We can alter our wait condition to be:

```zsh
    wait'
       [[ -f ${ZINIT[SNIPPETS_DIR]}/vivid-theme-nord/evalcache.zsh ]] ||
       (( $+commands[vivid] )) &&
       [[ -f ${ZINIT[PLUGINS_DIR]}/vivid-themes/themes/nord.yml ]]
   '
```

Initially, our first shell will have to wait until the vivid release has been
downloaded and the vivid repository has been cloned.  In subsequent shells,
these conditions should automatically be true.  But, if for some reason, you
decide to unload or delete these plugins, we can still load our evalcache.zsh to
get our LS_COLORS and zstyle.

We can further tweak this by putting `if` guards around our plugins:

```zsh
zinit wait \
    as'null' \
    if'[[ ! -f ${ZINIT[SNIPPETS_DIR]}/vivid-theme-nord/evalcache.zsh ]]' \
    for \
    id-as'vivid-bin' from'gh-r' sbin"**/vivid" \
        @sharkdp/vivid \
    id-as'vivid-themes' \
        @sharkdp/vivid
```

This will cut out these two plugins entirely if the evalcache.zsh exists at the
time of shell startup -- completely eliminating the load times for these two
plugins.

At this point, we're quite over-engineered, but again this demonstrates what a
bit of zinit-fu 💪 can accomplish.

[1]: https://github.com/sharkdp/vivid
[2]: https://github.com/ogham/exa
[3]: https://github.com/Peltoche/lsd
[4]: ../LS_COLORS-explanation
[5]: https://github.com/zdharma-continuum/zinit-annex-rust
[6]: https://github.com/sharkdp/vivid/blob/master/themes/nord.yml
[7]: https://github.com/NICHOLAS85/z-a-eval
