.EXPORT_ALL_VARIABLES:

ZSH := $(shell command -v zsh 2> /dev/null)
SRC := share/{'git-process-output','rpm2cpio'}.zsh zinit{'','-additional','-autoload','-install','-side'}.zsh
DOC_SRC := $(foreach wrd,$(SRC),../$(wrd))
HAS_TTY := $(shell echo $${GITHUB_ACTIONS:---tty})

.PHONY: all clean container-build container-shell container-docs tags tags/emacs tags/vim test zwc

all: help

clean:
	rm -rvf *.zwc doc/zsdoc/zinit{'','-additional','-autoload','-install','-side'}.zsh.adoc doc/zsdoc/data/

doc: clean ## Generate zinit documentation
	cd doc; zsh -l -d -f -i -c "zsd -v --scomm --cignore '(\#*FUNCTION:[[:space:]][\+\@\-\:\_\_a-zA-Z0-9]*[\[]*|}[[:space:]]\#[[:space:]][\]]*|\#[[:space:]][\]]*)' $(DOC_SRC); make -C ./zsdoc pdf"

CONTAINER_NAME := zinit
CONTAINER_CMD := docker run -i $(HAS_TTY) --platform=linux/x86_64 --mount=source=$(CONTAINER_NAME)-volume,destination=/root

container-build: ## build docker image
	docker build --file=Dockerfile --platform=linux/x86_64 --tag=$(CONTAINER_NAME):latest .

container-docs: ## regenerate zinit docs in container
	$(CONTAINER_CMD) $(CONTAINER_NAME):latest make --directory zinit.git/ doc

container-shell: ## start shell in docker container
	$(CONTAINER_CMD) $(CONTAINER_NAME):latest

test: ## Run zunit tests
	zunit run

zwc: ## compile zsh files via zcompile
	$(or $(ZSH),:) -fc 'for f in *.zsh; do zcompile -R -- $$f.zwc $$f || exit; done'

tags: tags/emacs tags/vim ## run ctags to generate emacs and vim's format tag file.

tags/emacs: ## build emacs-style ctags file
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

tags/vim: ## build the vim-style ctags file
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

help: ## display available make targets
	@ # credit: tweekmonster github gist
	@echo "$$(grep -hE '^[a-zA-Z0-9_-]+:.*##' $(MAKEFILE_LIST) | sed -e 's/:.*##\s*/:/' -e 's/^\(.\+\):\(.*\)/\\033[36m\1\\033[m:\2/' | column -c2 -t -s : | sort)"

# vim: set fenc=utf8 ffs=unix ft=make list noet sw=4 ts=4 tw=72:
