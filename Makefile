.EXPORT_ALL_VARIABLES:

ZSH := $(shell command -v zsh 2> /dev/null) -ilc
SRC := share/{'git-process-output','rpm2cpio'}.zsh zinit{'','-additional','-autoload','-install','-side'}.zsh
DOC_SRC := $(foreach wrd,$(SRC),../$(wrd))
CONTAINTER_NAME := zinit

.PHONY: all clean container-build container-shell doc doc-container help tags tags-emacs tags-vim test zwc
.SILENT: all clean container-build container-shell doc doc-container help tags tags-emacs tags-vim test zwc

all: help

clean:
	rm -rf *.zwc doc/zsdoc/zinit{'','-additional','-autoload','-install','-side'}.zsh.adoc doc/zsdoc/data/

container-build: ## build docker image
	docker build \
		--compress \
		--file=Dockerfile \
		--force-rm \
		--platform=linux/x86_64 \
		--rm \
		--tag=$(CONTAINTER_NAME):latest \
		.

container-shell: ## start shell in docker container
	docker run \
		--interactive \
		--mount=source=zinit-volume,destination=/root \
		--platform=linux/x86_64 \
		--tty \
		$(CONTAINTER_NAME):latest

doc: clean
	cd doc; $(ZSH) -df "zsd -v --scomm --cignore '(\#*FUNCTION:[[:space:]][\+\@\:∞\.\~\-\-a-zA-Z0-9]*[\[]*|}[[:space:]]\#[[:space:]][\]]*)' $(DOC_SRC); make -C ./zsdoc pdf"

doc-container:
	./scripts/docker-run.sh --docs --debug

help: ## display available make targets
	@ # credit: tweekmonster github gist
	echo "$$(grep -hE '^[a-zA-Z0-9_-]+:.*##' $(MAKEFILE_LIST) | sed -e 's/:.*##\s*/:/' -e 's/^\(.\+\):\(.*\)/\\033[36m\1\\033[m:\2/' | column -c2 -t -s : | sort)"

tags: tags/emacs tags/vim ## Run ctags to generate Emacs and Vim's format tag file

tags-emacs: ## build emacs-style ctags file
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

tags-vim: ## build the vim-style ctags file
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

zwc: ## compile zsh files via zcompile
	$(or $(ZSH),:) -fc 'for f in *.zsh; do zcompile -R -- $$f.zwc $$f || exit; done'

# vim:syn=dockerfile:ft=dockerfile:fo=croql:sw=2:sts=2
