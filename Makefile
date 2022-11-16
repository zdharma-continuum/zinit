.EXPORT_ALL_VARIABLES:

ZSH := $(shell command -v zsh 2> /dev/null) -ilc
SRC := share/{'git-process-output','rpm2cpio'}.zsh zinit{'','-additional','-autoload','-install','-side'}.zsh
DOC_SRC := $(foreach wrd,$(SRC),../$(wrd))

.PHONY: all clean container doc doc/container tags tags/emacs tags/vim test zwc

clean:
	rm -rvf *.zwc doc/zsdoc/zinit{'','-additional','-autoload','-install','-side'}.zsh.adoc doc/zsdoc/data/
	$(ZSH) 'zi delete --yes zdharma-continuum/zshelldoc; exit'

container:
	docker build --tag=ghcr.io/zdharma-continuum/zinit:latest --file=docker/Dockerfile .

deps:
	$(ZSH) "zi for make'PREFIX=$${ZPFX} install' nocompile zdharma-continuum/zshelldoc"

doc: deps
	cd doc; $(ZSH) -df "zsd -v --scomm --cignore '(\#*FUNCTION:[[:space:]][\~\-\:\+\@\__\-a-zA-Z0-9]*[\[]*|}[[:space:]]\#[[:space:]][\]]*)' $(DOC_SRC); make -C ./zsdoc pdf"

doc/container: container
	./scripts/docker-run.sh --docs --debug

tags: tags/emacs tags/vim ## Run ctags to generate Emacs and Vim's format tag file.

tags/emacs: ## Build Emacs-style ctags file
	@if type ctags >/dev/null 2>&1; then \
		if ctags --version | grep >/dev/null 2>&1 "Universal Ctags"; then \
			ctags --languages=zsh --maxdepth=1 --options=share/zsh.ctags --pattern-length-limit=250 -R -e; \
		else \
			ctags -e -R --languages=sh --langmap=sh:.zsh; \
		fi; \
		printf "Created the Emacs TAGS file\n"; \
	else \
		printf 'Error: Please install a Ctags (e.g.: either the Exuberant or Universal %b version) utility first\n'; \
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
	$(ZSH) 'for f in *.zsh; do zcompile -R -- $$f.zwc $$f || exit; done'