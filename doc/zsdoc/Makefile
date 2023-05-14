.EXPORT_ALL_VARIABLES:

SRC := $(shell zsh -c "echo {'git-process-output','rpm2cpio'}.zsh zinit{'','-additional','-autoload','-install','-side'}.zsh")

PDF_SRC := $(foreach wrd,$(SRC),$(wrd).pdf)
PDF_CMD := asciidoctor -a reproducible -b pdf -r asciidoctor-pdf -D pdf

MAN_SRC := $(foreach wrd,$(SRC),man/$(wrd))
MAN_CMD := a2x --verbose -L --doctype manpage --format manpage -D man

HTML_SRC := $(foreach wrd,$(SRC),html/$(wrd).html)
HTML_CMD := asciidoctor -a reproducible -b html -r asciidoctor-pdf -D html

RUBYOPT="-E utf-8:utf-8"

.PHONY: all clean man pdf test

all: clean dirs pdf

dirs:
	mkdir -p html man pdf

# PDFS
# uses asciidoctor not a2x
# html: dirs $(HTML_SRC)
# html/git-process-output.zsh.html:
# 	$(HTML_CMD) git-process-output.zsh.adoc
# html/rpm2cpio.zsh.html:
# 	$(HTML_CMD) rpm2cpio.zsh.adoc
# html/zinit-additional.zsh.html:
# 	$(HTML_CMD) zinit-additional.zsh.adoc
# html/zinit-autoload.zsh.html:
# 	$(HTML_CMD) zinit-autoload.zsh.adoc
# html/zinit-install.zsh.html:
# 	$(HTML_CMD) zinit-install.zsh.adoc
# html/zinit-side.zsh.html:
# 	$(HTML_CMD) zinit-side.zsh.adoc
# html/zinit.zsh.html:
# 	$(HTML_CMD) zinit.zsh.adoc

# Manual pages
# uses a2x from asciidoc package
man: dirs $(MAN_SRC)
man/git-process-output.zsh:
	$(HTML_CMD) git-process-output.zsh.adoc
man/rpm2cpio.zsh:
	$(HTML_CMD) rpm2cpio.zsh.adoc
man/zinit-additional.zsh:
	$(HTML_CMD) zinit-additional.zsh.adoc
man/zinit-autoload.zsh:
	$(HTML_CMD) zinit-autoload.zsh.adoc
man/zinit-install.zsh:
	$(HTML_CMD) zinit-install.zsh.adoc
man/zinit-side.zsh:
	$(MAN_CMD) zinit-side.zsh.adoc
man/zinit.zsh:
	$(MAN_CMD) zinit.zsh.adoc

# PDFS
# uses asciidoctor not a2x
html: dirs $(HTML_SRC)

html/git-process-output.zsh.html:
	$(HTML_CMD) git-process-output.zsh.adoc
html/rpm2cpio.zsh.html:
	$(HTML_CMD) rpm2cpio.zsh.adoc
html/zinit-additional.zsh.html:
	$(HTML_CMD) zinit-additional.zsh.adoc
html/zinit-autoload.zsh.html:
	$(HTML_CMD) zinit-autoload.zsh.adoc
html/zinit-install.zsh.html:
	$(HTML_CMD) zinit-install.zsh.adoc
html/zinit-side.zsh.html:
	$(HTML_CMD) zinit-side.zsh.adoc
html/zinit.zsh.html:
	$(HTML_CMD) zinit.zsh.adoc

clean:
	rm -rf data html man pdf

# vim: set fenc=utf8 ffs=unix ft=make list noet sw=4 ts=4 tw=72:
