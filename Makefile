.EXPORT_ALL_VARIABLES:

ZSH := $(shell command -v zsh 2> /dev/null)
SRC := zinit{'','-autoload','-install','-side'}.zsh
# zinit.zsh zinit-side.zsh zinit-install.zsh zinit-autoload.zsh
DOC_SRC := $(foreach wrd,$(SRC),../$(wrd))

.PHONY: all \
        clean \
        doc \
        doc/container \
        test \
        tags \
        tags-emacs \
        tags-vim

# Invoke a ctags utility to generate Emacs and Vim's format tag file.
#
# Generate two formats at once: Emacs and Vim's.
tags: tags-emacs tags-vim

# Build only the Emacs-style `TAGS` file.
tags-emacs:
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

# Build only the Vim-style `tags` file.
tags-vim:
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
	    printf 'Error: Please install a Ctags (e.g.: either the Exuberant or Universal %b' \
	    'version) utility first.\n'; \
	fi

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
