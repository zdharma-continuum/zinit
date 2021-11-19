# Documentation

## Generate the manage (doc/zinit.1)

1. Install [pandoc](https://pandoc.org/)
2. From the root of the repo run:

```zsh
pandoc --standalone --to man README.md -o doc/zinit.1
```

## Updating the gh-pages (zdharma-continuum.github.io)

1. Check out the [documentation branch](https://github.com/zdharma-continuum/zinit/tree/documentation)
```shell
git fetch origin documentation
git checkout documentation
```
2. Do your modifications and push your changes
3. Keep an eye on [the CI logs](https://github.com/zdharma-continuum/zinit/actions/workflows/gh-pages.yaml)
4. If all went well you can head to https://zdharma-continuum.github.io/ to see your changes live.

**NOTE:** If you really **need** to push directly, without CI please refer to
[the README in the documentation]https://github.com/zdharma-continuum/zinit/blob/documentation/README.md
