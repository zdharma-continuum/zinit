# Nickname a plugin or snippet

Zinit supports loading a plugin or snippet with a nickname. Set the nickname
through the `id-as` ice-mod. For example, one could try to load
[**docker/compose**](https://github.com/docker/compose) from GitHub binary
releases:

```zsh
zinit ice as"program" from"gh-r" mv"docker-c* -> docker-compose"
zinit light "docker/compose"
```

This registers plugin under the ID `docker/compose`. Now suppose the user would
want to also load a completion from the project's GitHub repository (not the
binary release catalog) which is also available under the GitHub url-path
**…/docker/compose**. The two IDs, both being "docker/compose", will collide.

The solution to this problem – the `id-as` (to be read as: _identify-as_) ice to
which this document is devoted: by using the `id-as` ice the user can resolve
the conflict by loading the completion under a kind of a _nickname_, for example
under "_dc-complete_", by issuing the following commands:

```zsh
zinit ice as"completion" id-as"dc-complete"
zinit load docker/compose
```

The plugin (of the type `completion`) is now seen under ID `dc-complete`:

```zsh
~ zinit list | grep -i dc-complete
dc-complete
```

Issuing `zinit report dc-complete` also works, so as other Zinit commands:

```zsh
~ zinit report dc-complete
Plugin report for dc-complete
-------------------------------

Completions:
_docker-compose [enabled]
```

This can be also used to nickname snippets. For example, you can use this to
create handy IDs in place of long urls:

```zsh
zinit ice as"program" id-as"git-unique"
zinit snippet https://github.com/Osse/git-scripts/blob/master/git-unique
```

The commands `zinit update git-unique`, `zinit delete git-unique` and other
will work normally and e.g. `zinit times` will show the _nickname_-ID
`git-unique` instead of the long URL.

## `id-as'auto'`

There's a special value to the `id-as''` ice – `auto`. It causes the nickname to
be automatically set to the last component of the plugin name or snippet URL.
For example:

```zsh
zinit ice as"program" id-as"auto"
zinit snippet https://github.com/Osse/git-scripts/blob/master/git-unique
```

will work the same as before, i.e.: like if the ice used was
`id-as'git-unique'`. Example with a plugin:

```zsh
# Will work as if id-as'zsh-autopair' was passed
zinit ice wait lucid id-as"auto"
zinit load hlissner/zsh-autopair
```

[]( vim:set ft=markdown tw=80: )
