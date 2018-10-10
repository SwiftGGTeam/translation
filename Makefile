sync: 
	git fetch upstream
	git checkout master
	git merge upstream/master

upstream:
	git remote add upstream https://github.com/SwiftGGTeam/translation.git 

