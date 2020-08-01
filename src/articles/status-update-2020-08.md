---
kind: article
title: Status update, July 2020
created_at: 2020-08-01
---

Time for a new monthly update.

I started accepting sponsors via github:

<https://github.com/sponsors/hugopeixoto>

If you enjoy my work, consider sponsoring me so I can keep on doing this full time.

After [some tribulations](/articles/portuguese-vps-providers.html), I decided
on a local VPS provider for the Mentorados project. I used
[dokku](https://github.com/dokku/dokku/) to create a space where the rails
application could be easily deployed. I ended up diving into their codebase and
making a few contributions:

- [viewdocs: Add tests to the frontmatter support feature](https://github.com/progrium/viewdocs/pull/5://github.com/progrium/viewdocs/pull/57)
- [dokku: Delete dokkurc recursively during uninstall](https://github.com/dokku/dokku/pull/4055)
- [dokku: Install sudo when installing from source](https://github.com/dokku/dokku/pull/4057)
- [dokku: Ensure web installer creates files with correct permissions](https://github.com/dokku/dokku/pull/4058)
- [dokku: Rewrite upgrade instructions](https://github.com/dokku/dokku/pull/4062)
- [dokku: documenting behavior of VHOST and HOSTNAME](https://github.com/dokku/dokku/issues/1558#issuecomment-659149054)

I have a few more dokku related contributions in the works / pending review:

- [viewdocs: Enable path based routing](https://github.com/progrium/viewdocs/pull/56)
- [dokku: Stop using VHOST when listing app domains and urls](https://github.com/dokku/dokku/pull/4080)
- [dokku: Remove web installer](https://github.com/dokku/dokku/pull/4079)

I edited and published two episodes of the podcast [Conversas em Código (portuguese)](https://conversas.porto.codes):

- [Aventuras no TypeScript (portuguese)](https://conversas.porto.codes/episodes/aventuras-no-typescript)
- [Enferrujados (portuguese)](https://conversas.porto.codes/episodes/enferrujados)

I looked for free software self hosted alternatives to
[simplecast.fm](https://simplecast.fm). Handling analytics seems to be the
biggest challenge. They work by tracking the audio file HTTP requests. There's
a [set of
guidelines](https://www.iab.com/guidelines/podcast-measurement-guidelines/) by
the [Interactive Advertising
Bureau](https://en.wikipedia.org/wiki/Interactive_Advertising_Bureau). This
might be relevant if we ever decide to take on sponsors.

I didn't migrate anything yet, but I did end up doing a couple of minor
contributions related to this:

- [open-podcast-analytics: Fix markdown typo](https://github.com/backtracks/open-podcast-analytics/pull/3)
- [adistancia.ansol.org: Add podcast publishing platforms (portuguese)](https://gitlab.com/ubuntu-pt/open-edu/-/issues/13)

I went through my pending pull requests to try to push them forward. I rewrote
a rails PR from 2016:

- [rails: Add config.action_dispatch.cookies_default_options](https://github.com/rails/rails/pull/39827)

I'm not sure how or if I'll get that merged.

[Back in may](/articles/2020-05-03.html), I started working on cleaning up my web server. I took inventory of what's hosted there. Now, I started working on automating the nginx configurations and static website builds:

- <https://github.com/hugopeixoto/static-websites>

One of the websites I'm hosting is
[vasteroids](https://vasteroids.lifeonmars.pt). I noticed that the build was
taking too long, so I decided to update its dependencies. This caused a
dependency vulnerability warning coming from `debug`, which I traced to A-Frame
using an outdated fork. I updated the fork, let's see if it gets traction:

- [aframe: Security vulnerability in 'debug' dependency](https://github.com/aframevr/aframe/issues/4612)

Back in 2016, [I submitted a fix to
git-crypt](https://github.com/AGWA/git-crypt/pull/162). I got some feedback
this week, and I'm testing the new solution by the author.

I spent some time working with [D3](https://direitosdigitais.pt) to find and
organize some information regarding contact tracing applications. I'm also
contributing to the [My data done right](https://www.mydatadoneright.eu/)
project, but there's still not much to see.

I migrated all of the [Make or Break](https://makeorbreak.io) websites to my
webserver. We have an API in elixir, so we were using a Digital Ocean droplet
to host everything. Since we don't need the backend until we start accepting
registrations for the next edition, I saved some money by destroying the
droplet and using my own webserver to host the static websites.

I've been working on the [Cyberscore](https://www.cyberscore.me.uk/) codebase,
trying to optimize some background processes. I've reduced the running time
from 10 minutes to 30 seconds, but ensuring that nothing's broken is taking its
time.

I had to do some admin work for [Life on Mars](https://lifeonmars.pt). I've
resumed the use of [plain text accounting](https://plaintextaccounting.org/) to
keep track of things.
