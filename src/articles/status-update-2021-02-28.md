---
kind: article
title: Status update, February 2021
created_at: 2021-03-11
excerpt: |
  February is long gone, and I worked mostly on Cyberscore and some consulting gigs.
---

<aside markdown="1">
  If you enjoy my work, consider sponsoring me so I can keep on doing this full
  time: <https://github.com/sponsors/hugopeixoto>
</aside>

Oof, this status update is a *bit* late. Not sure why I've been postponing
writing it, but it's probably because I spent most of the month doing
consulting work instead of open source stuff.


## Cyberscore

Some of the issues on our gitlab project mentioned the notifications page:
missing pagination, overlapping buttons on mobile, notifications not firing on
certain conditions. I started tackling these and ended up rewriting the whole
page and system. This is what it looked like before:

![Screenshot of the old Cyberscore notification page, showing overlapping buttons](/articles/cs-notifications-old.png)


And this is the new notifications page:

![Screenshot of the new Cyberscore notification page, showing read/unread filters](/articles/cs-notifications.png)

Besides the UI rewrite, I also changed the internals. The linked information
was stored in arbitrary fields like `chart_id`, even if they were user ids or
game ids. This was confusing and prevented us from creating foreign keys, so I
added some more columns to the table.

I also rewrote the game chart page. This page still requires some work, because
in some games it's way too wide for mobile, but here's an example of how it
looks like now:

<https://cyberscore.me.uk/chart/396221>

I also fixed a bunch of small bugs. The issue tracker is now under 100 issues!
We also closed a bunch of old features that we probably won't tackle anytime
soon, so we're down to 86 issues.

I'm currently working on ensuring that the scoreboards are correctly
calculated. There were some bugs that causes scoreboards inconsistencies
between different pages.

I also improved the time to rebuild the caches (again). I had worked on
optimizing the game scoreboard caches, but this time went even further. These
are the current times:

- 13 minutes to rebuild every chart cache
- 5 minutes to rebuild every game scoreboard cache
- 10 seconds to rebuild every global scoreboard cache

This means we can do a full site rebuild in less than 20 minutes, while before
it took hours. I'll probably issue a full rebuild this week, since there are
some charts that are probably using an old formula.


## HedgeDoc

I did some maintainer work on this, but nothing big. Mostly readme updates and
reviewing existing PRs:

- <https://github.com/hedgedoc/container/pull/161>
- <https://github.com/hedgedoc/container/pull/159>

There's currently some discussion going on regarding the structure of the
container repository, and whether or not it should be merged with the backend
repo:

- <https://github.com/hedgedoc/container/issues/160>

## Token.io consulting gig

I had to spend some time in February fixing bugs and deploying this to
production. It's now over.


## ink! upgradeability gig

I started working on this during February. I wrote a small [post on my
experience setting up the development environment][hp-ink], and I have a
template kind of working at
<https://github.com/trustfractal/ink-upgrade-template>. This week I'll start
cleaning it up, figure out how to handle authorization and write a post on how
to add upgradeability to your ink! contract, with all the caveats.


<aside markdown="1">
  If you enjoy my work, consider sponsoring me so I can keep on doing this full
  time: <https://github.com/sponsors/hugopeixoto>
</aside>

[hp-ink]: /articles/setting-up-an-ink-development-environment.html
