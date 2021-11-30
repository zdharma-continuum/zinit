[![paypal](https://www.paypalobjects.com/en_US/i/btn/btn_donateCC_LG.gif)](https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=D6XDCHDSBDSDG)

## Introduction

A shell command that will display selection list. It is similar to `selecta`,
but uses curses library to do display, and when compared to `fzf`, the main
difference is approximate matching instead of fuzzy matching. It is written in
Zshell and has it's capabilities:

- patterns, allowing multi-term searching
- curses module
- approximate matching (`Ctrl-F`)

The file `zsh-select` can be copied to any `bin` directory. `Zsh` will
serve as say `Ruby`, and `zsh-select` will be a regular program available
in system.

Pressing `o` will make elements uniqe. To search again after pressing enter,
press `/`. Approximate matching mode is activated by `Ctrl-F`.

Video: [asciinema](https://asciinema.org/a/48490). You can resize the video by pressing `Ctrl-+` or `Cmd-+`.

[![asciicast](https://asciinema.org/a/48490.png)](https://asciinema.org/a/48490)

## Installation

Simply copy file `zsh-select` to any `bin` directory such as `/usr/local/bin`.
The package is also available as plugin. `zsh-select` will be available in
interactive `Zsh` sessions only when using this method. Nevertheless, integration
with `Vim` and other uses will simply work when `Zsh` is your main shell. Also,
plugin managers often allow easy updates.

## Integration with Vim

Adding following snippet to `vimrc` will provide `\f` keyboard shortcut that will
run `zsh-select` as file-selector. Multi-term searching and approximate matching
(`Ctrl-F`) will be available. The snippet is based on code from `selecta` github
page (MIT license):

```vim
" Run a given vim command on the results of fuzzy selecting from a given shell
" command. See usage below.
function! ZshSelectCommand(choice_command, zshselect_args, vim_command)
  try
    let selection = system(a:choice_command . " | zsh-select " . a:zshselect_args)
  catch /Vim:Interrupt/
    " Swallow the ^C so that the redraw below happens; otherwise there will be
    " leftovers from zshselect on the screen
    redraw!
    return
  endtry
  redraw!
  exec a:vim_command . " " . selection
endfunction

" Find all files in all non-dot directories starting in the working directory.
" Fuzzy select one of those. Open the selected file with :e.
nnoremap <leader>f :call ZshSelectCommand("find * -type f 2>/dev/null", "", ":e")<cr>
```

## Configuring

There are a few environment variables that can be set to alter `Zsh-Select`
behavior. Values assigned below are the defaults:

```zsh
export ZSHSELECT_BOLD="1"                   # The interface will be drawn in bold font. Use "0" for no bold
export ZSHSELECT_COLOR_PAIR="white/black"   # Draw in white foreground, black background. Try e.g.: "white/green"
export ZSHSELECT_BORDER="0"                 # No border around interface, Use "1" for the border
export ZSHSELECT_ACTIVE_TEXT="reverse"      # Mark current element with reversed text. Use "underline" for marking with underline
export ZSHSELECT_START_IN_SEARCH_MODE="1"   # Starts Zsh-Select with searching active. "0" will not invoke searching at start.
```

## Use with plugin managers
### [Zinit](https://github.com/psprint/zinit)

Add `zinit load psprint/zsh-select` to `.zshrc`.
The plugin will be loaded next time you start `Zsh`.
To update issue `zinit update psprint/zsh-select` from command line.

### Zgen

Add `zgen load psprint/zsh-select` to `.zshrc` and issue a `zgen reset` (this
assumes that there is a proper `zgen save` construct in `.zshrc`).

### Antigen
Add `antigen bundle psprint/zsh-select` to `.zshrc`. There also should be
`antigen apply`.

