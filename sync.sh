#!/usr/bin/env zsh

autoload colors
colors

git -C ~/github/zplugin_readme checkout gh-pages || {
    print $fg_bold[green]Couldn\'t checkout, trying stash first...$reset_color
    sleep 1
    git -C ~/github/zplugin_readme stash
    git -C ~/github/zplugin_readme checkout gh-pages || exit 1
}
git -C ~/github/zplugin_readme llf
git -C ~/github/zplugin_readme rebase || exit 2

print $fg_bold[green]Copying files...$reset_color
sleep 1
cp -f ~/github/zplugin_readme/docs/*.md docs
git add -A docs
cp -fv ~/github/zplugin_readme/mkdocs.yml .
git add mkdocs.yml
cp -fv ~/github/zplugin_readme/docs/css/* docs/css
git add -A docs/css
print $fg_bold[green]Commiting:$reset_color
sleep 1
git commit ${${(M)1:#(a|am|amend)}:+--amend} && \
    git push -f origin documentation && \
        make gh-pages
