---
kind: article
title: Status update, March 2022
created_at: 2022-03-24
excerpt: |
  This month I joined the board of ANSOL, (re-)learned ansible and LXD,
  finished converting cyberscore's codebase, and implemented OCR in Rust in the
  browser using WebAssembly.
---

<aside markdown="1">
  If you enjoy my work, consider sponsoring me so I can keep on doing this full
  time: <https://github.com/sponsors/hugopeixoto>
</aside>

## ANSOL

I have joined the board of [ANSOL](https://ansol.org) for the next two years.
For the first few months I'll be trying to improve/simplify some of our
processes to speed up new memberships and free up some of our time to work on
actual issues.

One of our infrastructure servers is setup using [ansible][ansible] and [LXD
containers][lxd], so I've been re-learning the former and learning the latter.
[Our setup is available in our code forge][ansol-ansible], even though it's
missing licensing information.

Initially, this required the ansible runner to have lxd installed, and I don't
run Ubuntu, so I had to change that. There were some connection plugins that
worked with the server's lxd via ssh, but they were outdated. I found that they
were initially forked from a project that was based on bsd jails which is still
maintained, so I took those two and combined them to make a working `sshlxd`
connection plugin. You can find this plugin available under an MIT license:

<https://git.ansol.org/ansol/ansible/src/branch/master/connection_plugins/sshlxd.py>

Infrastructure-wise, We're also thinking of switching to a different platform
to manage membership subscriptions, payments, etc. We're currently using
[CiviCRM](https://civicrm.org/), and from what I understand it's a bit complex
to use that cause unnecessary delays in processing membership requests and
renewals, so we're looking into alternatives.

Next week, on the 30th, we'll be hosting an online discussion / meetup on the
topic of [Document Freedom][dfd]. We'll have a chat on the usage of open
standards, the adoption of such standards by the Portuguese government, and
other related topics. More info will be available on our website:

<https://ansol.org/eventos>


## Cyberscore

The process of converting the codebase to use prepared statements is finally
finished! After ~2 years of working on this, it's finally done. We've covered
most of the security holes in the application except for a couple of things:
lack of CSRF protection and trusting user input in a particular form. The CSRF
stuff is probably handled by `Same-Site: Lax`, but I need to double check that
it does what I think it does, I haven't really caught up with how that works.

Once the trusting user input issue is fixed (I'm currently working on it) I'll
be changing all the passwords, publishing the repository, and hoping for the
best.

I was thinking of setting up a temporary [CLA][cla] that would allow us to
close up the source code again in the first few months if something went wrong,
but I don't think it would do us any good, since the codebase would already be
out there anyway.

Another big thing I worked on this month was the "Auto-proofer" tool, which
takes player-submitted screenshots and automatically scans the scores contained
in the image, making it easier to bulk-submit scores and reduce typos. This is
limited to a handful of games and only works with full screenshots (not photos
or cropped versions), but it's been used a lot already. The scanning
functionality is implemented in [Rust on the browser using WASM, and I've
written an article detailing how that works][wasm]. The repository with the
scanning code is available under the AGPL, so check it out as well:

<https://gitlab.com/cyberscore/auto-proofer>

We also added a new scoreboard this month, the [Experience board][xp-board]. It
tracks how hard you grind in certain games. Scores like "how many kilometers
did you walk in Pokémon Go?" are rewarded.


## Other stuff

[AlumniEI's mentorship program](https://github.com/alumniei/mentorados) hasn't
had any progress in a while, so I suggested retiring it. The University of
Porto has released a platform that seems to include mentorship as one of its
goals, so it feels like a good time to shutdown this initiative.


<aside markdown="1">
  If you enjoy my work, consider sponsoring me so I can keep on doing this full
  time: <https://github.com/sponsors/hugopeixoto>
</aside>

[CLA]: https://en.wikipedia.org/wiki/Contributor_License_Agreement
[wasm]: https://hugopeixoto.net/articles/rust-wasm-ocr-experiments.html
[auto-proofer]: https://gitlab.com/cyberscore/auto-proofer
[xp-board]: https://cyberscore.me.uk/scoreboards/incremental
[ansol-ansible]: https://git.ansol.org/ansol/ansible
[lxd]: https://linuxcontainers.org/lxd/
[ansible]: https://www.ansible.com/
[dfd]: https://www.documentfreedom.org/
