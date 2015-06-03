---
kind: article
title: Web services in go
created_at: 2015-01-31
excerpt:
  I've been writing quite a few different web services in my current job. I'm
  going to talk a bit about my experience writing go web services.

---
I've been writing quite a few different web services in my current job.
Initially, they were all written in rails. As we shift towards a microservices
/ services oriented / whatchamacallit architecture, I've started experimenting
with other languages.

Right now we have about 12 services, half of which are ruby (rails or sinatra),
with the other half being written in go. I'm going to talk a bit about my
experience writing go web services.


Configuration
-------------

In our rails applications, we have our configurations in yaml files, in the
`config` directory. Database credentials live in `config/database.yml`, mailer
options in the `config/mailer.yml`, and so forth. These do not live in the code
repository, but instead are created the first time each service is deployed to
a server.

To maintain some consistency between services, I would like to have something
similar across web services. However, the previous approach posed some problems.

First, go does not have a yaml parser implementation right of the bat, as will
probably be the case for most languages. There are some packages for it
([go-yaml](https://github.com/go-yaml/yaml),
[go-gypsy](https://github.com/kylelemons/go-gypsy)), but looking for the right
implementation every time we try a new language seems more trouble than it is
worth. JSON, on the other hand, is widely supported. Rust, nodejs, go, and PHP
all have native json capabilities, and none of them has yaml support.

Second, having everything in its own file makes it a bit harder to deploy.
Ideally, I'd like to have some sort of central configuration system, like
[etcd](https://github.com/coreos/etcd), from which each service fetches its
configuration periodically, or with some kind of notification system. In this
kind of setup, it makes little sense having configuration spread over multiple
files. Instead, I opted for a single file, `config/settings.json`.

Eventually, I'd like to replace rails configuration yaml files with a single
json file as well.

Deployment
----------

The first question here was deciding wether we should compile the binaries on
the server or on the development machine. There are a couple of drawbacks to
each approach.

Compiling on the server requires a go compiler on every server, with the code
being compiled once per server.

Compiling on the development machine would require a cross compilation
toolchain, since our development machines are all macs and the servers are all
running linux.

I opted for the first option. It seemed less troublesome at the time, and it
kind of matches our ruby deployments, as in ruby the full source code gets
deployed to the server.

We try to make deployment as homogeneous as possible, so we turned to
capistrano as our deployment tool. It's our tool of choice when deploying ruby
services, so we saw no reason to use anything else.

Here's a sample deploy.rb file:

~~~~
set :application, 'binfo'
set :repo_url, 'company.com:web/binfo.git'

set :deploy_to, '/path/to/app'
set :scm, :git

set :ssh_options, { forward_agent: true }
set :default_env, { path: "/usr/local/go/bin:$PATH" }

set :linked_files, %w{ config/settings.json }

set :service, 'service nlife-binfo'

namespace :go do
  desc 'Build go application'
  task :build do
    on roles(:app), in: :sequence, wait: 5 do
      within release_path do
        with gopath: release_path do
          execute :sh, 'build.sh'
        end
      end
    end
  end
end

namespace :deploy do

  desc 'Restart application'
  task :restart do
    on roles(:app), in: :sequence, wait: 5 do
      sudo fetch(:service), :restart
    end
  end

  after :publishing, :restart
  after :finishing, 'deploy:cleanup'
  after :updated, 'go:build'
end
~~~~

You'll notice that I'm using `service nlife-binfo restart` to restart the
webservice.  Usually we deploy services to ubuntu, so we use upstart scripts to
manage the service lifetime.

Upstart scripts are relatively simple (although this will probably have to be
migrated to systemd once it replaces upstart, but that should take a while).
Here's a sample script:

~~~~
description "nlife binfo service"

start on (local-filesystems and runlevel [2345])
stop on runlevel [06]

setuid binfo-runner
setgid binfo-runner

chdir /path/to/app/current

exec bin/binfo
~~~~

In the future, I'd like to give [goagain](https://github.com/rcrowley/goagain)
a try. Its goal is to avoid downtime while the service is reloading.  It
requires rewriting most of the http server code, or combining it with
[manners](https://github.com/braintree/manners). This work has been done by
other developers, in [mannersagain](https://github.com/cupcake/mannersagain).

With this in play, the capistrano recipe would need to be changed to reload the
service instead of restarting it, and no requests would be dropped.
