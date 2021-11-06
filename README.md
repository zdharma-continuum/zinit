# How to edit the docs ie. the wiki

1. Run `make documentation`
2. Do your edits on this branch (documentation)
3. To deploy your changes you need to:
  - install [mkdocs](https://www.mkdocs.org/) and [mkdocs-material](https://squidfunk.github.io/mkdocs-material/):
  ```shell
  pipx install mkdocs
  pipx runpip mkdocs install mkdocs-material
  ```
  -❗ THIS WILL FORCE PUSH WHATEVER MKDOCS GENERATES TO THE GH-PAGES BRANCH: 
  run `make gh-pages`.
