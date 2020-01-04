all:
	bundle exec ruby src/build.rb

build/rouge.css:
	bundle exec rougify style github > build/rouge.css

deploy: all build/rouge.css
	rsync -a build/ git.hugopeixoto.net:/srv/www/hugopeixoto.net/public
