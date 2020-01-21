# The `wrap-track` Ice

The `wrap-track` ice-mod allows to extend the tracking (i.e. gathering of report
and unload data) of a plugin beyond the moment of sourcing it's main file(s). It
works by wrapping the given functions with a tracking-enabling and disabling
snippet of code. This is useful especially with prompts, as they very often do
their initialization in the first call to their `precmd` [**hook**
](http://zsh.sourceforge.net/Doc/Release/Functions.html#Hook-Functions)
function. For example,
[**romkatv/powerlevel10k**](https://github.com/romkatv/powerlevel10k) works this
way.

The ice takes a list of function names, with the elements separated by `;`:

```zsh
zinit ice wrap-track"func1;func2;…" …
…
```

## Example

Therefore, to e.g. load and unload the example powerlevel10k prompt in the
fashion of [**Multiple prompts**](../Multiple-prompts/) article, the `precmd`
function of the plugin – called `_p9k_precmd` (to get the name of the function
do `echo $precmd_functions` after loading a theme) – should be passed to
`wrap-track''` ice, like so:

```zsh
# Load when MYPROMPT == 4
zinit ice load'![[ $MYPROMPT = 4 ]]' unload'![[ $MYPROMPT != 4 ]]' \
            atload'source ~/.p10k.zsh; _p9k_precmd' wrap-track'_p9k_precmd'
zinit load romkatv/powerlevel10k
```

This way the actions done during the first call to `_p9k_precmd()` will be
normally recorded, which can be viewed in the report of the
[**romkatv/powerlevel10k**](https://github.com/romkatv/powerlevel10k) theme:

<pre>
<code>~ zplg report romkatv/powerlevel10k:
Report for romkatv/powerlevel10k plugin
<span class="hljs-blue">---------------------------------------</span>
Source powerlevel10k.zsh-theme (reporting enabled)
Autoload is-at-least with options -U -z

(…)

Note: === Starting to track function: _p9k_precmd ===
Zle -N p9k-orig-zle-line-finish _zsh_highlight_widget_zle-line-finish
Note: a new widget created via zle -N: p9k-orig-zle-line-finish
Zle -N -- zle-line-finish _p9k_wrapper__p9k_zle_line_finish
Autoload vcs_info with options -U -z
Zstyle :vcs_info:* check-for-changes true

(…)

Zstyle :vcs_info:* get-revision false
Autoload add-zsh-hook with options -U -z
Zle -F 22 _gitstatus_process_response_POWERLEVEL9K
Autoload _gitstatus_cleanup_15877_0_16212
Zle -N -- zle-line-pre-redraw _p9k_wrapper__p9k_zle_line_pre_redraw
Note: a new widget created via zle -N: zle-line-pre-redraw
Zle -N -- zle-keymap-select _p9k_wrapper__p9k_zle_keymap_select
Note: === Ended tracking function: _p9k_precmd ===

<span class="hljs-orange">Functions created:</span>
+vi-git-aheadbehind                      +vi-git-remotebranch

(…)
</code></pre>

## Summary

As it can be seen, creation of four additional Zle-widgets has been recorded
(the `Zle -N …` lines). They will be properly deleted/restored on the plugin
unload with `MYPROMPT=3` (for example) and the shell state will be clean, ready
to load a new prompt.

[]( vim:set ft=markdown tw=80: )

