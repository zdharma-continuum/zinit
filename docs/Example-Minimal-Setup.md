# Example Minimal Setup

```zsh
zplugin ice wait"0" blockf
zplugin light zsh-users/zsh-completions

zplugin ice wait"0" atload"_zsh_autosuggest_start"
zplugin light zsh-users/zsh-autosuggestions

zplugin ice wait"0" atinit"zpcompinit; zpcdreplay"
zplugin light zdharma/fast-syntax-highlighting
```

 - `light` – load the plugin in `light` mode, in which the tracking of plugin (i.e. activity report gathering, accessible via the `zplugin report {plugin-spec}` subcommand) is being disabled; note that for TurboMode, the performance gains are actually `0`, so in this mode you can load all plugins with the tracking, i.e. by using `zplugin ice wait'0'; zplugin load {plugin-spec}` commands,
 - `wait"0"` – load 0 seconds (about 110 ms exactly) after prompt,
 - `atinit''` – execute code before loading plugin,
 - `atload''` – execute code after loading plugin,
 - `zpcompinit` – equals to `autoload compinit; compinit`,
 - `zpcdreplay` – execute `compdef ...` calls that plugins did – they were recorded, so that `compinit` can be called later (it provides the `compdef` function, so it must be ran before issuing `compdef`s),
 - syntax-highlighting plugins (like [**fast-syntax-highlighting**](https://github.com/zdharma/fast-syntax-highlighting) or [**zsh-syntax-highlighting**](https://github.com/zsh-users/zsh-syntax-highlighting)) expect to be loaded last, even after the completion initialization (i.e. `compinit` function), hence the `atinit''`, which will load `compinit` right before the plugin,
 - the `atinit` of the plugin runs also `zcdreplay` (i.e. "*zplugin-compdef-replay*"), because after `compinit` is loaded, the `compdef` function becomes available, and one can re-run the all earlier automatically-caught`compdef` calls,
 - add `lucid` ice-mod to silence the under-prompt messages.

The same setup but without using Turbo-mode (i.e. no `wait''` ice):

```zsh
zplugin ice blockf; zplugin light zsh-users/zsh-completions
zplugin light zsh-users/zsh-autosuggestions

autoload compinit
compinit

zplugin light zdharma/fast-syntax-highlighting
```

 - `light` – as above

[]( vim:set ft=markdown tw=80: )
