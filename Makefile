doc: zplugin.zsh zplugin-side.zsh zplugin-install.zsh zplugin-autoload.zsh
	rm -rf zsdoc
	zsd -v --cignore '\#*FUNCTION:*{{{*' zplugin.zsh zplugin-side.zsh zplugin-install.zsh zplugin-autoload.zsh
