# Nickname a plugin or snippet

Zplugin supports loading a plugin or snippet with a nickname. Set the nickname through the `id-as` ice-mod. For example, one could try to load docker/compose from Github binary releases:

```zsh
zplugin ice as"program" from"gh-r" mv"docker-compose* -> docker-compose"
zplugin light "docker/compose"
```

This registers plugin under ID docker/compose. Now the user could want to load a completion from Github repository (not the binary release catalog) also called docker/compose. The two IDs, both being docker/compose, will collide. The user can however resolve the conflict via `id-as` ice-mod by loading the completion under a nickname, for example "dc-completion":

```zsh
zplugin ice as"completion" id-as"dc-completion"
zplugin load docker/compose
```

The completion is now seen under ID dc-completion. Issuing `zplugin report dc-completion` works, so as other Zplugin commands:

```zsh
~ zplugin report dc-completion
Plugin report for dc-completion
-------------------------------

Completions:
_docker-compose [enabled]
```

This can be also used to nickname snippets. For example, you can use this to create handlers in place of long urls:


```zsh
zplugin ice as"program" id-as"git-unique"
zplugin snippet https://github.com/Osse/git-scripts/blob/master/git-unique
```

`zplugin delete git-unique` will work, `zplugin times` will show `git-unique` instead of the URL.

[]( vim:set ft=markdown set tw=80: )
