---
kind: article
title: Status update, May 2021
created_at: 2021-06-01
excerpt: |
  Having finished moving, I was able to focus on my tech things again. I worked a
  lot on [Cyberscore](https://cyberscore.me.uk), and I think I accidentally
  became part of the development team of [F-Zero Central](https://fzerocentral.org).
---

<aside markdown="1">
  If you enjoy my work, consider sponsoring me so I can keep on doing this full
  time: <https://github.com/sponsors/hugopeixoto>
</aside>

Having finished moving, I was able to focus on my tech things again. I worked a
lot on cyberscore, and I think I accidentally became part of the development
team of [F-Zero Central](https://fzerocentral.org).


## F-Zero Central

After last month's hack, I started rewriting the website, decoupling the
scoreboards from the phpbb codebase. I wrote [a blog post on the differences
between Cyberscore and F-Zero Central](/articles/tale-of-two-sites.html) if
you're looking for more information on that.

For now, everything is read only and there's no forum, but at least there's
something online: [F-Zero Central](https://fzerocentral.org/).

I'm currently working on adding login support. I'd like to enable submitting
scores ASAP to get people using the website again. Since this codebase was
written mostly from scratch, it can probably be open sourced without any fears
of leaking hardcoded passwords or exposing a bunch of vulnerabilities.


## Cyberscore

After getting something online in FZC, I felt more comfortable working on
Cyberscore again. I rewrote some more pages and deleted a bunch of code:

~~~~
$ git diff master@{"1 month ago"} --shortstat
 134 files changed, 5403 insertions(+), 13021 deletions(-)
~~~~

Most of the deletions come from the rewritten comment system. It had 6 nested
loops with a bunch of duplicated markdown in each of them just so we could
render six levels of replies. Then, the whole thing was copy pasted around
everywhere we had comments (user profiles, news articles, blog posts, game
requests).

I also deleted some developer tools like a builtin SQL explorer. It was useful
sometimes, but it was thanks to that that the whole database got deleted, the
last time. I don't think these tools belong in a codebase in this state.

I've also improved the mobile experience. The header and footer of every page
are now responsive, and the homepage was also redesigned.

As for the plans to open source this codebase, I'm pretty confident that there
are a bunch of vulnerabilities on the website &mdash; SQL injection, mass
assignment-like problems, missing authorization checks, etc &mdash; that I was
trying to fix before releasing the code, but there's still so much to go. I've
converted around 8k lines of code, but the `/public/` directory still has 22k
lines that need converting.


## Personal infrastructure

Now that I've moved to a new apartment, I've started using my desktop computers
again. I don't want to deal with wifi for these devices, so I needed to get
some ethernet cables. Instead of getting a bunch of different sized ones, I got
a 25 meter one and started crimping some custom cables.

![
Two pictures: First, a Cat6 cable without shielding on the tip, with the eight
colored wires spreading out. Second, the same cable with a connector head
installed
](/articles/crimping-cables.jpg){:id="crimping"}

It was the first time I did this, so it took me a while to get used to it. I
used [`iperf`][iperf] to make sure that the cable was working OK. Not sure what
else to test tbh, if the bandwidth is close to gigabit, I guess it's fine?

I've also installed a pair of [shucked][shucking] 12TB hard drives that I
bought a year ago (before the price hike, thankfully). The only disks that I
tended to encrypt were the main OS ones, not the extra ones where I keep random
files. I'm currently changing this and encrypting every hard disk I have. It's
a whole process, because I have to move files around so I can scrub and
reformat every disk.

Another thing I started doing was running [syncthing][syncthing] on my phone
and on my desktop, so I could sync the pictures I take there automatically.
I've set the desktop folder to be receive only and to [ignore
deletions][ignoredelete], so I can free space from my phone knowing that I have
a copy of the pictures somewhere else.

I have a second computer around that I used to use for backups, but it was
shutdown for a couple of years. I finally managed to turn it back on again and
update everything. I had to ship the debian GPG keys from my laptop there, it
was so old that the keys it had were expired. I'm looking into installing
[restic][restic] on it so I can automate offsite backups of Cyberscore and
F-Zero Central.



<aside markdown="1">
  If you enjoy my work, consider sponsoring me so I can keep on doing this full
  time: <https://github.com/sponsors/hugopeixoto>
</aside>

[iperf]: https://manpages.debian.org/testing/iperf/iperf.1.en.html
[shucking]: https://en.wikipedia.org/wiki/Disk_enclosure#Hard_drive_shucking
[ignoredelete]: https://docs.syncthing.net/advanced/folder-ignoredelete.html
[restic]: https://restic.net/
[syncthing]: https://syncthing.net/
