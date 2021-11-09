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

general: test100 test101 test102 test104

prepare: ../zinit.zsh ../zinit-side.zsh ../zinit-install.zsh ../zinit-autoload.zsh
	cp ../zinit.zsh ../zinit-side.zsh ../zinit-install.zsh ../zinit-autoload.zsh ../_zinit ../git-process-output.zsh .
	rm -rf data
	@: ./bin/zsd-transform -q zinit.zsh zinit-side.zsh zinit-install.zsh zinit-autoload.zsh
	@: mv doc/zsdoc/data .
	@: rm -rf doc/zsdoc
	@: cp ../_zinit data/functions/zinit.zsh/
	perl -pi -e 's/command git/internet_mock_git/g' zinit-install.zsh zinit-autoload.zsh
	perl -pi -e 's/command svn/internet_mock_svn/g' zinit-install.zsh
	perl -pi -e 's/command curl/internet_mock_curl/g' zinit-install.zsh

test%: _test%/script _test%/urlmap _test%/model data
	rm -rf _$@/answer
	./bin/runtest.zsh _$@ "$(VERBOSE)" "$(DEBUG)" "$(OPTDUMP)" "$(EMUL)" "$(OPTS)"
	if [ "$(NODIFF)" = "" -a ! -f _$@/skip ]; then diff -x .git -x .svn -x .test_git -x '*.zwc' -x .model_keep -x polaris -u -r _$@/model _$@/answer; exit $$?; fi
	@echo

data: ../zinit.zsh ../zinit-side.zsh ../zinit-install.zsh ../zinit-autoload.zsh ../_zinit
	make prepare

clean:
	rm -rf -- data zsdoc zinit.zsh zinit-side.zsh zinit-install.zsh zinit-autoload.zsh _zinit
	rm -rf _test*/answer _test*/*.txt _test*/skip

.PHONY: all test prepare clean
