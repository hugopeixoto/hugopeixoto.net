---
title: OpenID - The comeback
created_at: 2011-03-24
---

In the past, I wrote (with a friend of mine) a simple PHP OpenID provider. We
used [dorm](http://getdorm.com/), and no extra framework whatsoever.

It is now a messy pile of code.

As such, we are rewriting it in a random Ruby web framework. So that we learn
something in the process, we'll be using the following set of technologies:

* [Sinatra](http://sinatrarb.com/) as the framework,
* [DataMapper](http://datamapper.org/) as the ORM and
* [Slim](http://slim-lang.com/) as the templating language.
