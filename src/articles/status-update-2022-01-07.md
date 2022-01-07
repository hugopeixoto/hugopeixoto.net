---
kind: article
title: Status update for January 2022 (and the last two months)
created_at: 2022-01-07
excerpt: |
  Happy new year everyone! I skipped a couple of monthly updates, so this one
  will be a bit longer than usual. I was having trouble finding the motivation
  to keep writing these updates. Anyway, here's what I've been doing for the
  past couple of months.

---

<aside markdown="1">
  If you enjoy my work, consider sponsoring me so I can keep on doing this full
  time: <https://github.com/sponsors/hugopeixoto>
</aside>

Happy new year everyone! I skipped a couple of monthly updates, so this one
will be a bit longer than usual. I couldn't find the motivation to keep writing
these updates since I felt like I had nothing to show, and I also felt like I
had the responsibility to spend more time working on the freelancing gig I had
taken.

After the new year when I did the last major task that I was contracted to do,
everything unblocked. Go figure. Anyway, here's what I've been doing for the
past couple of months.


## November

The new [ANSOL](https://ansol.org) website was released. Converting the drupal
database to markdown wasn't hard compared to rewriting the whole theme. I'm
still tweaking some things here and there, but it's mostly functional.
The [website's code is available on GitLab](https://gitlab.com/ansol/web-ansol.org).

I accidentally sat on my phone with my keys in the back pocket and its screen
died. Instead of getting it fixed or buying a new one, I rolled back to my
previous Moto G3. I didn't bother logging in to the play store, and I don't
even have email access right now. Through F-Droid, I installed
[Element](https://element.io/), Firefox and VLC. Since I'm practically at home
all the time it hasn't made much of a difference, but I do miss not having a
couple of homebanking applications. Unfortunately those are all closed source.

Completely unrelated, I spent most of the month going down a giant rabbit hole
of understanding android applications and how to reverse engineer their APIs. I
didn't get very far in my initial goal, but I ended up writing a partial
[Dalvik interpreter/emulator in ruby](https://github.com/hugopeixoto/rjava/).
This isn't super useful, and my application was stuck in an infinite loop so
it's definitely buggy, but it was kind of interesting to learn.

We released three episodes of the [Conversas em
Código](https://conversasemcodigo.pt) podcast: [one about reverse engineering
Android apps](https://conversas.porto.codes/episodes/android-reversing), [one
about
Matrix](https://conversas.porto.codes/episodes/matrix-slack-e-outras-chatices),
[one about
PeerTube](https://conversas.porto.codes/episodes/contribuicoes-open-source-e-peertube).
I still have one unreleased episode that will probably go out this month.

I did some client work deploying a new version of a third party application,
where the old version was on a windows virtual machine. Thankfully I was able
to deploy the new version without touching the old one.


## December tasks

During December I focused mostly on [Cyberscore](https://cyberscore.me.uk). I'm
continuing to go through each php file in `public/` and converting them to a
router based file in `src/`, taking the time to go through the code and remove
any potential SQL and XSS injections. I covered roughly 7000 lines of code this
month, with 12000 lines to go. The low hanging fruit is mostly gone, so now I'm
focusing on large and complex files.

I did some client work as well, upgrading some ruby applications, including
going from ruby 2.6 to 3.x, from ruby 5.x to 6.x, and bumping every gem.

December is the month of [Advent of Code](https://adventofcode.com/). I was way
from the computer at the start of the month but managed to catch up and do the
challenges daily until the 21st. I did the remaining four days on the last
hours of day 25. I went with rust again, and uploaded [my solutions onto a git
repository](https://github.com/hugopeixoto/aoc2021).


## January things

The new year only started about a week ago, but I already got a bunch of stuff
done.

I rewrote [`untracked`](https://github.com/hugopeixoto/untracked) in rust. The
tool had a couple of bugs that I wanted fixed and I didn't feel like dealing
with C. The codebase ended up practically the same size, but rust enums and
pattern matching made things a bit easier.

I published [`mknsd`](https://github.com/hugopeixoto/mknsd), a tool to generate
`nsd` configuration and zone files. It uses its own syntax to define zones,
since I don't need all the bells and whistles of a regular zone file. This tool
was in my private `infrastructure.git` repository, next to my actual zone
definitions, but extracting it allows me to publish it.

I cleaned up the [`static-websites`
tool](https://github.com/hugopeixoto/static-websites) output a bit. It now silences
each step's output unless that step fails.

I **finally** automated the backup process for
[Cyberscore](https://cyberscore.me.uk), [F-Zero
Central](https://fzerocentral.org), [viste.pt](https://viste.pt) and my
[miniflux](https://miniflux.app/) installation. I was backing up some of those
manually once a month or so, and the other ones not at all. I've setup
[`restic`](https://restic.net/) using an append only rest backend in a new
debian machine I setup in my bedroom. The next step is to create some redundancy
by shipping those snapshots somewhere else as well.

I had an AWS account draining my wallet for no good reason, with an S3 bucket
(~80gb) and an old route53 zone for hugopeixoto.net (before I started
self-hosting my nameservers). The zone and the bucket are now gone. The only
resource left is a set of credentials for AWS SES that I use to send emails in
one of my projects, but that shouldn't cost me any money, since the project is
practically dead.

I bought [conversasemcodigo.pt](https://conversasemcodigo.pt) a couple of
months ago but never bothered to set it up. It's now redirecting to
[conversas.porto.codes](https://conversas.porto.codes). One day, maybe, I'll
start self-hosting the podcast and ditch simplecast. I'll need to figure out
how to analytics first.

I did a small gig where I upgraded a Heroku application that was using a
deprecated stack (`heroku-16` to `heroku-20`). This required bumping node from
8 to 16, upgrading some packages and rewriting the integration with google
spreadsheets, as their V3 API was also shutdown in the meantime.

Also did some client work upgrading a bunch of RDS databases from postgresql 9
to postgresql 13 using terraform.

A friend kindly donated a bunch of hardware. I got an [Acer
AspireRevo](https://en.wikipedia.org/wiki/Acer_AspireRevo) that became my
backup server, and a couple of android smartphones that I'll use to play with
installing either a free version of Android and/or a Linux distribution. Thank
you!


## Up next

These next couple of months are going to be full of ANSOL tasks that need to be
done: we're making some changes to the association rules to make them a bit
more lax and practical; we're analysing the parties' programmes for the [2022
Portuguese legislative
election](https://pt.wikipedia.org/wiki/Elei%C3%A7%C3%B5es_legislativas_portuguesas_de_2022)
to see how they relate to free software; and work on celebratory messages for a
couple of "International Days" related to free software. [Help is
appreciated](https://ansol.org/inscricao/).

In February I'll be virtually attending [FOSDEM](https://fosdem.org/)!
I'm looking forward to attend, the whole matrix experience was interesting. It
was easier for me to socialize than when I attended in-person.

I also want to at least convert a couple more Cyberscore modules this month.
There are still 12kloc to convert, and it would be nice if I could hit the
10kloc mark this month.

I'd also like to setup some redundancy for the backup server. I already have a
machine in mind, I need to find out how to synchronize them. I'm thinking maybe
rsync+btrfs snapshots. Backups are done daily at a fixed time, so for most of
the day the backup repository will be stable.

In the self-hosting experiments department, there are a bunch of things that
I'd like to play with: [give Jellyfin a try](https://jellyfin.org/), replace my
AWS SES usage with something like [maddy](https://maddy.email/), and find a
good email client. I'm also thinking of finding an alternative portuguese VPS
provider, since the one I'm using is too expensive for the specs and it doesn't
support IPv6.

<aside markdown="1">
  If you enjoy my work, consider sponsoring me so I can keep on doing this full
  time: <https://github.com/sponsors/hugopeixoto>
</aside>
