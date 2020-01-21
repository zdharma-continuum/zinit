# Example Minimal Setup

```zsh
zinit ice wait blockf atpull'zinit creinstall -q .'
zinit light zsh-users/zsh-completions

zinit ice wait atinit"zpcompinit; zpcdreplay"
zinit light zdharma/fast-syntax-highlighting

zinit ice wait atload"_zsh_autosuggest_start"
zinit light zsh-users/zsh-autosuggestions
```

 - `light` – load the plugin in `light` mode, in which the tracking of plugin
   (i.e. activity report gathering, accessible via the `zinit report
   {plugin-spec}` subcommand) is being disabled; note that for Turbo mode, the
   performance gains are actually `0`, so in this mode you can load all plugins
   with the tracking, i.e. by using `zinit ice wait'0'; zinit load
   {plugin-spec}` commands,
 - `wait` – load 0 seconds (about 5 ms exactly) after prompt,
 - `atpull''` – execute after updating the plugin – the command in the ice will
   install any new completions,
 - `atinit''` – execute code before loading plugin,
 - `atload''` – execute code after loading plugin,
 - `zpcompinit` – equals to `autoload compinit; compinit`,
 - `zpcdreplay` – execute `compdef …` calls that plugins did – they were
   recorded, so that `compinit` can be called later (it provides the `compdef`
   function, so it must be ran before issuing `compdef`s),
 - syntax-highlighting plugins (like
   [**fast-syntax-highlighting**](https://github.com/zdharma/fast-syntax-highlighting)
   or
   [**zsh-syntax-highlighting**](https://github.com/zsh-users/zsh-syntax-highlighting))
   expect to be loaded last, even after the completion initialization (i.e.
   `compinit` function), hence the `atinit''`, which will load `compinit` right
   before the plugin,
 - however the true last-loaded plugin is the
   [**zsh-users/zsh-autosuggestions**](https://github.com/zsh-users/zsh-autosuggestions),
   because it runs a function in an `precmd` hook, i.e. right before first
   prompt,
 - the `atinit` of the plugin runs also `zpcdreplay` (i.e.
   "*zinit-compdef-replay*"), because after `compinit` is loaded, the
   `compdef` function becomes available, and one can re-run the all earlier
   automatically-caught`compdef` calls, loosing nothing from the original
   behavior,
 - add `lucid` ice-mod to silence the under-prompt messages.

The same setup but without using Turbo mode (i.e. no `wait''` ice):

```zsh
zinit ice blockf atpull'zinit creinstall -q .'
zinit light zsh-users/zsh-completions

autoload compinit
compinit

zinit light zdharma/fast-syntax-highlighting

zinit light zsh-users/zsh-autosuggestions
```

[]( vim:set ft=markdown tw=80: )
