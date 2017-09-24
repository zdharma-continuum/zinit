# Code documentation

Here is `Asciidoc` code documentation generated using [Zshelldoc](https://github.com/zdharma/zshelldoc).
There are `4` source files, the main one is [zplugin.zsh](zplugin.zsh.adoc). The documentation
lists all functions, interactions between them, and their comments.

 * [zplugin.zsh](zplugin.zsh.adoc) – always loaded, in `.zshrc`
 * [zplugin-side.zsh](zplugin-side.zsh.adoc) – common functions, loaded by `*-install` and `*-autoload` scripts
 * [zplugin-install.zsh](zplugin-install.zsh.adoc) – functions used only when installing plugin or snippet
 * [zplugin-autoload.zsh](zplugin-autoload.zsh.adoc) – functions used only in interactive `Zplugin` invocations
