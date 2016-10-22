deploy:
	git add --all
	git commit -m "Update"
	git push -u origin master
	hexo generate
	hexo deploy

d:
	git add --all
	git commit -m "Update"
	git push -u origin master
	hexo generate
	hexo deploy
