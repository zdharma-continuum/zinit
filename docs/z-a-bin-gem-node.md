# z-a-bin-gem-node
A Zsh-Zplugin annex (i.e. an extension) that provides functionality, which
allows to:

  1. Run programs and scripts without adding anything to `$PATH`,
  2. Install and run Ruby [gems](https://github.com/rubygems/rubygems) and
     [Node](https://github.com/npm/cli) modules from within a local directory
     with
     [$GEM_HOME](https://guides.rubygems.org/command-reference/#gem-environment)
     and
     [$NODE_PATH](https://nodejs.org/api/modules.html#modules_loading_from_the_global_folders)
     automatically set,
  3. Run programs, scripts and functions with automatic `cd` into the plugin
     or snippet directory,
  4. Source scripts through an automatically created function with the above
     `$GEM_HOME`, `$NODE_PATH` and `cd` features available,
  5. Create the so called `shims` known from
     [rbenv](https://github.com/rbenv/rbenv) – the same feature as the first
     item of this enumaration – of running a program without adding anything
     to `$PATH` with all of the above features, however through an automatic
     **script** created in `$ZPFX/bin`, not a **function** (the first item
     uses a function-based mechanism),
  6. Automatic updates of Ruby gems and Node modules during regular plugin and
     snippet updates with `zplugin update …`.

## How it works – bird's-eye view

Below is a diagram explaining the major feature – exposing a binary program
or script through a Zsh function of the same name:

![diagram](https://raw.githubusercontent.com/zplugin/z-a-bin-gem-node/master/images/diag.png)

This way there is no need to add anything to `$PATH` – `z-a-bin-gem-node`
will automatically create a function that will wrap the binary and provide it
on the command line like if it was being placed in the `$PATH`.

Also, like mentioned in the enumeration, the function can automatically
export `$GEM_HOME`, `$NODE_PATH` shell variables and also automatically cd
into the plugin or snippet directory right before executing the binary and
then cd back to the original directory after the execution is finished.

Also, like already mentioned, instead of the function an automatically
created script – so called `shim` – can be used for the same purpose and with
the same functionality.

## How it works, in detail

Suppose that you would want to install `junegunn/fzf-bin` plugin from GitHub
Releases, which contains only single file – the `fzf` binary for the selected
architecture. It is possible to do it in the standard way – by adding the
plugin's directory to the `$PATH`:

```zsh
zplugin ice as"command" from"github-rel"
zplugin load junegunn/fzf-bin
```

After this command, the `$PATH` variable will contain e.g.:

```zsh
% print $PATH
/home/sg/.zplugin/plugins/junegunn---fzf-bin:/bin:/usr/bin:/usr/sbin:/sbin
```

For many such programs loaded as plugins the PATH can become quite cluttered.
I've had 26 entries before switching to `z-a-bin-gem-node`. To solve this,
load with use of `fbin''` ice provided and handled by `z-a-bin-gem-node`:

```zsh
zplugin ice from"gh-r" fbin"fzf"
zplugin load junegunn/fzf-bin
```

The `$PATH` will remain unchanged and an `fzf` function will be created:

```zsh
% which fzf
fzf () {
        local bindir="/home/sg/.zplugin/plugins/junegunn---fzf-bin"
        "$bindir"/"fzf" "$@"
}
```

Running the function will forward the call to the program accessed through
an embedded path to it. Thus, no `$PATH` changes are needed!

## The Ice Modifiers Provided By The Annex

There are 7 ice-modifiers provided and handled by the annex. They are:
  1. `fbin''` – creates functions for binaries and scripts,
  2. `sbin''` – creates `shims` for binaries and scripts,
  3. `gem''` – installs and updates gems + creates functions for gems'
     binaries,
  4. `node''` – installs and updates node_modules + creates functions for
     binaries of the modules,
  5. `fmod''` – creates wrapping functions for other functions,
  6. `fsrc''` – creates functions that source given scripts,
  7. `ferc''` – the same as `fsrc''`, but using an alternate script-loading
     method.

**The ice-modifiers in detail:**

---

# **`fbin"[{g|n|c}:]{path-to-binary}[ -> {name-of-the-function}]; …"`**

Creates a wrapper function of the name the same as the last segment of the
path or as `{name-of-the-function}`. The optional preceding flags mean:
  
  - `g` – set `$GEM_HOME` variable,
  - `n` – set `$NODE_PATH` variable,
  - `c` – cd to the plugin's directory before running the function and then
    cd back after it has been run.

Example:

```zsh
% zplugin ice from"gh-r" fbin"g:fzf -> myfzf"
% zplugin load junegunn/fzf-bin
% which myfzf
myfzf () {
        local bindir="/home/sg/.zplugin/plugins/junegunn---fzf-bin"
        local -x GEM_HOME="/home/sg/.zplugin/plugins/junegunn---fzf-bin"
        "$bindir"/"fzf" "$@"
}
```

---

# **`gem"{gem-name}; …"`**
# **`gem"[{path-to-binary} <-] !{gem-name} [-> {name-of-the-function}]; …"`**

Installs the gem of name `{gem-name}` with `$GEM_HOME` set to the plugin's or
snippet's directory. In other words, the gem and its dependencies will be
installed locally in that directory.

In the second form it also creates a wrapper function identical to the one
created with `fbin''` ice.

Example:

```zsh
% zplugin ice gem'!asciidoctor'
% zplugin load zdharma/null
% which asciidoctor
asciidoctor () {
        local bindir="/home/sg/.zplugin/plugins/zdharma---null/bin" 
        local -x GEM_HOME="/home/sg/.zplugin/plugins/zdharma---null" 
        "$bindir"/"asciidoctor" "$@"
}
```

---

# **`node"{node-module}; …"`**
# **`node"[{path-to-binary} <-] !{node-module} [-> {name-of-the-function}]; …"`**

Installs the node module of name `{node-module}` inside the plugin's or
snippet's directory.

In the second form it also creates a wrapper function identical to the one
created with `fbin''` ice.

Example:

```zsh
% zplugin delete zdharma/null
Delete /home/sg/.zplugin/plugins/zdharma---null?
[yY/n…]
y
Done (action executed, exit code: 0)
% zplugin ice node'remark <- !remark-cli -> remark; remark-man'
% zplugin load zdharma/null
…installation messages…
% which remark
remark () {
        local bindir="/home/sg/.zplugin/plugins/zdharma---null/node_modules/.bin"
        local -x NODE_PATH="/home/sg/.zplugin/plugins/zdharma---null"/node_modules
        "$bindir"/"remark" "$@"
}
```

In this case the name of the binary program provided by the node module is
different from its name, hence the second form with the `b <- a -> c` syntax
has been used.

---

# **`fmod"[{g|n|c}:]{function-name}; …"`**
# **`fmod"[{g|n|c}:]{function-name} -> {wrapping-function-name}; …"`**

It wraps given function with the ability to set `$GEM_HOME`, etc. – the
meaning of the `g`,`n` and `c` flags is the same as in the `fbin''` ice.

Example:

```zsh
% myfun() { pwd; ls -1 }
% zplugin ice fmod'cgn:myfun'
% zplugin load zdharma/null
% which myfun
myfun () {
        local -x GEM_HOME="/home/sg/.zplugin/plugins/zdharma---null"
        local -x NODE_PATH="/home/sg/.zplugin/plugins/zdharma---null"/node_modules
        local oldpwd="/home/sg/.zplugin/plugins/zplugin---z-a-bin-gem-node"
        () {
                setopt localoptions noautopushd
                builtin cd -q "/home/sg/.zplugin/plugins/zdharma---null"
        }
        "myfun--za-bgn-orig" "$@"
        () {
                setopt localoptions noautopushd
                builtin cd -q "$oldpwd"
        }
}
% myfun
/home/sg/.zplugin/plugins/zdharma---null
LICENSE
README.md
```

---

# **`sbin"[{g|n|c}:]{path-to-binary}[ -> {name-of-the-script}]; …"`**

It creates the so called `shim` known from `rbenv` – a wrapper script that
forwards the call to the actual binary. The script is created always under
the same, standard and single `$PATH` entry: `$ZPFX/bin` (which is
`~/.zplugin/polaris/bin` by default).

The flags have the same meaning as with `fbin''` ice.

Example:

```zsh
% zplugin delete junegunn/fzf-bin
Delete /home/sg/.zplugin/plugins/junegunn---fzf-bin?
[yY/n…]
y
Done (action executed, exit code: 0)
% zplugin ice from"gh-r" sbin"fzf"
% zplugin load junegunn/fzf-bin
…installation messages…
% cat $ZPFX/bin/fzf
#!/usr/bin/env zsh

function fzf {
    local bindir="/home/sg/.zplugin/plugins/junegunn---fzf-bin"
    "$bindir"/"fzf" "$@"
}

fzf "$@"
```

---

# **`fsrc"[{g|n|c}:]{path-to-script}[ -> {name-of-the-function}]; …"`**
# **`ferc"[{g|n|c}:]{path-to-script}[ -> {name-of-the-function}]; …"`**

Creates a wrapper function that at each invocation sources the given file.
The second ice, `ferc''` works the same with the single difference that it
uses `eval "$(<{path-to-script})"` instead of `source "{path-to-script}"` to
load the script.

Example:

```zsh
% zplugin ice fsrc"myscript -> myfunc" ferc"myscript"
% zplugin load zdharma/null
% which myfunc
myfunc () {
        local bindir="/home/sg/.zplugin/plugins/zdharma---null"
        () {
                source "$bindir"/"myscript"
        } "$@"
}
% which myscript
myscript () {
        local bindir="/home/sg/.zplugin/snippets/OMZ::plugins--git/git.plugin.zsh"
        () {
                eval "$(<"$bindir"/"myscript")"
        } "$@"
}
```

## Installation

Simply load like a regular plugin, i.e.:

```zsh
zplugin light zplugin/z-a-bin-gem-node
```

After executing this command you can then use the dl'' and patch'' ice-mods.

[]( vim:set ft=markdown fo+=an1 autoindent tw=77: )
