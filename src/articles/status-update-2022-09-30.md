---
kind: article
title: Status update, September 2022
created_at: 2022-10-02
excerpt: |
    This month I was mostly focused on organizing events. I was the AV team for
    a conference in Lisbon and the organizer of another one in Porto.
---

<aside markdown="1">
  If you enjoy my work, consider sponsoring me so I can keep on doing this full
  time: <https://github.com/sponsors/hugopeixoto>
</aside>

This month I was mostly focused on organizing events. I was the AV team for a
conference in Lisbon and the organizer of another one in Porto.


## ANSOL

I organized an event celebrating [Software Freedom Day 2022][sfd]. This
included finding speakers, designing the poster, finding and booking a dining
place, spreading the word, and recording and editing the videos. The
presentations are now [available online][sfd2022].

Our [member management platform][saucy] is ready to be deployed. It now
includes a task that imports data from a custom CiviCRM dump, so the only thing
that we need to do is enable saucy and disable CiviCRM. Our ansible repository
needed some changes so I took the time to redesign our LXD saucy container.

We have the opportunity to prepare a document for the [2022 OGP Europe Regional
Meeting][ogp2022europe]. We only have a week or so to prepare, so it's kind of
tight. I'll probably be focusing on that this week.


## Cyberscore

Cyberscore has a feature where you upload a bunch of screenshots and it
automatically scans the images for high scores. This saves players a lot of
time when submitting to games with tons of charts. 

This feature is implemented as a bunch of javascript and a [WASM rust
module][auto-proof] that does the actual image detection. I'm not super happy
with the state of things, so I've been working on redesigning most of it. One
important thing is having some feedback when the module fails to detect any
high scores, so I'm adding a debug mode that displays some logging information
and bounding boxes.  I've also moved from vanilla javascript to
[Preact][preact].

We're having some weird server issues that causes occasional downtime windows.
I still haven't found the cause, but it's likely that it's caused by the cron
jobs that recalculate the scoreboards slowing down. Since the cron job runs
every five minutes, sometimes a new job starts before the last one finishes,
which probably makes things worse.


## Random stuff

Like I mentioned, I volunteered to be the AV team for [GambiConf][gambiconf],
an in-person conference in Lisbon. You can read more about the experience in
[My conference livestreaming setup at GambiConf][gambi].

I've been working with [DevPT][devpt] to start a weekly code challenge
initiative. We'll be using codewars, so we'll be picking some code challenges
from their roster instead of having to design our own. I built a [custom
leaderboard][codewars] for our members. I've also volunteered to setup a FOSS
infrastructure for their meetups to get them off Zoom.


## October plans

It's hacktoberfest again, so I'm planning on organizing an event or two focused
on open source contributions. I'd also like to finish implementing all the base
set cards on my [Pokémon TCG engine][tcg-engine] and start to implement a
graphical interface.


<aside markdown="1">
  If you enjoy my work, consider sponsoring me so I can keep on doing this full
  time: <https://github.com/sponsors/hugopeixoto>
</aside>

[sfd]: https://softwarefreedomday.org/
[sfd2022]: https://viste.pt/w/p/4irPoTqG4bSHPU4JD56TGL
[saucy]: https://git.ansol.org/ansol/saucy
[gambiconf]: https://gambiconf.dev/
[gambi]: /articles/my-conference-livestreaming-setup-at-gambiconf.html
[preact]: https://preactjs.com/
[auto-proof]: https://gitlab.com/cyberscore/auto-proofer
[codewars]: https://github.com/devpt-org/codewars
[ogp2022europe]: https://www.opengovpartnership.org/events/europe-regional-meeting/
[tcg-engine]: https://github.com/hugopeixoto/tcg-engine
[devpt]: https://devpt.co
