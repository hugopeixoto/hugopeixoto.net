---
kind: article
title: Reflections on 2023
created_at: 2024-01-05
excerpt: |
  It's 04:00 and I can't sleep, so here's an update. I stopped writing monthly
  updates a year ago, so this is an attempt at making up for it.
---

<aside markdown="1">
  If you enjoy my work, consider sponsoring me so I can keep on doing this full
  time: <https://github.com/sponsors/hugopeixoto>
</aside>

It's 04:00 and I can't sleep, so here's an update. I stopped writing monthly
updates a year ago, so this is an attempt at making up for it.


## ANSOL

Most of my time was split on [ANSOL][ansol] tasks. I won't get into details on
all of the tasks, but did a bunch of things:

- met with Portuguese Members of the European Parliament to discuss [Chat Control][chatcontrol];
- networked on ANSOL's behalf during FOSDEM and its surrounding events;
- helped organize a [MiniDebConf in Lisbon][minidebconfpt23];
- wrote and submitted a [contribution to the public consultation by FCT on open access][fct-oo];
- kept our [event agenda][ansol-eventos] up to date;
- migrated [our website on DRM][drmpt] from a Wordpress installation to Hugo;
- wrote the quarterly updates newsletter ([Q1][q1], [Q2][q2], [Q3][q3], [Q4][q4]);
- kept our accounting up to date, including writing 2022's financial report;
- kept our membership list and annual payments up to date;
- found someone to design a new t-shirt (this is still work in progress);
- led the efforts to organize our flagship event, [Festa do Software Livre][fsl2023], including:
  - creating and keeping the website up to date;
  - fine tuning the schedule with every track organizer;
  - procuring accomodation, free for students from out of town;
  - procuring lunch, free for attendants;
  - inviting and managing speakers for three tracks (2x ANSOL and DevPT);
  - coordinating the schedule of the members that volunteered to be at our booth;
  - writing a final report to share with sponsors and partners;
  - managing our income and expenses, including writing an accounting report;
  - setting up, monitoring, and fixing the A/V configuration;
  - and, generally, pushing the other organizers to do things.
- designed our new roll-up;
- set up a booth and represented ANSOL at a job fair on [ENEI][enei];
- edited and published [Joana Simões's talk during our Hacktoberfest event][h23];
- changed our infrastructure from an LXD mishmash to podman containers;

Something worth detailing is the A/V setup during Festa do Software Livre. Like
most things, everything was decided last minute. The University lent us three
cameras, and we had no idea what to do with them. The initial plan was just to
record things, but these were USB cameras, and they didn't have built-in
storage. We got [DETI][deti] to lend us three shiny new laptops, but they
didn't have enough storage to store footage for three whole days (and they were
running windows, which is not an ideal setup for a FOSS conference). Thankfully
the Ubuntu community booth had some Ubuntu-branded USB sticks, so we used them
as Live installs, installed OBS, and streamed the event to Youtube, on
UbuntuPT's channel. This would allow us to fetch the recordings later on. It
was not great because we had to set up everything from scratch every day, and
the computers couldn't be shut down, but it worked. There were a few blips
during the day (OBS occasionaly stopped streaming and had to be rebooted) but
for something that was configured last minute, it was OK.

The LXD to podman migration was interesting. We were continuously having
problems with our setup: HTTPS certificates were failing to be renewed every
three months, and we ran out of disk space a couple of times. This was mostly
thanks to the mess that the server was in. It was running Ubuntu with LXD
(installed via snap) with five containers, one running [haproxy][haproxy] and
one per application ([gitea][gitea], [saucy][saucy], [freescout][freescout],
and [pretalx][pretalx]). To top it off, saucy was running in a Docker container
inside the LXD container. We were running out of space because LXD was using a
single small ZFS storage pool, and the HTTPS certificates were being renewed
but not reloaded by haproxy. I decided to simplify things and removed all the
snap/LXD stuff and configured podman containers instead, with [Caddy][caddy]
installed directly on the host to deal with the certificates and reverse
proxying. I had to write a [Dockerfile for freescout][freescout-container], but
everything's working now and it's a bit more reproducible.

## D3

My involvement with [D3][d3] grew a bit this year. I mostly do tech stuff, like
managing our infrastructure. Starting in July, I got a grant to work one day
per week on the [Chat Control][chatcontrol] campaign. During that time, I
created the website, subtitled the portuguese video, designed/adapted a flyer,
translated an MEP phone call scheduling tool, and set up a mailing list server.

Other tasks I worked on during 2023:

- migrated our infrastructure (email and websites) from one web hosting provider to another;
- helped upgrade our website's joomla version;
- set up a [NocoDB][noco] service;
- worked on a new website, a catalog with books and movies related to digital rights;
- started an archival project of a portuguese video hosting website;

[SAPO Vídeos][sv] is (was?) a Portuguese website where users could upload
videos, like a Portuguese youtube. On 2023 they announced that they were going
to erase all uploaded videos (except for B2B partner channels). There was some
talks on social media about archiving things before they were deleted, so I
started working on it. The first step was to scrape the whole website to
download as much metadata as I could. Having created a small database with
information on every video I could find, I created a website/platform to
crowdsource downloading all the videos. The main tool was a bash script that
connected to the website, requested N videos URLs, downloaded them, and then
reported them back as downloaded so that they would be deprioritized. There are
some stats (in portuguese) on the [archival project's website][sapo].


## Porto Codes

We tried to restart the meetup during 2023, with little success. We managed to
do four events: two with talks and two just dinner.

I'm going to try again this year, and I found someone else to help. The hardest
part right now is finding speakers, since I haven't done much networking with
programmer folks.

Something that I'm not looking forward to is having to deal with A/V stuff
again. The biggest problem is usually recording the speakers' screen. We don't
want to require them to install OBS or tinker with VDO.ninja or anything like
that, but all of the solutions we've tried so far didn't work out that well.


## Cyberscore

I didn't focus much on [Cyberscore][cs] this year, but I did manage to
implement some things.

Every year or so, we tend to run out of disk space on the server. This happens
because players can upload screenshots of their scores, and these are uploaded
to the server instead of using some sort of elastic object storage service. In
2018 or something like that some of these screenshots were moved to an AWS S3
bucket, but there was no automation in place to do this: it was a one-off
operation. In 2021 I removed the resizing operation we were doing on upload
because some of the screenshots were unreadable, making them useless. This
caused the disk space problem to become more frequent. To fix this problem, I
introduced a couple of scripts to automate moving these screenshots to S3. We
could probably upload them directly to S3, but this helps us keep costs under
control: we won't pay more unless we run the script.

Speaking of AWS, we're using AWS SES to send emails: registration, password
recovery, and other notification-type messasges. Something that has happened
once or twice is that our spam/bounce threshold gets too high and we get
blocked from sending emails. This happened again in 2023, so I had to put some
additional measures in place. The first step was to add some event logging, so
we could see what was going on. After that, I added a shadow ban feature on
registration to prevent some domains from registering - we were getting daily
registrations from `expl0it.store`, for example. This reduced the noise a bit.
The final measure was to move the regisstration confirmation email from being
sent automatically on registration to having to be explicitly requested upon
the first login. This is a bit less streamlined, but it helps reduce email
usage during spam registration spikes.

Another big task was implementing an auto-submitter tool for Pokéclicker
scores. I wrote [a blog post about this][pk], but to summarize, this tool is a
web page where you can upload your save file and it will parse it, extract your
current scores, and submit them to Cyberscore. This is an idle game with 8000
score charts, so automation is definitely needed.

Mass submitting this many scores at once completely broke the website, so I
added a new queueing functionality, where scores can be mass submitted but are
only processed by a worker queue. I found out that our codebase isn't very
friendly for worker queues, particularly when it comes to handling mysql
connections. If the connection on the worker breaks for some reason (like
restarting mysql), the worker will continuously fail to do any operations and
won't recover. This is something that I want to address soon, because right now
I have to restart the worker from time to time.

Finally, I did some progress on our migration to Twig templates. There's not
much left - around 50 raw PHP templates) - so hopefully this gets done in 2024.


## Self-hosting

I mentioned that 2023 was going to be my personal year of self-hosting. I did
some progress on that, but not as much as I'd like.

I managed to migrate my podcast, [Conversas em Código][coc], away from
Simplecast and into a static website. It's nothing fancy, just a ~100 line ruby
script and a markdown file per episode. I just noticed that the repository
isn't published anywhere, I'll probably push it to the
<https://github.com/portocodes/> organization. Unfortunately I didn't publish
many episodes this year.

I'm also self-hosting Uptime Kuma, which I use to keep an eye on the
infrastructure I manage (ANSOL, D3, Cyberscore, and some clients' websites).
This is running on a server in my office, so it has the occasional downtime
when the ISP blips, I reboot the router, or the power goes down, but it's good
enough for my use case.

I played with NixOS a bit, when I was migrating some of ANSOL's servers. I
managed to set up a few podman containers with TLS termination on nginx, but I
feel like I'm still missing something. Using containers probably negates a lot
of the advantages of using NixOS, and I didn't get as far as configuring
something like `nixops` for full reproducibility. I'll have to play with it a
bit more.

I have another server at home running [restic][restic], with backups from
Cyberscore, [F-Zero Central][fzc], and D3. I haven't had to use it yet, thankfully,
but I do check from time to time that backups are being made daily and that I
can retrieve them.

I'm still hosting a peertube instance at <https://viste.pt>. It mostly serves
as a place to upload videos from ANSOL, D3 and Porto Codes, but I also use it
to upload personal tech experiments.


## Plans for 2024

During 2024 I want to keep working for ANSOL - we have some interesting
projects in the works - but I also want to go back to having a (close to) full
time developer job. It's been three years, and I think I'm ready to get back
into it. I'll be aiming for FOSS adjacent companies / non-profits.

I feel like during 2023 I didn't do much programming. I was focused on event
organizing and FOSS advocacy. That's something I hope I get to change.


<aside markdown="1">
  If you enjoy my work, consider sponsoring me so I can keep on doing this full
  time: <https://github.com/sponsors/hugopeixoto>
</aside>

[ansol]: https://ansol.org/
[ansol-eventos]: https://ansol.org/eventos/
[minidebconfpt23]: https://pt2023.mini.debconf.org/
[q1]: https://ansol.org/noticias/2023-05-26-boletim-2023-1-trimestre/
[q2]: https://ansol.org/noticias/2023-07-05-boletim-2023-2-trimestre/
[q3]: https://ansol.org/noticias/2023-11-13-boletim-2023-3-trimestre/
[q4]: https://ansol.org/noticias/2024-01-02-boletim-2023-4-trimestre/
[fct-oo]: https://ansol.org/noticias/2023-05-28-consulta-publica-fct/
[fsl2023]: https://festa2023.softwarelivre.eu/
[h23]: https://ansol.org/recursos/como-contribuir/
[enei]: https://enei23.pt/
[chatcontrol]: https://chatcontrol.pt/
[noco]: https://www.nocodb.com/
[cs]: https://cyberscore.me.uk/
[pk]: /articles/more-fresh-shenanigans.html
[drmpt]: https://drm-pt.info/
[coc]: https://conversasemcodigo.pt/
[gitea]: https://about.gitea.com/
[saucy]: https://git.ansol.org/ansol/saucy
[freescout]: https://freescout.net/
[freescout-container]: https://git.ansol.org/ansol/freescout/
[pretalx]: https://pretalx.com/
[haproxy]: https://www.haproxy.com/
[caddy]: https://caddyserver.com/
[sapo]: https://sapo.pxto.pt/
[d3]: https://direitosdigitais.pt/
[sv]: https://videos.sapo.pt/
[restic]: https://restic.net/
[fzc]: https://fzerocentral.org/
[deti]: https://www.ua.pt/pt/deti
