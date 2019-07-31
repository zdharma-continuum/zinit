#!/usr/bin/env zsh

cp -vf ~/github/zplugin_readme/docs/*.md docs
git add -A docs
cp -vf ~/github/zplugin_readme/mkdocs.yml .
git add mkdocs.yml
git commit ${${(M)1:#(a|am|amend)}:+--amend} && \
    git push -f origin documentation && \
        make gh-pages
