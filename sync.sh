#!/usr/bin/env zsh

autoload colors
colors

git -C ~/github/zplugin_readme checkout gh-pages || {
    print $fg_bold[green]Couldn\'t checkout, trying stash first...$reset_color
    sleep 1
    git -C ~/github/zplugin_readme stash save "$(LANG=C date)"
    git -C ~/github/zplugin_readme checkout gh-pages || exit 1
}
git -C ~/github/zplugin_readme llf
git -C ~/github/zplugin_readme rebase || {
    print $fg_bold[green]Couldn\'t rebase, trying stash first...$reset_color
    git -C ~/github/zplugin_readme stash save "$(LANG=C date)" || exit 2
    git -C ~/github/zplugin_readme rebase || exit 3
}

print $fg_bold[green]Copying files...$reset_color
sleep 1
cp -f ~/github/zplugin_readme/docs/*.md docs
git add -A docs
cp -fv ~/github/zplugin_readme/mkdocs.yml .
git add mkdocs.yml
cp -fv ~/github/zplugin_readme/docs/css/* docs/css
git add -A docs/css
mkdir -p docs/js
cp -fv ~/github/zplugin_readme/docs/js/* docs/js
git add -A docs/js
cp -fv ~/github/zplugin_readme/docs/img/* docs/img
git add -A docs/img
cp -vR ~/github/zplugin_readme/docs/theme/* docs/theme
git add -A docs/theme
print $fg_bold[green]Commiting:$reset_color
sleep 1
{ git commit ${${(M)1:#(a|am|amend)}:+--amend} || git status } && \
    git push -f origin documentation && \
        make gh-pages
