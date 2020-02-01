#!/usr/bin/env zsh

autoload colors
colors

git -C ~/github/readme_zplugin checkout gh-pages || {
    print $fg_bold[green]Couldn\'t checkout, trying stash first...$reset_color
    sleep 1
    git -C ~/github/readme_zplugin stash save "$(LANG=C date)"
    git -C ~/github/readme_zplugin checkout gh-pages || exit 1
}
git -C ~/github/readme_zplugin llf
git -C ~/github/readme_zplugin rebase || {
    print $fg_bold[green]Couldn\'t rebase, trying stash first...$reset_color
    git -C ~/github/readme_zplugin stash save "$(LANG=C date)" || exit 2
    git -C ~/github/readme_zplugin rebase || exit 3
}

print $fg_bold[green]Copying files...$reset_color
sleep 1
cp -f ~/github/readme_zplugin/docs/*.md docs
git add -A docs
cp -fv ~/github/readme_zplugin/mkdocs.yml .
git add mkdocs.yml
cp -fv ~/github/readme_zplugin/docs/css/* docs/css
git add -A docs/css
mkdir -p docs/js
cp -fv ~/github/readme_zplugin/docs/js/* docs/js
git add -A docs/js
cp -fv ~/github/readme_zplugin/docs/img/* docs/img
git add -A docs/img
cp -vR ~/github/readme_zplugin/docs/theme/* docs/theme
git add -A docs/theme
print $fg_bold[green]Commiting:$reset_color
sleep 1
{ git commit ${${(M)1:#(a|am|amend)}:+--amend} || git status } && \
    git push -f origin documentation && \
        make gh-pages
