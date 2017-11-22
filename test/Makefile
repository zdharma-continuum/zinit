all: test

test: test1 test2 test3 test4 test5 test6 test7 test8 test9 \
    	test11 test12 test13 test14

prepare: ../zplugin.zsh ../zplugin-side.zsh ../zplugin-install.zsh ../zplugin-autoload.zsh
	cp ../zplugin.zsh ../zplugin-side.zsh ../zplugin-install.zsh ../zplugin-autoload.zsh ../_zplugin .
	rm -rf data
	./bin/zsd-transform -q zplugin.zsh zplugin-side.zsh zplugin-install.zsh zplugin-autoload.zsh
	mv zsdoc/data .
	rm -rf zsdoc
	cp ../_zplugin data/functions/zplugin.zsh/
	perl -pi -e 's/command git/internet_mock_git/g' zplugin-install.zsh zplugin-autoload.zsh
	perl -pi -e 's/command svn/internet_mock_svn/g' zplugin-install.zsh

test%: _test%/script _test%/urlmap _test%/model data
	rm -rf _$@/answer
	./bin/runtest.zsh _$@ "$(VERBOSE)" "$(DEBUG)" "$(OPTDUMP)" "$(EMUL)"
	if [ "$(NODIFF)" = "" -a ! -f _$@/skip ]; then diff -x .git -x .svn -x .test_git -x '*.zwc' -x .model_keep -u -r _$@/model _$@/answer; exit $$?; fi
	@echo

data: ../zplugin.zsh ../zplugin-side.zsh ../zplugin-install.zsh ../zplugin-autoload.zsh ../_zplugin
	make prepare

clean:
	rm -rf -- data zsdoc zplugin.zsh zplugin-side.zsh zplugin-install.zsh zplugin-autoload.zsh _zplugin
	rm -rf _test*/answer _test*/*.txt _test*/skip

.PHONY: all test prepare clean
