SHELL=zsh
.EXPORT_ALL_VARIABLES:

cur-dir := $(shell pwd)

all: $(wildcard *.zsh)

%.zsh: %.zwc
	scripts/zcompile $(@)

doc-container: zinit.zsh zinit-side.zsh zinit-install.zsh zinit-autoload.zsh
	./scripts/docker-run.sh --docs --debug

# doc:
# 	rm -rf doc/zsdoc/{data,*.adoc}
# 	cd doc;
# 	zsd --cignore \
# 			--scomm \
# 			--verbose \
# 			'(\#*FUNCTION:*{{{*|\#[[:space:]]#}}}*)' \
# 			../zinit.zsh ../zinit-side.zsh ../zinit-install.zsh ../zinit-autoload.zsh
# EXECUTABLES = zsd
# doc: clean
# 	$(foreach exec,$(EXECUTABLES),\
# 		$(if $(shell PATH=$(PATH) which $(exec)),exec,$(error "No $(exec) in PATH")))
# 	zsd --cignore '(\#*FUNCTION:*{{{*|\#[[:space:]]#}}}*)' \
# 			--scomm \
# 			--verbose \
# 			zinit.zsh zinit-side.zsh zinit-install.zsh zinit-autoload.zsh

# 	rm -rf doc/zsdoc/data doc/zsdoc/*.adoc
# 	# cd is required since zsd outputs to PWD/zsdoc/
# 	cd doc; \
# 		zsh -ils -c -- "zsd -v --scomm --cignore '(\#*FUNCTION:*{{{*|\#[[:space:]]#}}}*)' ../zinit.zsh ../zinit-side.zsh ../zinit-install.zsh ../zinit-autoload.zsh"

# EXECUTABLES = zsd
# doc: clean
# 	$(foreach exec,$(EXECUTABLES),\
# 		$(if $(shell PATH=$(PATH) which $(exec)),exec,$(error "No $(exec) in PATH")))
# 	zsd --cignore '(\#*FUNCTION:*{{{*|\#[[:space:]]#}}}*)' \
# 			--scomm \
# 			--verbose \

foo := zinit.zsh zinit-side.zsh zinit-install.zsh zinit-autoload.zsh
bar := $(foreach wrd,$(foo),../$(wrd))
doc:
	cd doc; export TERM='xterm-256'; export LC_ALL='en_US.UTF-8'; $(SHELL) -c -- "zsd --scomm --cignore '(\#*FUNCTION:*{{{*|\#[[:space:]]#}}}*)' $(bar)"

clean:
	rm -rf *.zwc doc/zsdoc/data

.PHONY: all test clean doc doc-container
