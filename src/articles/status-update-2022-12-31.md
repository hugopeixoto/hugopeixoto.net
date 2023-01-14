---
kind: article
title: Status update, November and December 2022
created_at: 2023-01-14
excerpt: |
  Porto Codes is restarting. Cyberscore now uses Twig templates. I'm going to
  FOSDEM.
---

<aside markdown="1">
  If you enjoy my work, consider sponsoring me so I can keep on doing this full
  time: <https://github.com/sponsors/hugopeixoto>
</aside>

After moving and unpacking, I was away from the computer for a couple of weeks.


## Advent of code

I didn't have much time to participate in Advent of Code this year, but I
managed to solve most of them by now: <https://github.com/hugopeixoto/aoc2022>.
I was having trouble solving [day 19 part
2](https://adventofcode.com/2022/day/19), so I'd like to give it another try
soon.


## Cyberscore

Cyberscore HTML templates were pure PHP instead of something like Twig. This
had a number of problems. First, there was no way to enable HTML autoescaping
by default, meaning we were one missing `h()` call away from suffering from
XSS. Second, it was hard to stop someone from adding SQL queries and complex
PHP code to template files. Third, templates had access to every global
variable defined in the PHP file that rendered the template.

With this in mind, I [added support for Twig
templates](https://gitlab.com/cyberscore/cyberscore/-/merge_requests/1556). Now
things are automatically HTML escaped, you need to explicitly list which
variables the template can see, and no more PHP can leak onto them.

There are ~13k lines of template code on cyberscore, all of which will need to
be ported to Twig. I'm roughly 25% there, but there are some [scary
files](https://gitlab.com/cyberscore/cyberscore/-/blob/5fc4f1c5f9bad922fc894fc9c4b2b50bab45fa20/src/templates/charts/show.php)
that will take some time to convert.

## Forge federation grant proposal

I submitted a proposal to be funded by NLNet to add federation support to
gitlab. I am expecting an answer some time this month:
<https://forum.forgefriends.org/t/federation-in-gitlab-nlnet-grant-proposal-maybe-december-2022/933>


## Porto Codes

This January we'll have the first proper Porto Codes event in a long time, with
two talks:

- From top secret to common knowledge: how sensitive is sensitive data?, by
  Rita Silva
- A informática hospitalar e das instituições públicas - reflexões de um quase
  aposentado, by Mário Seixas

See the complete details on our meetup page:
<https://www.meetup.com/portocodes/events/290857364/>


## ANSOL / FOSDEM

In what probably wasn't the smartest idea, I volunteered to go to FOSDEM
representing ANSOL. I'll be there some days before to attend a few smaller
events.


## 2023: The year of self-hosting

I've started doing this last year, but I'm going to continue to migrate away
from third party hosted services to self hosting solutions (even if it's on a
VPS). Initially my plan was to migrate at least one service per month. Here's a
quick list of services that I'm thinking of self-hosting:

- Simplecast, where we host the podcast <https://conversasemcodigo.pt>. We
  haven't published any new episodes in a bit, and it's a bit costly to
  maintain.
- I'd like to leave `meetup.com` but given its network effect, it's going to be
  a bit hard to do. Maybe if I setup a mobilizon instance and offer it to the
  local meetups or something, not sure.
- Matrix, I'm using an account on `matrix.org` and I'd like to use my own
  homeserver with my own domain. I am waiting on `conduit.rs` to reach 1.0 but
  maybe I can give it a try anyway.
- Ultimately, email.

This doesn't cover 12 months, but the last item alone will be a multi month
project.



<aside markdown="1">
  If you enjoy my work, consider sponsoring me so I can keep on doing this full
  time: <https://github.com/sponsors/hugopeixoto>
</aside>
