---
kind: article
title: Status update, January 2021
created_at: 2021-02-04
excerpt: |
  Cyberscore, cyberscore, cyberscore. January was mostly Cyberscore.
---

<aside markdown="1">
  If you enjoy my work, consider sponsoring me so I can keep on doing this full
  time: <https://github.com/sponsors/hugopeixoto>
</aside>

I spent the first half of the month deep in Cyberscore's codebase. I also
started working on a couple of consulting gigs.


## Cyberscore

Last month I started rewriting the pages that seem more problematic, either
code- or layout-wise. This month I split the user settings page from the user
profile page, changed both of their layouts to remove all those scrollbars, and
added proper navigation instead of relying on navigationless AJAX page loads.

I also started tackling some issues from our tracker. One thing led to another,
and ended up rewriting some pages related to game rules. Game rules are things
like: "Only one controller is permitted", or "No glitches allowed". This system
was initially designed to only support one rule text per game level, and when
it was expanded to allow for multiple rule texts not every page was updated to
match that.

A random bot found an SQL injection attack which brought the website down for a
few minutes, so I had to spend some time tracking it down and fixing the
vulnerability.

I also did some long due system upgrades. The MySQL server package was in an
un-upgradeable state, because the `debian-sys-maint` user had been dropped when
the database was first imported. This was preventing us from upgrading our
packages, so it was important to get that fixed.

I wrote a blog post on some [php/mysql things I found interesting][hp-phpmysql]
while working on all of this. I wish I could migrate this to either mariadb or,
ideally, postgres, but this project has some queries that rely on weird
behavior and it doesn't use any database abstraction layer, so that's probably
going to take a while to happen.


## Random consulting gig 1

The first job, which is probably 90% done, required working on an integration
with [Token][tokenio], an open-banking platform. Their docs are, frankly, quite
bad, so I kind of had to jump through some hoops to figure out what was going
on.


## Random consulting gig 2

The second gig consists of figuring out how to bring upgradeability to [ink!
smart contracts][ink-sc]. This was submitted as [an application for the Web3
Foundation Open Grants Program][w3f-pr], so let's see if it moves forward.

I was reading through Substrate's documentation and submitted a few small
fixes:

- [FRAME vs FREAME typo][substrate828]
- [Fix broken links related to upgrades][substrate831]
- [Add link to contracts pallet][substrate832]

If the proposal is approved, expect a blogpost or two on this topic while I
figure things out.


<aside markdown="1">
  If you enjoy my work, consider sponsoring me so I can keep on doing this full
  time: <https://github.com/sponsors/hugopeixoto>
</aside>

[tokenio]: https://token.io/
[w3f-pr]: https://github.com/w3f/Open-Grants-Program/pull/238
[ink-sc]: https://substrate.dev/docs/en/knowledgebase/smart-contracts/overview
[su202012]: /articles/status-update-2020-12-31.html
[hp-phpmysql]: /articles/more-mysql-and-php-findings.html
[substrate828]: https://github.com/substrate-developer-hub/substrate-developer-hub.github.io/pull/828
[substrate831]: https://github.com/substrate-developer-hub/substrate-developer-hub.github.io/pull/831
[substrate832]: https://github.com/substrate-developer-hub/substrate-developer-hub.github.io/pull/832
