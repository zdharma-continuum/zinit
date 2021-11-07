# declare-zsh

[**declare-zsh**](https://github.com/zdharma-continuum/declare-zsh) is a parser for
`zinit` commands in `.zshrc`. It allows to perform the following actions on
`.zshrc` **from the command-line**:

  - enable and disable selected plugins and snippets,
  - add plugins and snippets,
  - delete plugins and snippets.

---

In other words, by issuing a `declzsh` command the user deploys a task of:

1. Reading and parsing of the `~/.zshrc`.

2. Making changes (like removal of a plugin, i.e. of `zinit load
   {removed-plugin}` command together with the possible associated `zinit ice
   …` command) and then…

3. Writing the result back to the `zshrc` (by default, the result is stored to
   `~/.zshrc_gen` file for safety, but the author wants to emhasize very
   strongly, that **breaking something within the parsed `zshrc` is nearly
   impossible** and the tool can be safely used with option `-o ~/.zshrc` which
   points `declzsh` to the original `zshrc` as the destination, output file).

## Examples & Screenshots

1. Example **disabling** of a plugin via the **toggle** option **-TT** – this
   works because the commands preceded by `:` are ignored by the shell:
![screenshot](https://raw.githubusercontent.com/zdharma/declare-zsh/master/img/toggle.png)

2. Example **addition** of a plugin via the option **-AA** – in order to also
   set up ice modifiers enclose them in a preceding square-bracket block, i.e.
   `declzsh -AA '[ wait"1" lucid ] zdharma-continuum/null'`:
![screenshot](https://raw.githubusercontent.com/zdharma/declare-zsh/master/img/add.png)

3. Example **deletion** of a plugin via the **purge** option **-PP** – the
   argument is treated as pattern, pass `*` to delete all plugins and snippets!:
![screenshot](https://raw.githubusercontent.com/zdharma/declare-zsh/master/img/purge.png)

## Usage

Multiple actions, i.e. multiple options like `-AA`, `-PP`, `-DD`, etc. are
possible in a single `declzsh` run.

![usage screenshot](https://raw.githubusercontent.com/zdharma/declare-zsh/master/img/usage.png)

[]( vim:set ft=markdown tw=80: )
