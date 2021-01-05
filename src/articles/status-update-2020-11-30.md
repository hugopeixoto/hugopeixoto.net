---
kind: article
title: Status update, November 2020
created_at: 2020-12-02
excerpt: |
  No more November. I didn't blog as much this month, so this status update
  will be a bit longer than usual.
---

<aside markdown="1">
  If you enjoy my work, consider sponsoring me so I can keep on doing this full
  time: <https://github.com/sponsors/hugopeixoto>
</aside>

No more November. I didn't blog as much this month, so this status update will
be a bit longer than usual.


## D3 - Defesa dos Direitos Digitais

I started the month doing some work for [D3][D3]. We use [HackMD][hackmd] a lot
to colaborate on writing articles and researching topics, and there was some
downtime. This made us consider self-hosting our own instance so we could have
some more control over our data. I configured a new VPS and set up an instance
for our members.

I still need to figure out how to add authentication. I don't want to have to
manually send out invitations to every member that joins. We have a bunch of
services that require member authentication, and it would be nice if we could
have a single set of credentials per member. I guess what I'm looking for is a
SAML/OpenID connect solution that I can self-host. Most of the things that I
found were a bit resource intensive, so I still haven't found a solution. Maybe
I should implement one in rust :P


## HedgeDoc

While I was setting up HackMD for D3, I found out that there are multiple
versions/forks. TLDR:

- the project started as HackMD (MIT)
- it split into HackMD EE (proprietary) and HackMD CE (AGPL)
- HackMD CE was renamed to CodiMD
- there was some governance and licensing discussion
- part of the community forked CodiMD
- the forked CodiMD was in the process of being renamed to HedgeDoc
- HedgeDoc is being rewritten in nestjs+react

Initially I had setup the original CodiMD, but as soon as I found out about the
fork, I switched to the forked version. I decided to help with the rename by
working on the [container][hedgedoc-container] repository: [Rename HackMD and
CodiMD to HedgeDoc](https://github.com/hedgedoc/container/pull/119). Since
travis stopped offering an open source plan, I also helped them migrate from
travis-ci to Github Actions: [Add github actions to build
containers](https://github.com/hedgedoc/container/pull/123)

I also started working on building nightly releases and improving the dockerfiles:

- [Publish nightly docker images](https://github.com/hedgedoc/container/pull/127)
- [Split dockerfiles into stages](https://github.com/hedgedoc/container/pull/126)

I had the opportunity to add a feature to a project that you can use to
generate docker tags based on the git tag being released: [Add tag
flavor](https://github.com/crazy-max/ghaction-docker-meta/pull/15). I also
spent some time going through the open issues and PRs, closing the stale ones
that were mainly support requests and not bugs. Thanks to these contributions,
I'm now part of the HedgeDoc core team:

<https://hedgedoc.org/team/>


## Personal infrastructure

I [migrated my nameservers from AWS Route53 to my own instances of of
nsd][self-hosting-nameservers]. I'm thinking of moving the lifeonmars zones to
these instances as well, since the websites are all hosted on my machines
anyway.

I finally [figured out the passphrase of an old ssh key][ssh-bruteforce]. This
was pointless but rewarding, in a weird way. I should dedicate some time to
figure out what to do with `git.hugopeixoto.net`. I need to either fix it or
redirect it to my github account or something.

I was looking for a self-hosted solution to share a shopping list with my house
mates, and decided to try [EteSync](https://etesync.com/), but the task
applications that support it didn't work that great. I started writing a stupid
[server in rust using diesel](https://github.com/hugopeixoto/lists-server) but
didn't get very far. I need to give etesync another go.


## Cyberscore

Cyberscore is not open source yet, because there are hardcoded secrets in the
git repository and some trivial vulnerabilities that would be exposed that we
need to fix before releasing the code. This month I spent some time working in
that direction, by extracting the hardcoded secrets into a `config.ini` file.

I also changed the way we deploy things, so that root of the repository isn't
apache's DocumentRoot. This closed a vulnerability where the `.git` directory
was accessible and browsable via the web. It also lets me add files to the
repository that I don't necessarily want to end up being web served, like a
`README.md`.


## AlumniEI mentorados

I groomed the issues list added some setup instructions and contributing
guidelines. We decided to [license the code as AGPL][mentorados-agpl].

## Conversas em Código Podcast

I recorded two podcast episodes, one about hedgedoc and one about matrix. These
should be published during December.

## What's next

It's Advent of code time! I [restarted my blog this year by writing about this
contest][aoc2019], and here we are again. If I can keep up with the daily
challenges, I'll see if I can do a small write up every few days.

I'll probably have some work to do on HedgeDoc. I still have pending PRs, and
if the nestjs/react rewrite goes anywhere, the dockerfiles will need to be
rewritten to account for the repository split. I'd like to add multi-platform
support to our docker images. We're only building amd64 images, and it would be
nice to be able to host this on raspberry pis, for example.

I want to continue working a bit on Cyberscore. We talked about rewriting it
from scratch in Laravel or something, but for me that isn't as appealing as
shaping the existing code into place.

I have some issues assigned to me on mentorados that need to be finished by the
end of the year, so I'll work on that.

<aside markdown="1">
  If you enjoy my work, consider sponsoring me so I can keep on doing this full
  time: <https://github.com/sponsors/hugopeixoto>
</aside>

[D3]: https://direitosdigitais.pt
[hackmd]: https://hackmd.io
[hedgedoc-container]: https://github.com/hedgedoc/container
[mentorados-agpl]: https://github.com/alumniei/mentorados/pull/20
[aoc2019]: /articles/advent-of-code-2019.html
[self-hosting-nameservers]: /articles/self-hosting-nameservers.html
[ssh-bruteforce]: /articles/brute-forcing-my-own-passphrase.html
