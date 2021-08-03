---
kind: article
title: Status update, July 2021
created_at: 2021-08-01
excerpt: |
  I spent most of July playing with computer vision stuff in rust, but also
  managed to get some work done on Cyberscore. I didn't touch F-Zero Central
  this month.
---

<aside markdown="1">
  If you enjoy my work, consider sponsoring me so I can keep on doing this full
  time: <https://github.com/sponsors/hugopeixoto>
</aside>


I spent most of July playing with computer vision stuff in rust, but also
managed to get some work done on Cyberscore. I didn't touch F-Zero Central this
month.


## Cyberscore

The biggest change this month on cyberscore is that we're now email-capable
again! It took a while to get AWS SES to grant us production access, but it's
working. It also meant I had to add composer to get the AWS SDK package
installed, so that's progress. I also added `twig` to render the email templates,
so maybe I'll end up reusing it for the actual website page templates.

The other significant thing I added was a JSON view to some pages. This was
requested by someone working on a Discord bot for New Pokémon Snap scores, and
it might see some changes in the future.

Finally, I removed a bunch of explicitly unused code (`attic/` directory):

```
$ git diff master@{"1 month ago"} --shortstat
316 files changed, 4338 insertions(+), 40417 deletions(-)
```

I'm currently working on understanding the details of every scoreboard, trying
to.. formalize its structure? The calculations related to each scoreboard are
spread over multiple files by funcionality instead of by scoreboard, making it
a bit hard to add new scoreboards.


## Computer vision and speaking at Rustconf

I mentioned a few months ago that I was digitizing my Pokémon TCG collection.
This month, I started playing around with the idea of automatically detecting
cards from a video stream to make the process easier.

I built a toy project using rust, and I got accepted to talk about it at
[RustConf 2021](https://rustconf.com/schedule/identifying-pok-mon-cards)!
The conference will be on September 14th.

The code is available on [my github
account](https://github.com/hugopeixoto/ptcg-detection/), but it's pretty
undocumented and experiment-y. I started by using a few crates with basic
algorithms but ended up writing them myself to tweak and adapt them.

I didn't bother to document anything yet, but I've uploaded some images of the
inner workings of the algorithm if you want to see some pretty pictures:
<https://hugopeixoto.net/pokemon/detection/>


<aside markdown="1">
  If you enjoy my work, consider sponsoring me so I can keep on doing this full
  time: <https://github.com/sponsors/hugopeixoto>
</aside>
