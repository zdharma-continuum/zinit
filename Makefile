all: zplugin.zsh.zwc zplugin-side.zsh.zwc zplugin-install.zsh.zwc zplugin-autoload.zsh.zwc

%.zwc: %
	doc/zcompile $<

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

doc: zplugin.zsh zplugin-side.zsh zplugin-install.zsh zplugin-autoload.zsh
	rm -rf zsdoc/data zsdoc/*.adoc
	zsd -v --scomm --cignore '(\#*FUNCTION:*{{{*|\#[[:space:]]#}}}*)' zplugin.zsh zplugin-side.zsh zplugin-install.zsh zplugin-autoload.zsh

clean:
	rm -f zplugin.zsh.zwc zplugin-side.zsh.zwc zplugin-install.zsh.zwc zplugin-autoload.zsh.zwc
	rm -rf zsdoc/data

.PHONY: all test clean doc
# vim:noet:sts=8:ts=8
