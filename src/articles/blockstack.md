---
kind: article
title: Blockstack portuguese meetup
created_at: 2019-11-01
excerpt: |
  I went to a blockstack meetup last week. I heard about it thanks to Tiago
  Alves, who built a couple of apps on top of it. It has `block` in the name,
  uses `decentralized` a lot in its description, so I binned it under
  "blockchain" stuff and didn't pay much attention to it.
---

I went to a blockstack meetup last week. I heard about it thanks to Tiago
Alves, who built a couple of apps on top of it. It has `block` in the name,
uses `decentralized` a lot in its description, so I binned it under
"blockchain" stuff and didn't pay much attention to it.

The meetup started with a brief description of what blockstack is, followed by
a showcase of apps using blockstack built by local folks.

- [Envelop](https://envelop.app/), a very simple free file-sharing app
- [Blockvault](https://blockvault.site/), a decentralized password manager for
  teams
- [Lannister](https://lannister.capital/), a wealth manager and financial
  planner
- [Recall](https://recall.photos/), an end-to-end encrypted and open-source
  photo vault app


## App mining

Before I go into further details, one thing that was mentioned is that there is
a bounty of $200k per month given to the "best apps built on Blockstack". I'm
guessing this money comes from the [$75 million they
raised](https://venturebeat.com/2017/12/04/blockstack-raises-52-million-to-build-a-parallel-internet-where-you-own-all-your-data/).
These rewards are paid in BTC and STX (Stacks tokens). App mining, despite its
name, is not a decentralized process similar to block mining. There are select
reviewers assigned by Blockstack that rank existing apps according to [certain
criteria](https://app.co/mining#how-are-apps-ranked). Blockstack will be
phasing out BTC in favor of STX.

This felt like the biggest incentive for people to build apps. Not sure what to
think of this.


## Blockstack architecture

They mentioned that blockstack is composed by a bunch of different services,
and that their goal is not to push everything into a blockchain - only the
necessary / critical information. The first app we saw on the meetup is a file
hosting service, similar to firefox send. These files don't get stored in a
blockchain, for example.

The services that I remember hearing about are Blockstack auth, Gaia, and
something about smart contracts that isn't quite ready yet. Probably related to
the STX tokens? Most projects seemed to rely on Auth and Gaia exclusively.


## Blockstack auth

[Blockstack auth](https://docs.blockstack.org/develop/overview_auth.html) seems
to be a decentralized protocol to register accounts and a way for apps to have
access to account information. Something like namecoin (for unique user
identification) meets OAuth. Apparently, they did use namecoin at some point in
the past, but have [now migrated to storing this on the Bitcoin
chain](https://docs.blockstack.org/core/naming/comparison.html#blockstack-vs-namecoin).
Block heights from [their explorer](https://explorer.blockstack.org) seem to
match bitcoin block heights.

When an app asks for authorization, it can specify some scopes, just like
OAuth. Not many scopes are available right now. Only `store_write`,
`publish_data`, and `email`. This protocol seems to use JWT, with the `ES256K`
algorithm. This doesn't seem to be in standard JWT libraries, so Blockstack
provides ruby and javascript libraries that implement this algorithm.

The `store_write` scope grants the app access to an app specific storage
bucket. Storage is implemented by the Gaia protocol/service.


## Blockstack Gaia

[Blockstack Gaia](https://docs.blockstack.org/storage/overview.html), the
storage service, seems to be independent of blockchain usage. You can host it
anywhere, it is HTTP based, and URLs are in the format
`https://<domain>/<prefix>/store/<address>/<filename>`. There is no read access
control. If you know the URL, you can access the file. Writing to files
requires that you have a token signed by the private key corresponding to
`<address>` ( with a challenge which seems to be static per server).

Sharing a storage namespace between multiple users doesn't seem to be super
easy (Blockvault is trying to implement this to share password vaults). I found
something regarding [scoping support in authentication
tokens](https://github.com/blockstack/gaia/issues/142), but the README doesn't
mention this.

Gaia doesn't provide any guarantee of availability / resilience. It's a simple
read/write protocol on top of HTTP. You host it on your own infrastructure.
They provide backend drivers for AWS S3 and Azure Blob Storage, but have
documented the driver API. You can also host them in your own hard drives.

Any encryption should be done by the writer, and it's not enforced by the
servers.


## Integration

Most of the developers that presented their apps mentioned that it was super
easy to integrate blockstack into their apps. There are iOS, Android, and
javascript SDKs which do most of the heavy lifting (including encrypting files
before uploading). They seemed to be mostly focused on design and user
experience. They all seemed to have the same grievances with some of Gaia
limitations.

Blockstack offers gaia storage to everyone, with some limits (20 writes per
second, max 5mb per file). Due to this limitation, Envelop.app splits files
into chunks of 5mb. This makes their app available to anyone using blockstack's
storage. Having the default storage option limited to 5mb means that apps must
use these limits, even if users have their own storage with higher limits. From
what I could gather, Gaia does not expose these limits in their discovery
endpoints, so developers can't optimize for this.


## Thoughts

I registered an identity and, four hours later, it showed up in their block
explorer, under "Subdomain registration". Since Blockstack is sponsoring the
name registrations (if they're stored in the bitcoin chain, there's a cost to
it), they're probably batching registrations. My identity is
`hugopeixoto.id.blockstack`. Note that this is a subdomain of `id.blockstack`,
which I assume is a top level name controlled by Blockstack, the company.

Gaia feels more like a fediverse/indieweb/self-hosting project. If there was no
free hosting by blockstack, I'm not sure so many would use this. I wonder if
there are any gaia service providers.

Registration taking forever doesn't seem very good for Blockstack auth. After
talking with some of the app developers, I felt like this is something that
could be replaced with a [IndieAuth](https://indieauth.com/) protocol. This
would mean using DNS instead of <abbr title="Blockstack Naming
Service">BNS</abbr>. In IndieAuth, you own your own domain and use it to log
in. You could also use a subdomain from an identity provider you trust (in the
same way that Blockstack controls `id.blockstack`). Although I guess that in
blockstack's scenario, transferring a subdomain could mean that it becomes self
sovereign. [Apparently BNS subdomains are not stored
on-chain](https://docs.blockstack.org/core/naming/namespaces.html), so I'm not
sure how that works.

Most apps presented during the meetup are open source. It could be worthwhile
to port the blockstack SDK to an IndieAuth implementation.
