---
kind: article
title: Status update, June 2020
created_at: 2020-07-01
---

It's now been one month since I [left my job](/articles/next-steps.html). I
decided to start doing status updates, at least once a month.

I brought my personal email inbox down to zero. While at it, [I wrote a rust
cli tool to back up all of the messages I
received](/articles/backing-up-gmail-with-rust.html). The next step is to add
an incremental backup option. I played around with email parsing to get some
statistics out of it. I would like to get this to a state where I could have it
running in a cron job.

On the topic of email, I created a trial account with [Hey](https://hey.com/),
an email provider and client. I don't think it's for me, since they don't
support custom domains and don't expose emails via IMAP, forcing me into using
their proprietary client. I found [email service provider recommendations by
Drew
DeVault](https://drewdevault.com/2020/06/19/Mail-service-provider-recommendations.html)
that might be useful when picking an alternative to gmail.

I started using [The Old Reader](https://theoldreader.com) again. Most of my
old subscriptions are either gone or not receiving updates. I added a few
personal blogs, some webcomics, and [RubyFlow](https://rubyflow.com). I
subscribe to [Hacker News](https://news.ycombinator.com/), which turned out not
to be great. There are more than 100 entries per day, and I skim through them,
reading only a dozen or so per day. I'll start tagging the articles I open to
see if there's a pattern. I may replace it with [lobste.rs](https://lobste.rs),
and [tilde.news](https://tilde.news/) which have considerably less traffic.

I have been collecting some resources on self hosting a RSS reader. One feature
I think I'd appreciate is to remove duplicates (so I could subscribe to
multiple from aggregators), and be able to transform some feeds (so I could
preload some webcomics). I'd also like to publish a feed of favorited articles.

I am [rewriting the web platform that runs my college's alumni mentorship
program](/articles/rewriting-a-small-rails-and-react-application.html). The
previous version was powered by a rails API and a react frontend, and I'm
rewriting it into a rails only application. I am looking for portuguese hosting
solutions, and expect to have this live by early next week.

I have two episodes of [Conversas em Código](https://conversas.porto.codes) in
the pipeline. One of them is practically done and I intend to publish it this
week.

To edit the episode, I rewrote the [command line audio editing
tool](https://github.com/hugopeixoto/wedit) I built a few years ago. I want to
write about how the new version of the tool works. It's written in C, but I am
thinking about porting it to rust. This tool is mainly an excuse for me to
learn about audio. I want to implement a frequency filter, so the next step
there is to learn how to convert the PCM stream from time domain to frequency
domain.

Lua 5.4 was released, so [RLua](https://github.com/whitequark/rlua) needs to be
updated. [I accidentally started this task last
year](https://github.com/whitequark/rlua/pull/10), unaware that I was using a
beta version. I can finish this now.

That's all for June. Let's see how July goes.
