# Multiple Powerlevel10k Configurations

The author wanted to indicate that he's working on a specific project through
a significant change of the prompt. The [Multiple Prompts](../Multiple-prompts)
setup was however too much – to change a prompt to a completely different one
because of `cd`-ing into a directory felt to be a too big change. However,
thanks to a user's request, a more balanced and quite ideal solution appeared
– to switch [romkatv/powerlevel10k](https://github.com/romkatv/powerlevel10k)
*configurations*.

The example setup is below. There's [Asciinema
recording](https://asciinema.org/a/285760) demonstrating it. The needed steps
include:

1. Generate your configs with `p10k configure`, copying `~/.p10k.zsh` to some
   other file like `~/.p10k_other.zsh`.

2. I suggest updating Powerlevel10k before generating the configs, as recently
   there was a code for hot reloading of the configs added.


```zsh
# Load within zshrc – for the instant prompt
zplugin atload'!source ~/.p10k.zsh' lucid nocd
zplugin load romkatv/powerlevel10k

# Load ~/.p10k_zplugin.zsh when in ~/github/zplugin.git
zplugin id-as'zplugin-prompt' nocd lucid \
    unload'[[ $PWD != */zplugin.git(|/*) ]]' \
    load'![[ $PWD = */zplugin.git(|/*) ]]' \
    atload'!source ~/.p10k_zplugin.zsh; _p9k_precmd' for \
        zdharma/null

# Load ~/.p10k.zsh when in any other directory
zplugin id-as'normal-prompt' nocd lucid \
    unload'[[ $PWD = */zplugin.git(|/*) ]]' \
    load'![[ $PWD != */zplugin.git(|/*) ]]' \
    atload'!source ~/.p10k.zsh; _p9k_precmd' for \
        zdharma/null
```

For explanation on the used ice mods, see [Multiple Prompts](../Multiple-prompts).

[]( vim:set ft=markdown tw=80 fo+=a1n autoindent: )
