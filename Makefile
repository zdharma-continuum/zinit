all: zplugin.zsh.zwc zplugin-side.zsh.zwc zplugin-install.zsh.zwc zplugin-autoload.zsh.zwc

%.zwc : %
	doc/zcompile $<

doc: zplugin.zsh zplugin-side.zsh zplugin-install.zsh zplugin-autoload.zsh
	rm -rf zsdoc/data zsdoc/*.adoc
	zsd -v --cignore '(\#*FUNCTION:*{{{*|\#[[:space:]]#}}}*)' zplugin.zsh zplugin-side.zsh zplugin-install.zsh zplugin-autoload.zsh

clean:
	rm -f zplugin.zsh.zwc zplugin-side.zsh.zwc zplugin-install.zsh.zwc zplugin-autoload.zsh.zwc
	rm -rf zsdoc/data

.PHONY: clean
# vim:noet:sts=8:ts=8
