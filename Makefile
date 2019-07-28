site: docs/*.md docs/css/*.css
	mkdocs build

gh-pages: site
	command mv -vf site site_
	git checkout gh-pages
	command rm -rf site
	command mv -vf site_ site
	git add -A site

