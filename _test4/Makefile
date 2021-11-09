current_dir = $(notdir $(shell pwd))

test: script urlmap model ../data
	rm -rf answer
	cd .. && ./bin/runtest.zsh $(current_dir) "$(VERBOSE)" "$(DEBUG)" "$(OPTDUMP)" "$(EMUL)" "$(OPTS)"
	if [ "$(NODIFF)" = "" -a ! -f skip ]; then cd ..; diff -x .git -x .test_git -x '*.zwc' -x _zinit -x .model_keep -u -r $(current_dir)/model $(current_dir)/answer; exit $$?; fi
	@echo

test%: ../_test%/script ../_test%/urlmap ../_test%/model ../data
	rm -rf answer
	cd .. && ./bin/runtest.zsh _$@ "$(VERBOSE)" "$(DEBUG)" "$(OPTDUMP)" "$(EMUL)" "$(OPTS)"
	if [ "$(NODIFF)" = "" -a ! -f skip ]; then cd ..; diff -x .git -x .test_git -x '*.zwc' -x _zinit -x .model_keep -u -r _$@/model _$@/answer; exit $$?; fi
	@echo

../data: ../../zinit.zsh ../../zinit-side.zsh ../../zinit-install.zsh ../../zinit-autoload.zsh ../../_zinit
	make -C .. prepare

clean:
	rm -rf answer
	rm -f *.txt

.PHONY: test clean
