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

# Run ctags to generate Emacs and Vim's format tag file.
tags: tags/emacs tags/vim

tags/emacs: ## Build Emacs-style ctags file
	@if type ctags >/dev/null 2>&1; then \
		if ctags --version | grep >/dev/null 2>&1 "Universal Ctags"; then \
			ctags -e -R --options=share/zsh.ctags --languages=zsh \
			    --pattern-length-limit=250 --maxdepth=1; \
		else \
			ctags -e -R --languages=sh --langmap=sh:.zsh; \
		fi; \
		printf "Created the Emacs \`TAGS\` file.\\n"; \
	else \
	    printf 'Error: Please install a Ctags (e.g.: either the Exuberant or Universal %b' \
	    'version) utility first.\n'; \
	fi

tags/vim: ## Build the Vim-style ctags file
	@if type ctags >/dev/null 2>&1; then \
		if ctags --version | grep >/dev/null 2>&1 "Universal Ctags"; then \
			ctags --languages=zsh --maxdepth=1 --options=share/zsh.ctags --pattern-length-limit=250 -R; \
		else \
			ctags -R --languages=sh --langmap=sh:.zsh; \
		fi; \
		printf "Created the Vim's style \`tags\` file.\\n"; \
	else \
	    printf 'Error: Please install a ctags first.\n'; \
	fi

test:
	zunit run

zwc:
	$(or $(ZSH),:) -fc 'for f in *.zsh; do zcompile -R -- $$f.zwc $$f || exit; done'
