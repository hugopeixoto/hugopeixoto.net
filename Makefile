all:
	bundle exec ruby src/build.rb

deploy: all
	rsync -a build/ git.hugopeixoto.net:/srv/www/hugopeixoto.net/public

draft: all build/rouge.css
	rsync -a build/ git.hugopeixoto.net:/srv/www/draft.hugopeixoto.net/public
