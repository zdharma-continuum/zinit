# Content based a bit on this nice documentation:
#
# https://wiki.archlinux.org/index.php/Zsh
#
# You can also debug this library with `whence -f red`
colors=( black red green yellow blue magenta cyan white )
autoload -Uz "${colors[@]}"
autoload -Uz colors && colors
