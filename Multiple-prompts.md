```zsh
# Load when MYPROMPT == 1
zplugin ice load'![[ $MYPROMPT = 1 ]]' unload'![[ $MYPROMPT != 1 ]]'
zplugin load halfo/lambda-mod-zsh-theme

# Load when MYPROMPT == 2
zplugin ice load'![[ $MYPROMPT = 2 ]]' unload'![[ $MYPROMPT != 2 ]]'
zplugin load ergenekonyigit/lambda-gitster

# Load when MYPROMPT == 3
zplugin ice load'![[ $MYPROMPT = 3 ]]' unload'![[ $MYPROMPT != 3 ]]'
zplugin load geometry-zsh/geometry

# Load Oh My Zsh dependency for lambda-gitster prompt
zplugin ice wait"0"
zplugin snippet OMZ::lib/git.zsh
```

 - `load''` – condition that when fulfilled will cause plugin to be loaded,
 - `unload''` – as above, but will unload plugin,
 - note that plugins are loaded with `zplugin load`, not `zplugin light`, to track what plugin does, to be able to unload it,
 - conditions are checked every second,
 - you can use conditions like `![[ $PWD == *github* ]]` to change prompt after changing directory to `*github*`,
 - the exclamation mark `![[ ... ]]` causes prompt to be reset after loading or unloading the plugin,
 - `wait"0"` – load snippet 0 seconds after prompt (actually after c.a. 100 milliseconds).
