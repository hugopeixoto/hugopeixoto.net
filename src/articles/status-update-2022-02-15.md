---
kind: article
title: Status update, February 2022
created_at: 2022-02-15
excerpt: Time for another monthly update. I'm moving these to the middle of the month.
---

<aside markdown="1">
  If you enjoy my work, consider sponsoring me so I can keep on doing this full
  time: <https://github.com/sponsors/hugopeixoto>
</aside>

Time for another monthly update. I'm moving these to the middle of the month.


## ANSOL

This was a busy month for [ANSOL][ansol].

I took the lead in writing [an analysis of the parties' programmes for the 2022
Portuguese legislative election][gov2022], focusing on free software and
digital rights issues. This got some attention and media coverage ([SAPO
Tek][tek], [PCGuia][pcguia], and [TSF][tsf]).

I also worked on our [yearly "I love free software" message][ilovefs], making a
quick round-up of free software technologies that we used in the last year.

We migrated our code forge from Phabricator to Gitea a couple of days ago, so I
spent some time configuring ANSOL's account and mirroring some repositories.
You can check it out on <https://git.ansol.org>. We're still using github and
gitlab as the main repositories, but that will probably change with time.

Finally, I recovered our mastodon account
[@ansol@floss.social](https://floss.social/@ansol). This was using an email
account that no longer exists, so I had to contact the administration team, but
then I couldn't receive their email replies... it took some time, but they were
super helpful and we're going to try to use it again now.


## Cyberscore

I've been going through [Cyberscore][cyberscore]'s codebase and converting it
file by file. On my last update, there were 12k lines of code to go through.
Today, that number is down to 1.5kloc! When this reaches zero, hopefully we'll
be able to make the code public. I can't wait to share with the world the
mini-framework I wrote.

Our server ran out of space this month. Players submit image proofs of their
highscores and we store them all, so this tends to take up a lot of disk space.
We had some redundant local backups as a result of the april 2021 hack, so I
moved those off-site and deleted them. This gave us ~15gb of breathing room,
which should be enough for at least a few months. Another thing that's taking
up a ton of space is `/var/lib/mysql`: 26Gb. Our database isn't that big, so
there's something weird going on. I think I'll need to tweak the binlog
expiration period.


## Other stuff

I released a podcast episode this month: [Ep 40: Nada funciona
nunca](https://conversas.porto.codes/episodes/nada-funciona-nunca). We have
another one in the editing queue, but I didn't have much time this month.

I virtually attended [FOSDEM](https://fosdem.org) and the [EU Open Source
Policy Summit](https://summit.openforumeurope.org/). During FOSDEM I mostly
focused on the Matrix and Legal and Policy devrooms. Videos of both events are
available.

I was trying to read [this german page about how a school adopted and adapted a
matrix client to their needs](https://hermannschule.de/hermannpost.html), when
I decided to look for an alternative to google translate. I found something
that's self-hostable, [LibreTranslate](https://libretranslate.com/). I tried
self-hosting this on my PTisp VPS, and it was terribly slow. I tried again in a
5 USD digital ocean VPS, and it was way faster. I really need to switch to a
different provider. I started working on a [browser extension for
firefox][gh-ltf] but with such a slow instance I was having a hard time
iterating, so I paused work on it until I get a better server.

Finally, I tried to convince some folks to host their meetup on free software
solutions instead of zoom, but had some trouble finding a setup that felt good
enough to replace it. I tried jitsi, owncast, OBS, VDO.ninja, and BigBlueButton
in several combinations. I'll need to give it another go.


## Up next

I'll be doing some consulting work for the next couple of weeks, working on
upgrading up some Terraform repositories and some postgres clusters.

Other than that, I want to finish the cyberscore conversion. It's so close! As
soon as I finish convering all the missing files, I still need to go through
every file again for a quick second pass, ensuring that we have the proper
authorization in each endpoint and double-checking for SQL injections. Then,
we'll have to change all our server passwords (since some of them were commited
to the git repository when I started). Finally, we'll have to pick a license
and release the software.


<aside markdown="1">
  If you enjoy my work, consider sponsoring me so I can keep on doing this full
  time: <https://github.com/sponsors/hugopeixoto>
</aside>

[cyberscore]: https://cyberscore.me.uk
[ansol]: https://ansol.org

[gov2022]: https://ansol.org/noticias/2022-01-19-software-livre-nos-programas-eleitorais-2022/
[ilovefs]: https://ansol.org/noticias/2022-02-14-eu-adoro-software-livre-2022/
[gitea]: https://git.ansol.org

[tek]: https://tek.sapo.pt/noticias/negocios/artigos/o-que-dizem-os-programas-dos-partidos-sobre-software-livre-e-direitos-digitais
[pcguia]: https://www.pcguia.pt/2022/01/software-open-source-nos-programas-dos-partidos-para-as-legislativas-2022-ansol-elogia-ideias-da-il-e-do-pan/
[tsf]: https://www.tsf.pt/programa/mundo-digital/emissao/a-importancia-do-software-livre-nas-proximas-eleicoes-14527370.html
[gh-ltf]: https://github.com/hugopeixoto/libretranslate-firefox
