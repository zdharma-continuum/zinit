# The `atload` Ice (and other `at…` ices)

## Introduction

There are four code-receiving ices: `atclone`, `atpull`, `atinit`, `atload`.
Their role is to **receive a portion of Zsh code and execute it in certain
moments of the plugin life-cycle**. The **`atclone`** executes it:

  - **after cloning** the associated plugin or snippet to the disk.

The **`atpull`** is similar, but works:

  - **after updating** the associated plugin or snippet. 

Next, **`atinit`** works similar, but is being activated:

  - **before loading** of the associated plugin or snippet.

Last, **`atload`** is being activated:

  - **after loading** of the associated plugin or snippet.

For convenience, you can use each of the ices multiple times in single `zplugin
ice …` invocation – all the passed commands will be executed in the given order.

The `atpull` ice recognizes a special value: `%atclone` (so the code looks i.e.:
`atpull'%atclone'`). It causes the contents of the `atclone` ice to be copied
into the contents of the `atpull` ice. This is handy when the same tasks have to
be performed on clone **and** on update of plugin or snippet, like e.g.: in the
[**Direnv example**](../Direnv-explanation).

## *Exclamation mark*-preceded `atload`

The `wrap-track` ice allows to track and unload plugins that defer their
initialization into a function run later after sourcing the plugin's script –
when the function is called, the plugin is then being fully initialized.
However, if the function is being called from the `atload` ice, then there is a
simpler method than the `wrap-track` ice – an *exclamation mark*-preceded
`atload` contents. The exclamation mark causes the effects of the execution of
the code passed to `atload` ice to be recorded.

## Example

For example, in the following invocation:

```zsh
zplugin ice id-as'test' atload'!PATH+=:~/share'
zplugin load zdharma/null
```

the `$PATH` is being changed within `atload` ice. Zplugin's tracking records
`$PATH` changes and withdraws them on plugin unload, and also shows information
loading:

<pre>
<code>
$ zplg report test
Report for test plugin
<span class="hljs-blue">----------------------</span>
Source  (reporting enabled)

<span class="hljs-orange">PATH elements added:</span>
/home/sg/share
</code>
</pre>

As it can be seen, the `atload` code is being correctly tracked and can be
unloaded & viewed. Below is the result of using the `unload` subcommand to
unload the `test` plugin:

<pre>
<code>
$ zplugin unload test
<span class="hljs-blue">--- Unloading plugin: test ---</span>
Removing PATH element /home/sg/share
Unregistering plugin test
Plugin report saved to $LASTREPORT
</code>
</pre>

## Practical example

The same example as in the [**Tracking precmd-based Plugins**](../wrap-track/)
article, but using the *exclamation mark*-preceded `atload` instead of
`wrap-track`:

```zsh
# Load when MYPROMPT == 4
zplugin ice load'![[ $MYPROMPT = 4 ]]' unload'![[ $MYPROMPT != 4 ]]' \
            atload'!source ~/.p10k.zsh; _p9k_precmd'
zplugin load romkatv/powerlevel10k
```

## Summary

The creation of the four additional Zle-widgets will be recorded (see the
[**article**](../wrap-track) on `wrap-track` for more information) – the effect will
be exactly the same as with the `wrap-track` ice.  The widgets will be properly
deleted/restored on the plugin unload with `MYPROMPT=3` (for example) and the
shell state will be clean, ready to load a new prompt.

[]( vim:set ft=markdown tw=80: )

