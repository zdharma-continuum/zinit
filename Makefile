wiki: docs/*.md docs/css/*.css
	mkdocs build -d wiki

gh-pages: wiki
	command mv -vf wiki wiki_
	git checkout gh-pages
	command rm -rf wiki
	command mv -vf wiki_ wiki
	git add -A wiki
	echo "Site build ["`date "+%m/%d/%Y %H:%M:%S"`"]" > .git/COMMIT_EDITMSG
	cat .git/COMMIT_EDITMSG

master: wiki
	git checkout master
