---
kind: article
title: Self-hosting nameservers for my domains
created_at: 2020-11-16
excerpt: |
  In an attempt to self-host all the things, I decided to try self-hosting
  nameservers for my domains.
---

<aside markdown="1">
  If you enjoy my work, consider sponsoring me so I can keep on doing this full
  time: <https://github.com/sponsors/hugopeixoto>
</aside>

## Introduction

In an attempt to self-host all the things, I decided to try self-hosting
nameservers for my domains. When I first bought my domains, I was using the
nameservers provided by the registrar. Eventually, I moved them to Route53 so
that I could manage the records in a git repository and apply them via
terraform. Now I just want to get rid of third-parties while still being able
to manage changes via CLI. By hosting my own nameservers, I can keep track of
the zone files in a git repository and rsync them or something to apply the
changes. I bought a new domain I was planning on acquiring anyway so I could
mess with nameservers without breaking any of my existing websites.

## Choosing the software

I know I'll need to run one authoritative nameserver (or two, if I care about
redundancy), hosting the DNS [zones][rfc2181-zone] for the domains I want to
manage. I once implemented a [toy nameserver][dns-hobby], but it's not exactly
production ready. Going in, I knew of a few options: [BIND][bind],
[PowerDNS][powerdns], and [djbdns][djbdns]. After asking around, I found out
about [NSD][nsd] and [YADIFA][yadifa]. I decided to start with djbdns, whose
implementation is the smallest, at around 10k lines of code.

I started by launching tinydns (the authoritative server in the djbdns package)
inside an [Alpine Linux][alpine] container. I installed the server via `apk add
djbdns`, and created a data file with the following:

~~~~
.example.pt:127.0.0.1
=example.pt:127.0.0.2
=another.example.pt:127.0.0.3
~~~~

Note that djbdns doesn't use the common [zone file format][zone-file], which is
not trivial to parse, opting instead for a format that's easily edited by
machines and ["reasonably easy for humans to edit"][djbdns-format]. The first
character of each line indicates the type of resource that should be created.
Tinydns doesn't use this file directly, though. You need to convert it using
`tinydns-data`, which creates a `data.cdb` file that's optimized for serving
information. Here's the list of commands I used to get tinydns running:

~~~~
container:/# cat data
.example.pt:127.0.0.1
=example.pt:127.0.0.2
=another.example.pt:127.0.0.3
container:/# apk add djbdns
container:/# tinydns-data
container:/# mkdir /dns
container:/# cp data.cdb /dns
container:/# UID=0 GID=0 ROOT=/dns IP=0.0.0.0 tinydns
~~~~

I was running the docker container with a port map of 53 to 5300 so that I
could test the nameserver from my host without reserving my computer's 53 port.
To see if things were working, I used `dig`:

~~~~
laptop:~$ dig +short example.pt @127.0.0.1 -p 5300
127.0.0.2
laptop:~$ dig +short another.example.pt @127.0.0.1 -p 5300
127.0.0.3
~~~~

This was all working fine, so I started converting my zone file to the djbdns
format, when I came across an IPv6 record. [Alpine's wiki page on the tinydns
data format][alpine-tinydns-format] indicated that I should add a line starting
with `:`. Other pages mentioned using `3`. Neither of these worked, erroring
out with an unknown leading character error.

Djbdns is not very typical. Its last release was in 2001, and features like
IPv6 and DNSSEC are not supported. These features are available through third
party patches. If we look at [Alpine Linux's build of djbdns][djbdns-apkbuild],
we'll find that there are a bunch of patches listed:

* https://www.fefe.de/dns/djbdns-1.05-test25.diff.bz2
* headtail.patch
* dnsroots.patch
* dnstracesort.patch
* djbdns-1.05-jumbo-josb.patch
* 1.05-errno.patch
* 1.05-response.patch

The first patch in the list is a [well known IPv6 patch][fefe-ipv6], although
it's using an outdated version (25, from 2011, instead of 28, from 2016). The
`jumbo-josb` patch seems to be a merged version of `jumbo-p13` and a patch that
adds `SRV` and `NAPTR` support. `jumbo-p13` is a [collection of thirteen
patches][jumbo-p13], one of which also adds `SRV` support. The other patches
don't add any features and are mostly about fixing the build. I downloaded the
IPv6 and confirmed that it was adding `3` and `6` as leading character options,
so I started suspecting that something was wrong with their build.

The first thing I noticed was that the patch was the only one that was being
downloaded instead of [being commited to the repository][aports-repository]. It
was also the only `.diff.bz2` file, with all the other patches being `.patch`
files. Checking the [APKBUILD file history][apkbuild-log], I found the [commit
that added the IPv6 patch][apkbuild-ipv6], and part of the diff was a bit
suspicious:

~~~~diff
-build() {
- cd "$srcdir"/$pkgname-$pkgver
- for i in ../*.patch; do
-   msg "Applying $i..."
-   patch -p1 < $i || return 1
+_builddir="$srcdir"/$pkgname-$pkgver
+prepare() {
+ cd "$_builddir"
+ for i in $source; do
+   case $i in
+   *.patch) msg $i; patch -p1 -i "$srcdir"/$i || return 1;;
+   *.diff.gz) msg $i; gunzip -c "$srcdir"/$i | patch -p1 || return 1;;
+   esac
~~~~

This commit added a `diff.bz2` source, but the loop that applied the patches
was modified to handle `.diff.gz` files. In a [later
commit][apkbuild-modernize], the loop was replaced with a call to
[`default_prepare`][default-prepare], a function that handles `.patch`,
`.patch.gz`, and `.patch.xz` files. So it seems like the patch has just sitting
there, never being applied.

To double check that the patch was not being applied, I changed the APKBUILD
file to use a local copy of the patch instead of downloading the `.diff.bz2`
file and tried to build the package. I suspected that the patch wouldn't apply
cleanly, given that it's a relatively large patch and it would probably
conflict with the jumbo patch. I installed the `abuild` tool via `apk add
alpine-sdk`, cloned the aports repository, changed the `main/djbdns/APKBUILD` file,
and ran `abuild checksum && abuild`, and it failed almost immediately:

~~~~
container:/build/aports/main/djbdns$ grep source APKBUILD -A3
source="https://cr.yp.to/djbdns/$pkgname-$pkgver.tar.gz
        djbdns-1.05-test25.patch
        headtail.patch
        dnsroots.patch
container:/build/aports/main/djbdns$ abuild checksum && abuild
>>> djbdns: Fetching https://cr.yp.to/djbdns/djbdns-1.05.tar.gz
>>> djbdns: Updating the sha512sums in APKBUILD...
>>> djbdns: Building main/djbdns 1.05-r47 [...]
>>> [...]
>>> djbdns: Unpacking /var/cache/distfiles/djbdns-1.05.tar.gz...
>>> djbdns: djbdns-1.05-test25.patch
patching file FILES
patching file Makefile
patching file README.ipv6
[...]
>>> djbdns: headtail.patch
patching file Makefile
Hunk #2 FAILED at 205.
Hunk #3 succeeded at 495 (offset 46 lines).
Hunk #4 succeeded at 628 (offset 58 lines).
Hunk #5 succeeded at 816 (offset 58 lines).
Hunk #6 succeeded at 1004 (offset 103 lines).
1 out of 6 hunks FAILED -- saving rejects to file Makefile.rej
>>> ERROR: djbdns: prepare failed
~~~~

The build didn't even had to get to the jumbo patch to hit a conflict. I tried
moving the patch around, which fixed the conflicts with the smaller patches,
but I found no way of avoiding conflicts with the jumbo one, and these are both
significant changes, so I opened an issue on alpine's repository:

* [djbdns: ipv6 patch not being applied][alpine-issue]

To be honest, I'd rather not deal with any of this. Managing third party
patches and ensuring that you're not messing anything up when merging them
doesn't sound very secure. Debian used to maintain a fork, [dbndns][dbndns],
with a few patches applied, but they ended up dropping it. I could spend some
time looking for a decently maintained fork, but I'd rather switch to another
nameserver.

I switched to [NSD][nsd], whose codebase is also on the small side when
compared to BIND. NSD uses standard zone files, so I started writing a zone
file for my domain:

~~~~
$ORIGIN example.pt.
$TTL 300
@ IN SOA a.ns root 1 7200 3600 1209600 3600
@ IN NS a.ns
@ IN NS b.ns
@ IN A 127.0.0.1
@ IN AAAA ::1

a.ns IN A 127.0.0.2
b.ns IN A 127.0.0.3
~~~~

I stored this in a `/zones/example.pt` file, and edited the NSD config file to
read it:

~~~~
zone:
  name: example.pt.
  zonefile: /zones/example.pt
~~~~

With `nsd -d` running, I was able to query these names from my laptop,
including the IPv6 record:

~~~~
laptop:~$ dig +short example.pt @127.0.0.1 -p 5300
127.0.0.1
laptop:~$ dig +short a.ns.example.pt @127.0.0.1 -p 5300
127.0.0.2
laptop:~$ dig +short b.ns.example.pt @127.0.0.1 -p 5300
127.0.0.3
laptop:~$ dig +short example.pt @127.0.0.1 -p 5300 AAAA
::1
~~~~

With a zone working, I installed NSD in two of my servers. One of them is
running Debian 10, and I had no issues installing and configuring it. The other
server is running Ubuntu 18.04, and things were a bit harder. Apparently
`systemd-resolved` binds port 53, so NSD wasn't able to start. Since my
/etc/resolv.conf isn't pointing to the systemd dns server, I disabled it by
setting `DNSStubListener=no` in `/etc/systemd/resolved.conf`.

Now that I had both nameservers working, I had to configure the domain to
actually use them.

## Setting DNS glue records

When you register a domain, you usually set its nameservers by going to the
registrar's dashboard. They'll probably default to the registrar's nameservers,
and if you use route53, you'll need to change them to something like
`ns-YYYY.awsdns-YY.{org,net,com,co.uk}.`. These are stored as `NS` entries in
the domain's top level domain zone. In this case, I want to use my personal
nameservers, but I can't just put the IP addresses in there; NS records require
a name.

Since I'm only messing with one domain, my nameservers would have to have names
in the domain they're managing: `a.ns.example.pt` and `b.ns.example.pt`, for
example. Setting these as NS records in the TLD zone wouldn't be enough though,
as we'd be causing a chicken-and-egg problem. To resolve `example.pt`, you'd
need to access `a.ns.example.pt`, which lives inside the `example.pt` zone.
You would have no IP addresses to query. This is where glue records come in.
Instead of just defining the NS record on the TLD, you're also allowed to add
some A records for the names used in NS entries. These are returned as non
authoritative answers, in the additional section of the response, to help you
break the loop.

The registrar that I'm using, [PTisp][ptisp], doesn't seem to expose the glue
records functionality to its clients. I found no way of setting the IP
addresses of my nameservers. I've contacted their support, which was a
frustrating experience:

- First, they told me I needed to go to dns.pt, the website of the TLD, and set
  the glue records there, but only if I was the technical manager of the domain
  (which I'm currently not, they are);
- I replied asking if that meant that they have no way of letting customers set
  the glue records, and if I had to take over the technical management of the
  domain;
- They replied saying that in the .pt TLD there's no concept of glue records,
  and that I could just go to the registrar's DNS management tool and set two A
  records;
- I replied letting them know that there are plenty of portuguese domains with
  glue records, and asking them to clarify what they meant by "setting two A
  records";
- They replied saying that in .pt domains, I could just create two A records in
  the registrar's tool, and that they would automatically become glue records;
- At this point I was like "whatever I'll create the records", which obviously
  didn't do anything in terms of glue records, and didn't even set the NS
  records at the TLD level. I reported all of that back to them;
- They told me that now they could proceed with setting the glue records
  manually, or that, alternatively, they could hand me the technical management
  of the domain so I could do it myself.

After this kind of useless round of interactions, I feel like I ended up where
I started, so I'm currently waiting for them to transfer management to my
account.

I also found out that their VPS service doesn't support IPv6, so one of my
nameservers will have to be IPv4 only, I guess. I'm starting to question if I
should start looking for an alternative provider.

## Conclusions

I started by experimenting with [djbdns][djbdns], found a bug in the alpine
package, and ended up switching to [NSD][nsd] to avoid having to manage third
party patches. I tried to set up glue records and had an awkward interaction
with my registrar.

I'm still waiting for my registrar to set up the glue records, but hopefully
that will be the last step. Meanwhile, I'll start writing zone files for the
other domains. I'm hoping that by the end of the month I will no longer be
using Route53 for any of my personal domains. No more $0.50 per domain per
month for you, Amazon!


<aside markdown="1">
  If you enjoy my work, consider sponsoring me so I can keep on doing this full
  time: <https://github.com/sponsors/hugopeixoto>
</aside>

[dns-hobby]: https://github.com/hugopeixoto/dns
[bind]: https://www.isc.org/bind/
[djbdns]: https://cr.yp.to/djbdns.html
[powerdns]: https://www.powerdns.com/
[nsd]: https://www.nlnetlabs.nl/documentation/nsd/
[yadifa]: https://www.yadifa.eu/
[alpine]: https://alpinelinux.org/
[alpine-issue]: https://gitlab.alpinelinux.org/alpine/aports/-/issues/12099
[alpine-tinydns-format]: https://wiki.alpinelinux.org/wiki/TinyDNS_Format
[fefe-ipv6]: https://www.fefe.de/dns/
[djbdns-apkbuild]: https://git.alpinelinux.org/aports/tree/main/djbdns/APKBUILD
[djbdns-format]: https://cr.yp.to/djbdns/tinydns-data.html
[zone-file]: https://en.wikipedia.org/wiki/Zone_file
[jumbo-p13]: http://lkr.sourceforge.net/djbdns/mywork/jumbo/index.html
[aports-repository]: https://git.alpinelinux.org/aports/tree/main/djbdns
[apkbuild-log]: https://git.alpinelinux.org/aports/log/main/djbdns/APKBUILD
[apkbuild-ipv6]: https://git.alpinelinux.org/aports/commit/main/djbdns/APKBUILD?id=564452f0de9f0b04d025b3a06480896206d9e596
[apkbuild-modernize]: https://git.alpinelinux.org/aports/commit/main/djbdns/APKBUILD?id=1db1917442cb087f602dc69b36d22b33b04c05ea
[default-prepare]: https://git.alpinelinux.org/abuild/tree/abuild.in?id=8ceca11831a3990a14f92ab6aeb83a4b1d54be2b#n691
[dbndns]: https://web.archive.org/web/20150919154039/https://packages.debian.org/unstable/dbndns
[rfc2181-zone]: https://tools.ietf.org/html/rfc2181#section-6
[rfc2181-zone-auth]: https://tools.ietf.org/html/rfc2181#section-6.1
[ptisp]: https://ptisp.pt/
