---
title: Ubuntu, rvm and contributing to rails
created_at: 2009-09-13
---

I wanted to write a couple of patches for the rails gem, so I needed to clone
the rails repository and install all the gem dependencies with bundler.
Unfortunately, my bundler installation doesn't work very well, as I screwed
something up when installing several versions of ruby. So I decided to create a
virtual machine with *Ubuntu* and install everything with *rvm*. I'll describe
all the steps I took after the VM installation. I used Ubuntu 10.04.1 LTS, so
your mileage may vary.

## Initial setup

I started by installing the ssh server. This step is completely unrelated to
the ruby business, but it allowed me to connect to the server from my laptop

~~~~ bash
hugopeixoto@ruby$ sudo aptitude install ssh
~~~~

Then, I installed a couple of packages that rvm will need.

* bash (it was obviously already installed),
* curl and
* git-core.

~~~~ bash
hugopeixoto@ruby$ sudo aptitude install bash curl git-core
~~~~

## rvm installation

To install rvm, I decided to go with a system-wide installation. This makes the
rubies available to all the users instead of just the one used in the
installation process. To do this, I just needed to execute their system-wide
installation script.

~~~~ bash
hugopeixoto@ruby$ sudo su -
root@ruby# bash < <( curl -L http://bit.ly/rvm-install-system-wide )
~~~~

Now that it is installed, there were a couple of extra steps I had to take to
be able to install the rubies. First, there are some required packages so that
the rubies can be installed from source. Additionally, rvm must be loaded when
your shell launches so that you can use the rvm commands. The two following
commands were ran as root:

~~~~ bash
hugopeixoto@ruby$ sudo su -
root@ruby# aptitude install build-essential bison openssl \
           libreadline6 libreadline6-dev curl git-core zlib1g \
           zlib1g-dev libssl-dev libyaml-dev libsqlite3-0 \
           libsqlite3-dev sqlite3 libxml2-dev libxslt-dev \
           autoconf libc6-dev
root@ruby# echo '[[ -s "/usr/local/lib/rvm" ]] && source "/usr/local/lib/rvm"' > /etc/profile.d/rvm.sh
~~~~

After doing that, you are ready to install any version of ruby and using it.
For example, say you want to have ruby 1.8.7, 1.9.1 and 1.9.2 and that you want
to use, for now, 1.9.1. Just type:

~~~~ bash
root@ruby# rvm install 1.8.7
root@ruby# rvm install 1.9.1
root@ruby# rvm install 1.9.2
root@ruby# rvm 1.9.1
~~~~

And you're done. If you want to install rails, now, just type:

~~~~ bash
root@ruby# gem install rails
~~~~

## Contributing to rails

In order to make modifications to the rails source code and run the tests, you
want to check out the lastest version of rails. This can be pulled from their
git repository:

~~~~ bash
hugopeixoto@ruby$ git clone git@github.com:rails/rails.git
~~~~

You also need to install additional gems and system libraries. All the gems
required to test rails can be installed using the bundler gem:

~~~~ bash
hugopeixoto@ruby$ gem install bundler
~~~~

You can decide if you want to test mysql and postgresql. If you don't, just run

~~~~ bash
hugopeixoto@ruby$ sudo aptitude install libxslt-dev
hugopeixoto@ruby$ cd rails
hugopeixoto@ruby:~/rails$ bundle install --without db
~~~~

Otherwise, you need to install the databases and their client development packages:

~~~~ bash
hugopeixoto@ruby$ sudo aptitude install libxslt-dev libmysqlclient-dev libpq-dev
hugopeixoto@ruby$ cd rails
hugopeixoto@ruby:~/rails$ bundle install --without db
~~~~

Note that installing and configuring both mysql and postgresql servers is not
covered here. View the [rails guide on
contributing](http://edgeguides.rubyonrails.org/contributing_to_rails.html#testing-active-record)
for more details on this.

This is pretty much it! Now you just need to make your changes, and run the
tests to see if anything is broken:

~~~~ bash
hugopeixoto@ruby:~/rails$ rake test
~~~~
