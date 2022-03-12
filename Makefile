all: zinit.zsh.zwc zinit-side.zsh.zwc zinit-install.zsh.zwc zinit-autoload.zsh.zwc

%.zwc: %
	scripts/zcompile $<

alltest: test testB testC testD testE

test:
	make VERBOSE=$(VERBOSE) NODIFF=$(NODIFF) DEBUG=$(DEBUG) OPTDUMP=$(OPTDUMP) OPTS=$(OPTS) -C test test

testB:
	make VERBOSE=$(VERBOSE) NODIFF=$(NODIFF) DEBUG=$(DEBUG) OPTDUMP=$(OPTDUMP) OPTS="kshglob" -C test test

testC:
	make VERBOSE=$(VERBOSE) NODIFF=$(NODIFF) DEBUG=$(DEBUG) OPTDUMP=$(OPTDUMP) OPTS="noextendedglob" -C test test

testD:
	make VERBOSE=$(VERBOSE) NODIFF=$(NODIFF) DEBUG=$(DEBUG) OPTDUMP=$(OPTDUMP) OPTS="ksharrays" -C test test

testE:
	make VERBOSE=$(VERBOSE) NODIFF=$(NODIFF) DEBUG=$(DEBUG) OPTDUMP=$(OPTDUMP) OPTS="ignoreclosebraces" -C test test

# Set LC_ALL to avoid having to deal with different locales.
# The generated .adoc files will differ in sorting and or unicode char encoding.
# LC_ALL=C is sadly not an option here since it results in incorrect char
# encoding in some of the files created by zsd.
doc: export LC_ALL=en_US.UTF-8
doc: zinit.zsh zinit-side.zsh zinit-install.zsh zinit-autoload.zsh
	rm -rf doc/zsdoc/data doc/zsdoc/*.adoc
	# cd is required since zsd outputs to PWD/zsdoc/
	cd doc; zsd -v --scomm --cignore '(\#*FUNCTION:*{{{*|\#[[:space:]]#}}}*)' ../zinit.zsh ../zinit-side.zsh ../zinit-install.zsh ../zinit-autoload.zsh

IMAGE_ID_PATH := $(PWD)/doc/docker/image-id

doc-docker-image:
	cd doc/docker && docker build --rm --iidfile ${IMAGE_ID_PATH}  .

doc-in-docker:
	docker image inspect \
		$$([[ -f ${IMAGE_ID_PATH} ]] && cat ${IMAGE_ID_PATH}) \
		>/dev/null 2>&1 || \
		$(MAKE) doc-docker-image
	cat ${IMAGE_ID_PATH} | xargs docker run --rm -v $(PWD):/zinit.git

clean:
	rm -f zinit.zsh.zwc zinit-side.zsh.zwc zinit-install.zsh.zwc zinit-autoload.zsh.zwc
	rm -rf doc/zsdoc/data

.PHONY: all test clean doc doc-in-docker doc-docker-image
# vim:noet:sts=8:ts=8
