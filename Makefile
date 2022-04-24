.ONESHELL:
cur-dir := $(shell pwd)

%.zsh: %.zwc
	scripts/zcompile $(@)

doc-container: zinit.zsh zinit-side.zsh zinit-install.zsh zinit-autoload.zsh
	./scripts/docker-run.sh --docs --debug

# EXECUTABLES = zsd
# doc: clean
# 	$(foreach exec,$(EXECUTABLES),\
# 		$(if $(shell PATH=$(PATH) which $(exec)),exec,$(error "No $(exec) in PATH")))
# 	zsd --cignore '(\#*FUNCTION:*{{{*|\#[[:space:]]#}}}*)' \
# 			--scomm \
# 			--verbose \
# 			zinit.zsh zinit-side.zsh zinit-install.zsh zinit-autoload.zsh

doc: zinit.zsh zinit-side.zsh zinit-install.zsh zinit-autoload.zsh
	rm -rf doc/zsdoc/data doc/zsdoc/*.adoc
	# cd is required since zsd outputs to PWD/zsdoc/
	cd doc; \
		zsh -ils -c -- "zsd -v --scomm --cignore '(\#*FUNCTION:*{{{*|\#[[:space:]]#}}}*)' ../zinit.zsh ../zinit-side.zsh ../zinit-install.zsh ../zinit-autoload.zsh"


# doc: zinit.zsh zinit-side.zsh zinit-install.zsh zinit-autoload.zsh
# 	export LC_ALL=en_US.UTF-8
# 	zsh -ils -c "zsd -v --scomm --cignore '(\#*FUNCTION:*{{{*|\#[[:space:]]#}}}*)' $<"
#
clean:
	rm -rf *.zwc doc/zsdoc/data zsdoc/*.adoc

.PHONY: all test clean doc doc-container
