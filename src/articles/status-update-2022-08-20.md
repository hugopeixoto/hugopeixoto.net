---
kind: article
title: Status update, July and August 2022
created_at: 2022-08-20
excerpt: |
  Cyberscore is now Free Software; ANSOL is organizing a Software Freedom Day
  event; I installed a bunch of Linux distros on my computers; and finally, I
  started yet another Pokémon project.
---

<aside markdown="1">
  If you enjoy my work, consider sponsoring me so I can keep on doing this full
  time: <https://github.com/sponsors/hugopeixoto>
</aside>

I'm grouping together July and August, since July was mostly hyper-focusing on
a new silly project.


## Cyberscore

Big news: Cyberscore is now Free Software!

During August, I finally took the final steps to open source the project's
codebase: resetting all the passwords and hardening the server a bit. We have
some passwords in the git history, so instead of messing with
`git-filter-branch`, I rotated everything. We were also using mysql's root
username/password for everything: the website, forums, and other side projects.
Now we have a user per project, limited to their own database. There were some
old CPanel mysql users from the previous webhost still in there, so I removed
them as well. Our phpmyadmin by is now limited to being accessed from a
specific IP address, and I uninstalled some random services we had from older
experiences.

The codebase is now available at <https://gitlab.com/cyberscore/cyberscore>


## ANSOL

We're almost done with migrating away from [CiviCRM](https://civicrm.org) to
[saucy](https://git.ansol.org/ansol/saucy). Timings were right and [Gitea 1.17
was released](https://blog.gitea.io/2022/07/gitea-1.17.0-is-released/),
allowing us to self-host the container image using the new Package Registry
feature. I'm still working on the data migration scripts, but we should fully
migrate in the next couple of weeks.

We're also planning a meetup/event to celebrate [Software Freedom
Day](https://www.softwarefreedomday.org/). It'll be in Porto on the 17th of
September. We haven't publicly announced it yet, but we already have a couple
of talks lined up.


## Personal Infrastructure

These last two months have been full of hardware updates.

I needed to be away from my desk for a few days, and my XPS 13 isn't in great
shape (problem registering keystrokes), so I needed a replacement laptop. I
grabbed a 2015 macbook pro that I had lying around from my [old
company](https://lifeonmars.pt)'s inventory and took it with me without even
trying to boot it. When I sat down and tried to use it, it failed to detect the
boot partition. I tried to reinstall Mac OS using their built-in internet
recovery thing, but had no success, so I grabbed a USB flash drive, asked
someone to put a Fedora installer in there, and installed Fedora 36 on the Mac.

Not everything works: Bluetooth crashes, resuming after closing the lid takes
around 10 minutes, and it doesn't have drivers for the webcam, but it's good
enough to work on my projects while away from home.

I'm doing the live streaming and recording for [GambiConf
EU](https://gambiconf.dev/), an in-person conference in September, so I ordered
some PC components for a OBS streaming build. I ended up with a mini-ITX board
with a Ryzen 5600G. I wasn't sure what distro to use, so at first I used the
same Fedora Live CD I used on the mbp to test it out. I had to do some
shenanigans to enable every flatpak from flathub to be able to install OBS, and
I wasn't really feeling it, so I switched to something else.

The next candidate was Arch Linux. I didn't really feel like spending the time
I thought it would take to get to a working system a DE and OBS working, so I
went with Manjaro instead. It took me a while to get used to `pacman` and
understanding `makepkg`'s output, but I managed to get `obs-studio-browser`
working.

After installing two new Linux distros, I was in the mood to keep trying new
things, so I grabbed the Nexus 5 that a friend had gifted me earlier this year
and installed Ubuntu Touch. The installation process was alright (I used
[UBports installer](https://devices.ubuntu-touch.io/installer/)), but I'm not
sure what to do with it now. The battery is practically dead, and the
FluffyChat version available is too old to support encrypted chats. I was a bit
sad that I couldn't `apt install` things; maybe there's a way, but I haven't
figured it out yet.


## Pokémon TCG engine

In June, I started a new silly project. I was browsing Pokémon TCG Live's
subreddit, and all the complaints about weird bugs led to me searching for
unofficial implementations. I found [TCG ONE](https://tcgone.net), which is
partially free software. They have most of the cards implementation in an
Apache licensed repository, but the engine that it relies on is closed source.
I spent the following weeks working on my own engine. I didn't go far yet, but
you can check out my progress on <https://github.com/hugopeixoto/tcg-engine>.

The scope of this project is too big for anyone to tackle in a couple of weeks,
but I like the challenge of figuring out how to structure the code in a way
that new cards and their effects can easily be added. I don't expect to get
this to a completed state, but I want to at least be able to play some games,
even if it's against myself via the command line.


<aside markdown="1">
  If you enjoy my work, consider sponsoring me so I can keep on doing this full
  time: <https://github.com/sponsors/hugopeixoto>
</aside>
