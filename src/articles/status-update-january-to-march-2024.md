---
kind: article
title: Status update, January to March 2024
created_at: 2024-03-24
excerpt: |
  TODO Excerpt
---

<aside markdown="1">
  If you enjoy my work, consider sponsoring me so I can keep on doing this full
  time: <https://github.com/sponsors/hugopeixoto>
</aside>

## ANSOL

We've started writing articles for a paper publication, [PCGuia][pcguia]. I
personally wrote two opinion columns, one about Router Freedom and one with a
few suggestions for the new goverment (a shorter version of [ANSOL's
article][ideias] on the same topic).

[FOSDEM][fosdem] happened, and travelled there on ANSOL's behalf. We had a few
meetings with Portuguese Members of the European Parliament, joined the Matrix
Community Meetup, and hung out with other Free Software groups. We've also had
a meeting with someone from the [Institute of Registries and Notary][irn].

![A group picture taken at the Matrix Community Meetup in Brussels showing around 30 attendees in a crowded hackerspace room with several Club Mate bottles on the table](matrix-meetup-2024.jpg)

ANSOL had its elections in March, which means we had to prepare a bunch of
documents to present during the General Assembly. I wrote the activity and
financial statements report for 2023 and the programme for 2024. During this GA
I was elected as the Vice President of the Board of Directors for the next two
years. Three of the five members are new to the board, so there was a lot of
onboarding that needed to be done.

I've been working on [saucy][saucy] again. I upgraded its rails version and
rewrote the whole notification system. I've also added [`solid_queue`][squeue],
now that it has recurring tasks support. With puma's `solid_queue` plugin, this
means we no longer need an additional daemon or the host's cron to run the
scheduled tasks, which simplifies deployment.

Other organizations have shown interest in using saucy, so I've submitted a
grant proposal to NLNet's Common Fund to make it a bit more flexible and
usable. I've published the [text of my proposal][nlnet].


## Porto Codes

I organized a [meetup in January][portocodes], with around 20 attendees. It was
a failed attempt at restarting the monthly events. I couldn't schedule anything
for February due to scheduling conflicts and didn't even try in March. I'll be
out of the country during April so... maybe in May? We recorded this event, so
now I need to edit and publish it.



## Cyberscore

One of the few games that I've been playing that's on cyberscore is [Melvor
Idle][melvor]. Just like [Pokéclicker][pokeclicker], it's an incremental game
where you just check it from time to time and numbers go up. I didn't want to
submit 4000 scores manually, so I made a tool where you upload your savefile
and it extracts all the scores. I couldn't easily repurpose the game's
javascript files so I went with rust compiled to WebAssembly. The code is
[available on gitlab][csmelvor].


<aside markdown="1">
  If you enjoy my work, consider sponsoring me so I can keep on doing this full
  time: <https://github.com/sponsors/hugopeixoto>
</aside>

[pcguia]: https://pcguia.pt/
[ideias]: https://ansol.org/noticias/2024-01-12-ideias-para-a-proxima-legislatura/
[fosdem]: https://fosdem.org/
[irn]: https://en.wikipedia.org/wiki/Institute_of_Registries_and_Notary
[saucy]: https://git.ansol.org/ansol/saucy
[squeue]: https://github.com/rails/solid_queue/
[melvor]: https://melvoridle.com/
[pokeclicker]: /articles/more-fresh-shenanigans.html
[csmelvor]: https://gitlab.com/cyberscore/melvoridle
[nlnet]: https://gist.github.com/hugopeixoto/b2b611a4c61b97050c2bbe876deed566
[portocodes]: https://porto.codes/previous#2024-01-25
