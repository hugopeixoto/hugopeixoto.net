---
kind: article
title: Tale of two sites
created_at: 2021-05-24
excerpt: |
  Cyberscore and F-Zero central are two video game related websites that I help
  maintain. I used two different approaches when I started working on them, and
  in this post I'll go through these methodologies.
---

<aside markdown="1">
  If you enjoy my work, consider sponsoring me so I can keep on doing this full
  time: <https://github.com/sponsors/hugopeixoto>
</aside>

Last month, two video game related websites, [Cyberscore][cyberscore] and
[F-Zero Central][fzc], were breached. [I wrote about it in last month's
report][su-202104]. I've been helping out Cyberscore for a while now, and I
started helping the F-Zero Central staff since the hack.

These two sites are kind of similar in functionality, but my approach when I
started working on them was quite different.

## Cyberscore

Cyberscore is a frameworkless PHP website, of roughly 45k lines of code.
There's also a Simple Machines forum installation, but the codebases are
independent, so we can upgrade the forum without breaking the main website's
functionality. Cyberscore doesn't use any templating engine, ORM or routing
library.

When I started working on it, I started by making some small fixes to get the
website to a stable place. There were some cron jobs that were bringing the
website to a halt. When things started being stable, I started fixing bugs, but
more weird things kept popping up. At this point, the dev team discussed
rewriting the whole thing from scratch.

I started a Laravel project but didn't get very far. The website is just too
big to rewrite in one go. There's no documentation except for some code
comments here and there, so it was hard to start building the data model to
cover the existing functionality. It would take months to get to a place where
we'd be able to deploy it, so I ditched the idea and started doing incremental
changes in the existing codebase instead.

The first changes were on the directory structure. I moved every php file to
`/public/` and pointed the http root to it instead of pointing to the root
repository, so we would stop exposing other files (like `/.git/`) to the web.
Files that felt like experiments or files that were accidentally duplicated via
FTP were all moved to `/attic/`, for later reference or deletion. Extracted
some configurations to a git ignored `/config.ini` so that things like the
database password wouldn't be tracked by git. Added a simple router so that the
new code could be extracted to `/src` instead of `/public`.

Then, I added a few helpers for things like accessing the database with
prepared statements, html helpers to generate forms, etc. Whenever I had to
touch a page to fix something, I'd rewrite it to make use of these helpers and
moved it to `/src/pages/`, extracting the HTML part to `/src/templates/`. I
still haven't covered half the website, but this way I can track which files
have been converted to the new helpers.

The hardest part has been dealing with the database. There are a bunch of
integer enums whose values aren't documented anywhere, there's no foreign key
enforcing so we have a ton of dangling references, there are many cache tables
and columns which are hard to identify, and sometimes sql and html escaping is
applied in the database instead of being applied when rendering. Sometimes I
have to spend hours going through the code, discord logs, and gitlab issues to
understand what's up with the database.

If I had gone the rewrite route, I'd have to do all of this work upfront, and I
would probably still be working on the rewrite right now. By working
incrementally, I can stop working on cyberscore any time and the community
still benefits from my work until then.

Maybe when I've converted every page I can start working on adding proper
templates and an ORM. Then I can start thinking about converting it to a
Laravel project, but I'm still too far away from that to think about all the
steps.


## F-Zero Central

F-Zero Central is built on top of a quite old phpbb forum, with around 17k
lines of code added. The custom pages are heavily dependant on the forum
codebase, relying on it for html templates, sql queries, and user
authentication. I joined the project to help with the forum hack. The plan was
to upgrade phpbb from 2.x to 3.x, fix whatever would be broken, and be done
with it.

Unfortunately, the migration wasn't easy. There's no upgrade button from the
2.x version. You have to setup a 3.x and import the data from the other
database. This part took me a while to get right, mostly due to `latin1` vs
`utf8` problems, and the presence of multiple users with the same username.
When I got that right, I could see the posts, but the new phpbb doesn't support
HTML posts, which is what we were using, so every post was a bunch of HTML. I'd
have to find a way to convert it to bbcode, and some posts are not
representable in bbcode.

The templates/styles structure also changed, so that's another thing I'd have
to convert. Even if I left the forum using the default theme, our custom pages
rely on the templates, so I'd have to convert at least part of the styles to
get the website working. The phpbb functions used by the custom pages also
changed, so I'd have to rewrite every custom page to use the new functions.
Basically, I'd have to rewrite the custom pages anyway.

By now, almost two weeks had passed since we took the website down, so I
decided to take a different approach. I wanted to get something working to
signal the community that we were working on it. Having a "we're down" page for
months won't do anyone any good.

I installed [`twig`][twig], which is what phpbb 2.x uses, and started rewriting
some pages from scratch. I focused on displaying existing scoreboard
information first, ignoring sign in and registrations. I copied over parts of
the templates but took the time to rewrite them to use css grids, background
gradients and radius borders instead of nesting tables and using images.

Most pages I converted follow the same structure: read and sanitize query
params, make some SQL queries, transform and pass the data over to a template
and render it. Some of them also read data from XML files. These contain the
information of each game, things like cups and courses. Dealing with these
files was the weirdest thing I had to deal with while working on this project,
even using [`simplexml_load_file`][simplexml_load_file]. I copied over some
database handling functions from cyberscore, and since I didn't have to deal
with authentication, I didn't depend on any phpbb code.

The end result doesn't look exactly how it looked before, and it's missing a
lot of information and details, but my priority was to get something live so
that the website didn't look dead. It was way easier to rewrite the pages than
to deal with all the phpbb cruft. Now I can add things back slowly without the
pressure of losing community interest.

I'm still not sure what I'm going to do with the forum, but at least folks can
view their record times and their scoreboard positions. I'm working on allowing
users to sign in and submit new records. I will probably end up converting the
XML files to either JSON or YAML.


## Conclusions

Rewriting a project from scratch, if you have to achieve feature parity to get
it live, doesn't work for me. This is particularly true if you're working on a
voluntary project like these two, where it's usually hard to find motivation to
work and contributions are scarse.

I have a preference for improving existing codebases instead of writing things
from scratch. I find it more interesting to move things around and trying to
understand how things work and what their intention was, rather than being
faced with a blank canvas, and having to make a bunch of boring decisions
upfront, like which framework to use, what CSS model, etc. But sometimes the
rewrite is the right option.

I just take whichever approach gets me visible results faster, even if I have
to deal with non ideal codebases.


<aside markdown="1">
  If you enjoy my work, consider sponsoring me so I can keep on doing this full
  time: <https://github.com/sponsors/hugopeixoto>
</aside>

[cyberscore]: https://cyberscore.me.uk
[fzc]: https://fzerocentral.org
[su-202104]: /articles/status-update-2021-04-30.html
[simplexml_load_file]: https://www.php.net/manual/en/function.simplexml-load-file.php
[twig]: https://twig.symfony.com/
