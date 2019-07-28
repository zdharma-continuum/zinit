# declare-zsh

`declare-zsh` is a parser for `zplugin` commands in `.zshrc`. It allows to
perform the following actions on `.zshrc` **from the command-line**:
  - enable and disable selected plugins and snippets,
  - add plugins and snippets,
  - delete plugins and snippets.

Example **disabling** of a plugin via the **toggle** option **-TT** –
the commands preceded by `:` are ignored by the shell:
![screenshot](https://raw.githubusercontent.com/zdharma/declare-zsh/master/img/toggle.png)

Example **addition** of a plugin via the option **-AA** – in order to
also set up ice modifiers enclose them in a preceding square-bracket
block, i.e. `declzsh -AA '[ wait"1" lucid ] zdharma/null'`:
![screenshot](https://raw.githubusercontent.com/zdharma/declare-zsh/master/img/add.png)

Example **deletion** of a plugin via the **purge** option **-PP** – the
argument is treated as pattern, pass `*` to delete all plugins and
snippets!:
![screenshot](https://raw.githubusercontent.com/zdharma/declare-zsh/master/img/purge.png)

# Usage

![usage screenshot](https://raw.githubusercontent.com/zdharma/declare-zsh/master/img/usage.png)

<!-- vim:tw=72:wrap
