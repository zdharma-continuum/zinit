all: test

alltest: test testB testC testD testE

test:
	make plugin svn curl general

testB:
	make OPTS="kshglob" plugin svn curl general

testC:
	make OPTS="noextendedglob" plugin svn curl general

testD:
	make OPTS="ksharrays" plugin svn curl general

testE:
	make OPTS="ignoreclosebraces" plugin svn curl general

plugin: test1 test2 test3 test4 test5 test6 test7 test8 test9 test10 \
    	test50 test51

svn: test11 test12 test13 test14 test15 test16 test17 test18 test19 test20 \
     test60

curl: test21 test22 test23 test24 test25 test26 test27 test29 test30 \
      test70

general: test100 test101 test102

prepare: ../zplugin.zsh ../zplugin-side.zsh ../zplugin-install.zsh ../zplugin-autoload.zsh
	cp ../zplugin.zsh ../zplugin-side.zsh ../zplugin-install.zsh ../zplugin-autoload.zsh ../_zplugin ../git-process-output.zsh .
	rm -rf data
	@: ./bin/zsd-transform -q zplugin.zsh zplugin-side.zsh zplugin-install.zsh zplugin-autoload.zsh
	@: mv zsdoc/data .
	@: rm -rf zsdoc
	@: cp ../_zplugin data/functions/zplugin.zsh/
	perl -pi -e 's/command git/internet_mock_git/g' zplugin-install.zsh zplugin-autoload.zsh
	perl -pi -e 's/command svn/internet_mock_svn/g' zplugin-install.zsh
	perl -pi -e 's/command curl/internet_mock_curl/g' zplugin-install.zsh

test%: _test%/script _test%/urlmap _test%/model data
	rm -rf _$@/answer
	./bin/runtest.zsh _$@ "$(VERBOSE)" "$(DEBUG)" "$(OPTDUMP)" "$(EMUL)" "$(OPTS)"
	if [ "$(NODIFF)" = "" -a ! -f _$@/skip ]; then diff -x .git -x .svn -x .test_git -x '*.zwc' -x .model_keep -u -r _$@/model _$@/answer; exit $$?; fi
	@echo

data: ../zplugin.zsh ../zplugin-side.zsh ../zplugin-install.zsh ../zplugin-autoload.zsh ../_zplugin
	make prepare

clean:
	rm -rf -- data zsdoc zplugin.zsh zplugin-side.zsh zplugin-install.zsh zplugin-autoload.zsh _zplugin
	rm -rf _test*/answer _test*/*.txt _test*/skip

.PHONY: all test prepare clean
