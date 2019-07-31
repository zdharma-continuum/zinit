documentation:
	@git checkout documentation || { echo RETRYING WITH STASH; git stash; git checkout documentation; }

master:
	@git checkout master || { echo RETRYING WITH STASH; git stash; git checkout master; }
