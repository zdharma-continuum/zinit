documentation:
	@git checkout documentation || { print RETRYING WITH STASH; git stash; git checkout documentation; }

master:
	@git checkout master || { print RETRYING WITH STASH; git stash; git checkout master; }
