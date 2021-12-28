wiki: docs/*.md docs/css/*.css
	mkdocs -v build -d wiki

gh-pages: wiki
	mv -vf wiki wiki_
	git checkout gh-pages
	rm -rf wiki
	mv -vf wiki_ wiki
	git add -A wiki
	echo "Site build ["`date "+%m/%d/%Y %H:%M:%S"`"]" > .git/COMMIT_EDITMSG_
	cat .git/COMMIT_EDITMSG_
	git commit -F .git/COMMIT_EDITMSG_ && git push -f origin gh-pages

master: wiki
	git checkout master

docker-build:
	docker build -t zinit-docs:latest .

docker-wiki:
	docker run --rm -it -v $$PWD:/opt -w /opt zinit-docs:latest make wiki
