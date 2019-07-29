site: docs/*.md docs/css/*.css
	mkdocs build
	./high.sh

gh-pages: site
	command mv -vf site site_
	git checkout gh-pages
	command rm -rf site
	command mv -vf site_ site
	git add -A site
	echo "Site build ["`date "+%m/%d/%Y %H:%M:%S"`"]" > .git/COMMIT_EDITMSG

master: site
	git checkout master
