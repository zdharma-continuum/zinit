doc: zplugin.zsh zplugin-side.zsh zplugin-install.zsh zplugin-autoload.zsh
	rm -rf zsdoc/data zsdoc/*.adoc
	zsd -v --cignore '(\#*FUNCTION:*{{{*|\#[[:space:]]#}}}*)' zplugin.zsh zplugin-side.zsh zplugin-install.zsh zplugin-autoload.zsh

# vim:noet:sts=8:ts=8
