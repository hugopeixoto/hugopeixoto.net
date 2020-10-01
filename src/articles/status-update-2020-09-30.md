---
kind: article
title: Status update, September 2020
created_at: 2020-09-30
excerpt: |
  Another month gone, another status update
---

<aside markdown="1">
  If you enjoy my work, consider sponsoring me so I can keep on doing this full
  time: <https://github.com/sponsors/hugopeixoto>
</aside>

Another month gone, another status update.

My main focus this month was on reporting what I learned during the [Games Made
Quick](https://itch.io/jam/games-made-quick-four-plus) gamejam. This resulted
in a two-parter:

- [Rust, gamedev, ECS, and bevy - Part 1](/articles/rust-gamedev-ecs-bevy.html)
- [Rust, gamedev, ECS, and bevy - Part 2](/articles/rust-gamedev-ecs-bevy-p2.html)

While working on those articles, I had to write some benchmarking code,
[available on my tests
repository](https://github.com/hugopeixoto/tests/tree/master/ecs).

These articles had rust code samples, so I bumped into some bugs in the rouge
syntax highlighting gem I'm using.

There was [a PR from 2016](https://github.com/rouge-ruby/rouge/pull/452) that
fixed a lot of rust issues, but most of them were fixed in different pull
requests in the meantime. I tracked those down, figured out what issues were
still present in the main branch, and made a couple of small PRs to fix them:

- [Bugfix: Allow rust tuple indexing](https://github.com/rouge-ruby/rouge/pull/1580)
- [Bugfix: support rust float delimiters](https://github.com/rouge-ruby/rouge/pull/1581)

These were merged fairly quickly, and the original PR was closed.

When publishing those two articles, I explored the idea of syndicating my blog
posts to [DEV.to](https://dev.to/). They can import content from an RSS feed as
draft posts, so I decided to give it a try. Unfortunately, [this feature has
issues dealing with newlines](https://github.com/forem/forem/issues/8457).
There was some discussion on **what** was happening, but not **why**, so I
cloned the repository and started making some experiments.

The issue comes from converting HTML to markdown, which is mostly handled by
the [`reverse_markdown` gem](https://github.com/xijo/reverse_markdown). Part of
the problem was in a monkey patched class that didn't get any updates, so I
fixed that:

- [Fix newlines being chomped in RSS import](https://github.com/forem/forem/pull/10476)

But the other part of the problem is upstream, and I don't see how to easily
fix it. I reported my findings in this issue:

- [Too much blankspace gets stripped](https://github.com/xijo/reverse_markdown/issues/91)

I'm not sure if I will continue working on that issue, since I can't find a
quick solution to the problem and it might require a significant overhaul.

On another note, people are renaming their git branches from `master` to `main`
(I've migrated some of mine, and try to use `main` in new repos). This change
inevitably leads to some things breaking. This happened with
[Dokku](http://dokku.viewdocs.io/dokku)'s documentation, so I made a PR to
fix it:

- [Update push command for sample app in docs](https://github.com/dokku/dokku/pull/4136)

Dokku itself doesn't support `main` by default, so maybe that's something worth
exploring.

This week I've been exploring rust in a web dev context. I'm working on a toy
project, [imghost](https://github.com/hugopeixoto/imghost), to see how the
experience is like. I'll probably report on this soon.

I've been complaining about my laptop for months now. 8GB of ram is not enough
anymore, and when it starts swapping, everything halts. Some disk heavy
operations would also freeze the entire thing, so replaced the SSD to see if it
helps. Instead of cloning the disk, I decided to start from scratch.

I recently changed my setup from using X11 to using Wayland (mostly to get
multi-monitor variable DPI support), so there were a lot of packages and
configs that I didn't need anymore. I also decided to skip chromium and rely on
firefox exclusively.

One of the advantages of starting from scratch is that I had to update my
[dotfiles repository](https://github.com/hugopeixoto/dotfiles/). I also took
the opportunity to document (in my private notes.git) the installation process
and which packages I usually need. I'll try to figure out the best way to make
this public.
