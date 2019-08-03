```zsh
# Load when MYPROMPT == 1
zplugin ice load'![[ $MYPROMPT = 1 ]]' unload'![[ $MYPROMPT != 1 ]]'
zplugin load halfo/lambda-mod-zsh-theme

# Load when MYPROMPT == 2
zplugin ice load'![[ $MYPROMPT = 2 ]]' unload'![[ $MYPROMPT != 2 ]]' \
    pick"/dev/null" multisrc"{async,pure}.zsh"
zplugin load sindresorhus/pure

# Load when MYPROMPT == 3
zplugin ice load'![[ $MYPROMPT = 3 ]]' unload'![[ $MYPROMPT != 3 ]]'
zplugin load geometry-zsh/geometry
```

 - `load''` – condition that when fulfilled will cause plugin to be loaded,
 - `unload''` – as above, but will unload plugin,
 - note that plugins are loaded with <code>zplugin load &#8203;</code>, not `zplugin light`, to track what plugin does, to be able to unload it,
 - conditions are checked every second,
 - you can use conditions like `![[ $PWD == *github* ]]` to change prompt after changing directory to `*github*`,
 - the exclamation mark `![[ ... ]]` causes prompt to be reset after loading or unloading the plugin,
 - `pick'/dev/null'` – disable sourcing of the default-found file
 - `multisrc''` – source multiple files

[]( vim:set ft=markdown tw=80: )
