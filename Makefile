.EXPORT_ALL_VARIABLES:

ZSH := $(shell command -v zsh 2> /dev/null)
SRC := zinit{'','-autoload','-install','-side'}.zsh
# zinit.zsh zinit-side.zsh zinit-install.zsh zinit-autoload.zsh
DOC_SRC := $(foreach wrd,$(SRC),../$(wrd))

zwc:
	$(or $(ZSH),:) -fc 'for f in *.zsh; do zcompile -R -- $$f.zwc $$f || exit; done'

doc/container:
	./scripts/docker-run.sh --docs --debug

doc: clean
	cd doc; zsh -d -f -i -c "zsd -v --scomm --cignore '(\#*FUNCTION:*{{{*|\#[[:space:]]#}}}*)' $(DOC_SRC)"

test:
	zunit run

clean:
	rm -rvf *.zwc doc/zsdoc/zinit{'','-autoload','-install','-side'}.zsh.adoc doc/zsdoc/data/

.PHONY: all clean doc doc/container test
