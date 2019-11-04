```zsh
# Load when MYPROMPT == 1
zplugin ice load'![[ $MYPROMPT = 1 ]]' unload'![[ $MYPROMPT != 1 ]]' lucid
zplugin load halfo/lambda-mod-zsh-theme

# Load when MYPROMPT == 2
zplugin ice load'![[ $MYPROMPT = 2 ]]' unload'![[ $MYPROMPT != 2 ]]' \
    pick"/dev/null" multisrc"{async,pure}.zsh" \
    atload'!prompt_pure_precmd' lucid nocd
zplugin load sindresorhus/pure

# Load when MYPROMPT == 3
zplugin ice load'![[ $MYPROMPT = 3 ]]' unload'![[ $MYPROMPT != 3 ]]' \
          atload'!geometry::prompt' lucid nocd
zplugin load geometry-zsh/geometry
```

 - `load''` – condition that when fulfilled will cause plugin to be loaded,
 - `unload''` – as above, but will unload plugin,
 - note that plugins are loaded with <code>zplugin load </code>, not `zplugin
   light`, to track what plugin does, to be able to unload it,
 - `atload'!…'` – run the `precmd` hooks to make the prompts fully initialized
   when loaded in the middle of the prompt (`precmd` hooks are being normally
   run before each **new** prompt); exclamation mark causes the effects of the
   functions to be tracked, to allow better unloading,
 - conditions are checked every second,
 - you can use conditions like `![[ $PWD == *github* ]]` to change prompt after
   changing directory to `*github*`,
 - the exclamation mark `![[ … ]]` causes prompt to be reset after loading or
   unloading the plugin,
 - `pick'/dev/null'` – disable sourcing of the default-found file,
 - `multisrc''` – source multiple files,
 - `lucid` – don't show the under-prompt message that says e.g.: `Loaded
   geometry-zsh/geometry`,
 - `nocd` – don't cd into the plugin's directory when executing the `atload''`
   ice – it could make the path that's displayed by the theme to point to that
   directory.

[]( vim:set ft=markdown tw=80: )
