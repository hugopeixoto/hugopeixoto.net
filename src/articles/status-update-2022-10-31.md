---
kind: article
title: Status update, October 2022
created_at: 2022-11-15
excerpt: |
  Late october update, I'm moving cities again. I managed to do a bunch of
  small tasks in several different projects.
---

<aside markdown="1">
  If you enjoy my work, consider sponsoring me so I can keep on doing this full
  time: <https://github.com/sponsors/hugopeixoto>
</aside>


Another late update &mdash; I was busy with stuff during the first half of October.
I'm moving places again, so until December I'll probably be busy packing and
moving things around. Oh, and I'm on the fediverse now: <a
href='https://ciberlandia.pt/@hugopeixoto'>@hugopeixoto@ciberlandia.pt</a>.


## Porto Codes

During this year's hacktoberfest we organized [contributing
session](https://www.meetup.com/portocodes/events/289194405/) on
[Significa](https://significa.co/)'s office. We had around a dozen folks show
up, with some making their first open source contribution.


## ANSOL

I'm working on translating the [Fedigov](https://fedigov.ch/) website to
Portuguese. Hopefully I'll publish it this week.
[Saucy](https://git.ansol.org/ansol/saucy) has some issues that need fixing, so
I'll be working on that this week.


## D3 - Defesa dos Direitos Digitais

I upgraded our instance of bitwarden and hedgedoc to the latest versions and
wrote some documentation on how things are currently deployed.


## Cyberscore

I did a big data model change to cyberscore. Each chart can have a bunch of
flags and point modifiers. The way these modifiers and flags were stored was
weird and hard to query. Here's the old schema:

~~~~sql
CREATE TABLE chart_modifiers(
  chart_id UNSIGNED INT PRIMARY KEY,
  csp_modifier UNSIGNED INT DEFAULT 0,
  chart_flag UNSIGNED INT DEFAULT 0,
);
~~~~

If a chart had two chart flags and three csp modifiers, it would have five
entries in this table. With this layout, it wasn't easy to find charts that had
two chart flags, or charts that had no csp modifiers. It also relied on `int`
based enums which made our code a bit more unreadable. This is the new schema:

~~~~sql
CREATE TABLE chart_modifiers2(
  chart_id UNSIGNED INT PRIMARY KEY,
  standard BOOLEAN DEFAULT FALSE,
  speedrun BOOLEAN DEFAULT FALSE,
  solution BOOLEAN DEFAULT FALSE,
  -- ...

  significant_regional_differences BOOLEAN DEFAULT FALSE,
  significant_device_differences BOOLEAN DEFAULT FALSE,
  -- ...

);
~~~~

It has a bunch more columns than the previous schema and their names are
longer, but it's easier to query and to update. After fixing all the
references, we ended up with fewer lines of code. This is the summary of the
merge request: `122 files, +1522, -1735`.


<aside markdown="1">
  If you enjoy my work, consider sponsoring me so I can keep on doing this full
  time: <https://github.com/sponsors/hugopeixoto>
</aside>
