---
kind: article
title: Status update, April 2022
created_at: 2022-04-27
excerpt: |
  This month I did some random work for ANSOL and restart my project of
  tracking my Pokémon TCG collection.
---

<aside markdown="1">
  If you enjoy my work, consider sponsoring me so I can keep on doing this full
  time: <https://github.com/sponsors/hugopeixoto>
</aside>

## ANSOL

I wrote the [quarterly
newsletter](https://ansol.org/noticias/2022-04-07-newsletter-2022-1-trimestre/)
describing our activities during Q1. This week I also helped with translating
and publishing an open letter on the universal right to install any software on
any device. You can read the [full letter on FSFE's
website](https://fsfe.org/activities/upcyclingandroid/openletter.en.html), and
check [ANSOL's statement on our
website](https://ansol.org/noticias/2022-04-27-carta-aberta-ecodesign/).


## Pokémon things

I restarted the idea of tracking my Pokémon TCG collection. A few months ago I
had built a command line tool for this, but I decided to upgrade it to a web
app since most of the time it's helpful to see the card images. The main goal
of this project is to be able to quickly register which cards I have and to
keep it up to date.

The way I decided to do this was to create "bags" of cards, representing
physical spaces where my cards are stored. I have binders, decks, and bulk
boxes.

Each of these bag types has their own input method, optimized for data
insertion. For example, I use 3x3 binders for each set where cards are sorted
by number (with gaps for cards that I don't have). To register each binder
page, I press the 1-9 keys on the numpad, each representing a binder page slot,
and use Enter to move to the next page. This lets me register a full binder in
a minute or so.

I didn't want to spend much time writing backend/frontend code, so I went with
[EmberJS](https://emberjs.com) for the frontend, using their
[json:api](https://jsonapi.org) adapter to talk to a Sinatra app that uses
[Sinja](https://github.com/mwpastore/sinja), an extension that helps you
quickly build json:api services. Sinja doesn't support the latest Ruby, so I
started a branch to fix this and other limitations:
<https://github.com/hugopeixoto/sinja/commits/fix/ruby-3-support>. The backend
stores things in [jsonl](https://jsonlines.org/) files because I didn't bother
setting up a database and it was easier to manually tweak things like this.

I also took some notes of the EmberJS first-user experience, and reported a
couple of issues:

 - [ember-keyboard isKey documentation bug](https://github.com/adopted-ember-addons/ember-keyboard/pull/626);
 - [Fix Ember Data call out regarding store](https://github.com/ember-learn/guides-source/pull/1802), submitted by locks.

The code is available on github:

- Frontend: <https://github.com/hugopeixoto/pokemon-collection-tracker-frontend/>
- Backend: <https://github.com/hugopeixoto/pokemon-collection-tracker-backend/>


## Other stuff

There wasn't much going on this month, I had to spend some time doing freelance
work. The next project will be installing some zigbee power meter things around
the office to see how much energy the computers are consuming. I also want to
finally move away from PTISP to stop wasting money there.


<aside markdown="1">
  If you enjoy my work, consider sponsoring me so I can keep on doing this full
  time: <https://github.com/sponsors/hugopeixoto>
</aside>
