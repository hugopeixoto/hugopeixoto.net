---
kind: article
title: Status update, June 2021
created_at: 2021-06-30
excerpt: |
  I got F-Zero Central working again, licensed its code under AGPL, and did
  some minor features on Cyberscore. Also, I've been playing Mindustry, you
  should give it a try.
---

<aside markdown="1">
  If you enjoy my work, consider sponsoring me so I can keep on doing this full
  time: <https://github.com/sponsors/hugopeixoto>
</aside>


## F-Zero Central

After bringing the website back up, I worked on making it possible for existing
players to reset their passwords, logging in, and submitting new times.

Time submission took a bit longer than I expected because we have a bunch of
tables that cache several scores and rankings that needed to be recalculated.
This used to be done as a cron job because it took too long to do inline, but I
was able to make it fast enough. It took me a while to understand what each
table represented and to figure out the formulas from the code and FAQ, but it
seems to be working.

Part of the good news is, the code is now licensed under AGPL, and it's
available here:

<https://github.com/fzerocentral/fzerocentral>


## Cyberscore

The most visible thing I did this month was to rewrite the login, registration
and password recovery pages to be mobile friendly. Apart from that, I worked on
improving the way we do html escaping. Some old translation strings were being
stored in escaped form, and some functions like `GetGameName` was also
returning an already escaped string. I normalized the database and moved all
escaping to the html templates. These were all detected thanks to an effort to
translate the website to japanese, given all the influx of New Pokémon Snap
submissions from japanese players.

During fzero's rewrite, I added a migration system. I want to port it to
cyberscore, we've been doing some changes to the database and it's kind of
troublesome to keep everyone in sync without one.


## Personal infrastructure

I have a bunch of HDDs in my desktop that are not encrypted. I started moving
files around to get those disks empty so I can format them, but it's taking
forever. When emptying one disk, I decided to create at least two copies on
different disks to improve my redundancy. This means I need to have a lot of
free space available to move everything around, so this doubles the time it
takes to empty a disk.

Every time I make a new copy, I double check that everything was copied
successfully with a sha1sum:

~~~~
find . -type f -print0 |
  LC_ALL=C sort -z |
  xargs -0 sha1sum |
  tee ../shasums.txt |
  sha1sum
~~~~

I never detected any issues when copying files between two disks on the same
machine, but one of my larger disks is in another computer in the network, so
some of the files are being transfered via rsync. I transferred 2.4 TB in one go,
and the checksums didn't match. There were differences in three files, of sizes
8 GB, 93 GB, and 256 GB.

I was curious to know how many bits were corrupted, but I didn't want to make a
trivial diff over the network, since it would require copying all those
gigabytes, so I ended up writing a rust cli tool that would find the
differences between the two using a merkle tree to detect where the errors
were. You can find the source code of `netdiff` here:

<https://github.com/hugopeixoto/netdiff/>

Using this tool, I found that the files had, respectively, 1 bit flip, 2 bit
flips, 4 bit flips. I could just flip those bits to fix the issue, but I'll
rsync those files again instead.


## Other stuff

I accidentally discovered [Mindustry](https://mindustrygame.github.io/) while
browsing F-Droid for games. It looks great, it's GPLv3, and I already played it
for more hours than I should. I kind of want to play with setting up a
multiplayer server and playing it on the desktop instead, but it's probably
better if it stays contained in my phone.


<aside markdown="1">
  If you enjoy my work, consider sponsoring me so I can keep on doing this full
  time: <https://github.com/sponsors/hugopeixoto>
</aside>
