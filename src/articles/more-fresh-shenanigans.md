---
kind: article
title: More Fresh shenanigans
created_at: 2023-07-07
excerpt: |
  I implemented another Fresh webservice thing for Cyberscore to parse an
  incremental game's save file. Had to deal with a bunch of typescript
  shenanigans from upstream.
---

<aside markdown="1">
  If you enjoy my work, consider sponsoring me so I can keep on doing this full
  time: <https://github.com/sponsors/hugopeixoto>
</aside>

[Pokéclicker](https://pokeclicker.com) is one of those [incremental
games](https://en.wikipedia.org/wiki/Incremental_game) where you mostly idle
and barely play.

I've started playing this thanks to Cyberscore. There are thousands of charts
in the game, and I don't like to work to submit things manually, so I started
automating it. Usually I'd implement it in the [OCR
system](https://hugopeixoto.net/articles/rust-wasm-ocr-experiments.html) we
have in place, but taking 7k screenshots manually didn't seem like the right
approach.

Since the game allows you to download a save file, I implemented something that
parses this file and extracts the scores. At first I was doing it in ruby, but
the save file doesn't have all the necessary information. It depends a lot on
the game's source code, which is [available on
github](https://github.com/pokeclicker/pokeclicker). Scores like "how many of
each berry have you harvested" are encoded as an array in the save file, and
you need the source code to know which position represents each berry.

The game is coded in typescript, and at first I was just half-assing parsing
certain key files in ruby to extract the necessary information, but it became a
hassle quickly, so I switched to working in typescript so I could just import
the files directly.

I didn't want to deal with npm modules or webpack or any of that stuff, so I
went with [Deno](https://deno.land/). This kind of worked, but I couldn't
import any files directly, because the codebase isn't ready to be used like
this: imports don't have the `.ts` extension, so I did a quick replace to add
those. Then I hit another problem: the project isn't fully converted to proper
typescript modules, and files in `src/scripts` don't have any imports. I
started adding imports to those files manually, but quickly hit weird
dependencies, like some files trying to do DOM operations on initialization.
Also, some of the typescript modules has circular dependencies. Instead of
trying to fix these problems, I replaced some imports with fake declarations:

~~~typescript
// instead of:
import Sound from "./utils/Sound.ts";
// I just did:
class Sound {}
~~~

Another dependency I had to handle was `Knockout.js` observables. I wasn't
going to deal with importing the real framework, so [I built a few fake
observable
classes](https://gitlab.com/cyberscore/pokeclicker/-/blob/cyberscore-fixups/src/modules/ko.ts).

In the end there were about 86 files changed. This is probably going to be a
nightmare to maintain: save files are for specific game versions, so I'll have
to keep updating this with every release.

With the save parsing working, I had to put this up on a webservice. Using
deno, [Fresh](https://fresh.deno.dev) was the obvious choice. I already ported
a nodejs service to Fresh, so I had an idea of what I was getting into.

Getting things to work was easy, I just needed a couple of endpoints: one where
you'd upload the save file, and a second one where you confirmed the parsed
scores and submitted them to cyberscore.

Cyberscore doesn't have a proper API with authentication and all that, but I
worked around it by asking the user to enter the `PHPSESSID` cookie, and passed
that along to authenticate the request. The response isn't even JSON based,
it's just the website's HTML, which I ignore.

The issue I hit next was that submitting thousands of scores in one go took
more than 2 minutes. I'm pretty sure our production apache would timeout before
that, but even if it didn't, I didn't want to make a tool that would DoS our
main site, so I had to work on that a bit. At first I optimized the multiple
record submission code by removing redundant queries, but I couldn't get it
below 100 seconds. Each score triggers a chart rebuild and potentially sends
notifications to users that get dethroned, so there's a lot of work being done.

The fix for this was to queue these record submissions and process them offline
if you submit more than 100 scores in the same request. I created a
`queued_records` table with all the data that gets submitted and built a
background worker whose code is basically this:

~~~~php
while (true) {
  process_queued_records(100);
  sleep(5);
}
~~~~

Each score takes around 50ms to process, so we do bursts of ~5 seconds of work,
and then pause for another 5 seconds. It's a very rude rate limiting system,
but it does the trick.


To deploy this, I used Fresh's sample dockerfile, which mostly works. It fails
running `deno cache` half the time, and I don't know how to deal with
`deno.lock` yet, but no other big problems. I set up gitlab's CI to
automatically build the docker image and push it to their registry, and it was
surprisingly easy to do it. I didn't have to create and configure any
credentials manually: the CI worker already has those builtin, apparently. The
[.gitlab-ci.yml
file](https://gitlab.com/cyberscore/pokeclicker-submitter/-/blob/main/.gitlab-ci.yml)
was generated using their web based wizard, with just a pair of clicks.


This all works mostly fine (I didn't parse "achivement charts", since they felt
like it was going to be too much trouble), but the authentication part isn't
ideal. The next step is to add API tokens to cyberscore (and do it in a way
that doesn't compromise the whole website) and implement them here.

The [tool's source code is available on Cyberscore's
GitLab](https://gitlab.com/cyberscore/pokeclicker-submitter), soon-to-be AGPL
(I forgot to add the file, oops). [Our fork of the game's codebase is also up
there](https://gitlab.com/cyberscore/pokeclicker), and this one doesn't have a
license because upstream didn't license it (probably because it contains a lot
of assets and IP from N\*nt\*ndo).


<aside markdown="1">
  If you enjoy my work, consider sponsoring me so I can keep on doing this full
  time: <https://github.com/sponsors/hugopeixoto>
</aside>
