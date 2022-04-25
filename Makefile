.EXPORT_ALL_VARIABLES:
# SHELL=zsh
SRC := zinit.zsh zinit-side.zsh zinit-install.zsh zinit-autoload.zsh
DOC_SRC := $(foreach wrd,$(SRC),../$(wrd))

cur-dir := $(shell pwd)

all: $(wildcard *.zsh)

%.zsh: %.zwc
	scripts/zcompile $(@)

doc-container: zinit.zsh zinit-side.zsh zinit-install.zsh zinit-autoload.zsh
	./scripts/docker-run.sh --docs --debug

doc: clean
	cd doc; zsh -d -f -i -c "zsd -v --scomm --cignore '(\#*FUNCTION:*{{{*|\#[[:space:]]#}}}*)' $(DOC_SRC)"

clean:
	rm -rf doc/zsdoc/data doc/zsdoc/*.adoc

.PHONY: all test clean doc doc-container
