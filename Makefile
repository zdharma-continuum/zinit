.EXPORT_ALL_VARIABLES:

ZSH := $(shell command -v zsh 2> /dev/null)
SRC := zinit{'','-additional','-autoload','-install','-side'}.zsh
DOC_SRC := $(foreach wrd,$(SRC),../$(wrd))

.PHONY: all clean container doc doc/container tags tags/emacs tags/vim test zwc

clean:
	rm -rvf *.zwc doc/zsdoc/zinit{'','-additional','-autoload','-install','-side'}.zsh.adoc doc/zsdoc/data/

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
		    ctags -G -e -R --options=share/zsh.ctags --languages=zsh \
		        --alias-zsh=+sh \
			    --pattern-length-limit=250 --maxdepth=1 -f .TAGS; \
	    else \
		    ctags -e -R --languages=sh --langmap=sh:.zsh -f .TAGS; \
	    fi; \
	    : Exchange .TAGS for TAGS with minimal disk usage;  \
	    ln -f .TAGS TAGS; \
	    rm -f .TAGS; \
	    printf "Created the Emacs \`TAGS\` file.\\n"; \
	else \
	    printf 'Error: Please install a Ctags (e.g.: either the Exuberant or Universal %b' \
	    'version) utility first.\n'; \
	fi

tags/vim: ## Build the Vim-style ctags file
	@if type ctags >/dev/null 2>&1; then \
	    if ctags --version | grep >/dev/null 2>&1 "Universal Ctags"; then \
		    ctags -G -R --options=share/zsh.ctags --languages=zsh \
		        --alias-zsh=+sh \
			    --pattern-length-limit=250 --maxdepth=1 -f .tags; \
	    else \
		    ctags -R --languages=sh --langmap=sh:.zsh -f .tags; \
	    fi; \
	    : Exchange .tags for tags with minimal disk usage; \
	    ln -f .tags tags; \
	    rm -f .tags; \
	    printf "Created the Vim's style \`tags\` file.\\n"; \
	else \
	    printf 'Error: Please install a ctags first.\n'; \
	fi

test:
	zunit run

zwc:
	$(or $(ZSH),:) -fc 'for f in *.zsh; do zcompile -R -- $$f.zwc $$f || exit; done'
