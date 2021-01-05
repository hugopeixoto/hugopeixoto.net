---
kind: article
title: Status update, December 2020
created_at: 2021-01-05
excerpt: |
  The last status update of 2020.
---

<aside markdown="1">
  If you enjoy my work, consider sponsoring me so I can keep on doing this full
  time: <https://github.com/sponsors/hugopeixoto>
</aside>

2020 is over! It was a different year in many aspects. I started doing these
monthly updates when I stopped working full time, inspired by [Drew DeVault's
status
updates](https://drewdevault.com/2020/12/15/Status-update-December-2020.html).
It's been a useful way of tracking the passing of time, it keeps me aware that
I should at least try to accomplish something each month, even if it's working
on a useless personal project. Some months were more productive than others,
and that needs to be OK.

## Advent of Code

I spent most of the month obsessing over [Advent of
Code](https://adventofcode.com/). Initially my goal was only to solve each
problem using rust on the day of release, but I ended up trying to optimize
them down to sub-millisecond. That wasn't possible for every problem, but I did
manage to get there for most of them. My [solutions are available on
github](https://github.com/hugopeixoto/aoc2020), and I wrote down some thoughts
over the weeks:

- [Advent of code 2020, week 1](/articles/advent-of-code-2020-week-1.html)
- [Advent of code 2020, week 2](/articles/advent-of-code-2020-week-2.html)
- [Advent of code 2020, week 3 and 4](/articles/advent-of-code-2020-week-3-4.html)


## Cyberscore

I'm working on rewriting some of the pages. Instead of rewriting everything
from scratch, I'm going from page to page extracting helpers similar to the
ones available in rails, like `link_to`, `url_for`, `checkbox_field`, etc.

I've also redesigned some pages while doing it; for now these redesigned pages
are only available for logged in users that opt-in, but here's a sample of the
redesigned home page:

![Screenshot of the Cyberscore homepage, redesigned to be
responsive](/articles/cyberscore-mainpage-new.png)

The main difference is that the new version is a bit more responsive.

I'm currently working on rewriting the user settings page, which implies
rendering forms, handling POST parameters and updating database records. I'm
also redesigning it, because this is how the current page looks like right now:

![Screenshot of the Cyberscore settings page, showing redesigned to be
responsive](/articles/cyberscore-settings.png)


## Random consulting gig

I spent one day consulting, helping a company optimize their infrastructure and
making sure that each component can scale if necessary. We spent some time
optimizing the number of [workers][gunicorn-workers] and
[threads][gunicorn-workers] of `gunicorn`. They were using the values suggested
by gunicorn's documentation, `2-4 $(NUM_CORES)` for both, which is a bit weird.
I don't think you ever want a quadratic number of threads. We tested a few
different configurations and benchmarked it with [Locust](https://locust.io/)
to see what would be the optimal values for that particular project.


## What's next

I have two podcast episodes to edit. I also need to finish some [AlumniEI
mentorados][mentorados] project tasks.

<aside markdown="1">
  If you enjoy my work, consider sponsoring me so I can keep on doing this full
  time: <https://github.com/sponsors/hugopeixoto>
</aside>

[gunicorn-workers]: https://docs.gunicorn.org/en/stable/settings.html#workers
[gunicorn-threads]: https://docs.gunicorn.org/en/stable/settings.html#threads
[mentorados]: https://github.com/alumniei/mentorados/
