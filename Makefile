.EXPORT_ALL_VARIABLES:

# ZSH := $(shell command -v zsh 2> /dev/null)
ZSH := /Users/null/.local/bin/zsh
SRC := zinit{'','-autoload','-additional','-install','-side'}.zsh
# zinit.zsh zinit-side.zsh zinit-install.zsh zinit-autoload.zsh
DOC_SRC := $(foreach wrd,$(SRC),../$(wrd))

zwc:
	$(or $(ZSH),:) -fc 'for f in *.zsh; do zcompile -R -- $$f.zwc $$f || exit; done'

doc/container:
	./scripts/docker-run.sh --docs --debug

doc: clean
	$(or $(ZSH),:) -dflc "make --directory $(shell pwd)/doc asciidoc"
	#  -dfl -c "zsd -v --scomm --cignore '(\#*FUNCTION:*{{{*|\#[[:space:]]#}}}*)' $(DOC_SRC)"

test:
	zunit run

clean:
	rm -rvf *.zwc doc/zsdoc/zinit{'','-autoload','-additional','-install','-side'}.zsh.adoc doc/zsdoc/data/

.PHONY: all clean doc doc/container test
