---
kind: article
title: Status update, August 2020
created_at: 2020-08-31
excerpt: |
  August is over, time for a new monthly update.
---

> I am accepting sponsors via github: <https://github.com/sponsors/hugopeixoto>
>
> If you enjoy my work, consider sponsoring me so I can keep on doing this full time.

August is over, time for a new monthly update.

I started helping out with the [Cyberscore](https://cyberscore.me.uk) project.
The current version is not free software, but there are plans to open up
version 5. I [wrote about some of the issues I
found](/articles/knee-deep-in-a-lamp-project.html), and recorded a podcast
episode on it as well. I'm currently editing the episode and it should go live
this week. I'm learning [Laravel](https://laravel.com/) to see if it's a good
fit for the new version.

I've also joined [ANSOL](https://ansol.org/) and made some contributions to
<https://github.com/marado/RNID>, a project that monitors failures to comply
with the national open standards regulation. In the process [I found a bug and
submitted a fix to `html-xml-utils`](/articles/html-xml-utils-fix.html). The
fix was released in [version
7.9](https://www.w3.org/Tools/HTML-XML-utils/ChangeLog). I'm trying to get it
packaged by Debian:

- <https://salsa.debian.org/rnaundorf-guest/html-xml-utils/-/merge_requests/2>

My contributions to ANSOL's RNID project (mostly in portuguese):

- [Don't mark `alt=""` as an accessibility error](https://github.com/marado/RNID/pull/65)
- [Starts tracking accessmonitor.accessibilidade.pt](https://github.com/marado/RNID/pull/64)
- [Remove inventarios.pt](https://github.com/marado/RNID/pull/60)
- [Small typo fix](https://github.com/marado/RNID/pull/59)
- [Transcribe RNID legislation to markdown](https://github.com/marado/RNID/pull/54)
- [Another small typo fix](https://github.com/marado/RNID/pull/53)

I also started working on a way to reduce the repetition in these scripts and
make it easier to add new ones. No PR yet, but [there's a
branch](https://github.com/hugopeixoto/RNID/tree/create-framework).

The [veekun / pokedex](http://veekun.com/) project is starting to have some
activity again. The current version uses
[pylons](https://www.pylonsproject.org/) and it doesn't support python 3, so
it's being upgraded to [pyramid](https://trypyramid.com/). I helped porting one
of the sections:

- [Add frontpage](https://github.com/magical/spline-pokedex/pull/1)

The pyramid version is live at <http://beta.veekun.com/>.

During the week from 16 to 23 [Summer Games Done
Quick](https://gamesdonequick.com/) and [Games Made
Quick](https://itch.io/jam/games-made-quick-four-plus) happened and I spent
some time trying to build a game with [bevy](bevyengine.org/), a rust ECS game
engine. I'm working on a blog post detailing what I learned and what I built.

I randomly bumped into some warnings in the [microformats
gem](https://github.com/microformats/microformats-ruby) in ruby 2.7. I
submitted some fixes that were already merged:

- [Fix ruby 2.7 warnings in open()](https://github.com/microformats/microformats-ruby/pull/114)
- [Update ruby versions](https://github.com/microformats/microformats-ruby/pull/115)

I finally got around to finish automating the nginx configuration and
deployment of static websites on my server. I built a small tool:

- <https://github.com/hugopeixoto/static-websites>

It still needs some love if I want to make it usable by someone else, so I
documented those issues in the project's readme.

I also noticed I had broken
[vasteroids](https://github.com/lifeonmarspt/vasteroids) by upgrading aframe to
`1.0.0`, a version that changed a lot of APIs. I spent some time fixing those
issues and the [live version](https://vasteroids.lifeonmars.pt/) should work
fine.
