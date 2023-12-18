.EXPORT_ALL_VARIABLES:

ZSH := $(shell command -v zsh 2> /dev/null)
SRC := zinit{'','-additional','-autoload','-install','-side'}.zsh
DOC_SRC := $(foreach wrd,$(SRC),../$(wrd))

.PHONY: all clean container doc doc/container tags tags/emacs tags/vim test zwc

clean:
	rm -rf *.zwc doc/zsdoc/zinit{'','-additional','-autoload','-install','-side'}.zsh.adoc doc/zsdoc/data/

container:
	docker build --tag=ghcr.io/zdharma-continuum/zinit:latest --file=docker/Dockerfile .

doc: clean
	cd doc; zsh -l -d -f -i -c "zsd -v --scomm --cignore '(\#*FUNCTION:[[:space:]][\:\∞\.\+\@\-a-zA-Z0-9]*[\[]*|}[[:space:]]\#[[:space:]][\]]*)' $(DOC_SRC)"

doc/container: container
	./scripts/docker-run.sh --docs --debug

test:
	zunit run

zwc:
	$(or $(ZSH),:) -fc 'for f in *.zsh; do zcompile -R -- $$f.zwc $$f || exit; done'
