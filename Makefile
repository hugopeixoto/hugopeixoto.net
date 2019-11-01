all:
	ruby src/build.rb

deploy: all
	rsync -a build/ git.hugopeixoto.net:/srv/www/hugopeixoto.net/public
