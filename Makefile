cur-dir := $(shell pwd)

all: $(wildcard *.zsh)

%.zsh: %.zwc
	scripts/zcompile $(@)

doc-container: zinit.zsh zinit-side.zsh zinit-install.zsh zinit-autoload.zsh
	./scripts/docker-run.sh --docs --debug

doc:
	rm -rf doc/zsdoc/{data,*.adoc}
	cd doc;
	zsd --cignore \
			--scomm \
			--verbose \
			'(\#*FUNCTION:*{{{*|\#[[:space:]]#}}}*)' \
			../zinit.zsh ../zinit-side.zsh ../zinit-install.zsh ../zinit-autoload.zsh

clean:
	rm -rf *.zwc doc/zsdoc/data

.PHONY: all test clean doc doc-container
