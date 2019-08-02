Normally `src''` can be used to specify additional file to source:

```zsh
zplugin ice pick"powerless.zsh" src"utilities.zsh"
zplugin light martinrotter/powerless
```
- `pick''` – provide main file to source (can be pattern like `*.sh`, alphabetically first matched file is sourced),
- `src''` – provide second file to source (not a pattern, plain file name)

***

However, via `atload''` ice one can provide simple loop to source more files:

```zsh
zplugin ice svn pick"completion.zsh" \
    atload'local f; for f in git.zsh misc.zsh; do source $f; done'
zplugin snippet OMZ::lib
```
- `svn` – use Subversion to clone `OMZ::lib` (Oh My Zsh `lib/` directory),
- note that `atload''` uses apostrophes not double quotes, to literally put `$f` into the string,
- `atload''` code isn't tracked by Zplugin, i.e. cannot be unloaded, unless you prepend its value by exclamation mark, i.e. `atload'!local f; for ...'`,
- `atload''` is executed after loading main files (`pick''` and `src''` ones).

****

**NEW**: The `multisrc''` ice, which loads **multiple** files enumerated with spaces as the separator (e.g. `multisrc'misc.zsh grep.zsh'`) and also using brace-expansion syntax (e.g. `multisrc'{misc,grep}.zsh')`. Example:

```zsh
zplugin ice svn pick"completion.zsh" multisrc'git.zsh \
    functions.zsh {history,grep}.zsh'
zplugin snippet OMZ::lib
```

The all possible ways to use the `multisrc''` ice-mod:

```zsh
zplugin ice depth"1" multisrc="lib/{functions,misc}.zsh" pick"/dev/null"
zplugin load robbyrussell/oh-my-zsh

# Can use patterns
zplugin ice svn multisrc"{funct*,misc}.zsh" pick"/dev/null"
zplugin snippet OMZ::lib

array=( {functions,misc}.zsh )
zplugin ice svn multisrc"$array" pick"/dev/null"
zplugin snippet OMZ::lib

# Will use the array's value at the moment of plugin load
# – this can matter in case of using turbo mode
array=( {functions,misc}.zsh )
zplugin ice svn multisrc"\$array" pick"/dev/null"
zplugin snippet OMZ::lib

# Compatible with KSH_ARRAYS option
array=( {functions,misc}.zsh )
zplugin ice svn multisrc"${array[*]}" pick"/dev/null"
zplugin snippet OMZ::lib

# Compatible with KSH_ARRAYS option
array=( {functions,misc}.zsh )
zplugin ice svn multisrc"\${array[*]}" pick"/dev/null"
zplugin snippet OMZ::lib

zplugin ice svn multisrc"misc.zsh functions.zsh" pick"/dev/null"
zplugin snippet OMZ::lib
```

[]( vim:set ft=markdown tw=80: )
