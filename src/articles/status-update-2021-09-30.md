---
kind: article
title: Status update, September 2021
created_at: 2021-09-30
excerpt: |
  September has been productive. I finished all but one of the tasks I had
  planned for this month and did some extra stuff. October is going to be
  overwhelming.
---

<aside markdown="1">
  If you enjoy my work, consider sponsoring me so I can keep on doing this full
  time: <https://github.com/sponsors/hugopeixoto>
</aside>

September has been productive. I finished all but one of the tasks I had
planned for this month and did some extra stuff.

## September accomplishments

Speak at [RustConf 2021](https://rustconf.com). The video, slides, and code
[are already available][rustconf-pokemon].

I fixed the [cyberscore][cyberscore] bugs I mentioned last month. When using
the old layout, users change their own profile information, so I migrated
everyone to the new layout. Moderation tools like "Revert record" and "Reset
record status" were broken, so these were fixed as well. There were also some
pages that were broken when we migrated to MariaDB, thanks to queries where you
select columns that are not aggregate or functionally dependent of the group by
expressions.

Password recovery is now available on [AlumniEI's mentorship
program][mentorados]. I also made an effort to prevent accidentally disclosing
if a user is registered on the website or not, including via timing attacks.
There's some more information on this [in the pull request
review][mentorados-pr], but I might turn it into a short blog post. The
website's portuguese translation now comforms to [gender neutral
rules][gender-neutral] instead of defaulting to male pronouns.

I started working on migrating [ANSOL][ansol]'s website from Drupal 7 to
[Hugo][hugo]. The content is all converted to markdown, now I need to work on
the website itself. I also designed the banner for their [20 year
anniversary][20anos] and did some other tasks related to that event.

I didn't find time to work on [D3][direitosdigitais] or [F-Zero Central][fzc].

[Conversas em código][coc] is back! [locks][locks] and I released episodes this
month and we have a couple more in the queue. I also found two unreleased
episodes from late 2020, so I edited them and will publish them whenever we
need to fill in a gap. Let's see if we can keep this up.

I've been playing sokoban with my hard drives, moving stuff around so I could
full disk encrypt them all. The last disk should be done today, and then I can
focus on organizing this mess.

My graphic design skills are practically non-existent and a lot of volunteer
based projects I've been working on lack someone in that department, so I
decided to read a bit about the subject. [Thinking with type][twt] was sitting
in my shelf so I started there. I'd appreciate any suggestions on what to pick
up next.


## October plans

I'll be spending approximately 20h/week on a freelancing gig for the following
three months. It's going to be a cleanup job: upgrading some dependencies,
fixing infrastructure issues, bringing terraform up to code.

I want to publish one podcast episode per week during October. It should be
doable, since we already have enough recorded material for that. I just need to
edit them.

The unnamed D3 project needs to be tackled this month. I have been delaying
this for months now, and it's a bit embarrassing. I think there's a pending
Joomla upgrade that needs attending.

I will focus on finishing ANSOL's website rewrite. I'm not expecting to finish
the whole thing since there are design and copywriting issues that need to be
solved, but I want to get it into a state where could replace the current
website.

There's also the C++ presentation that I volunteered for. I still need to do
some research and prepare the actual presentation. I'm going to talk about
`std::ranges`. There's still no fixed date, but it will be in November,
somewhere in Porto.

If there's any time left, I want to tackle F-Zero Central. This has been pretty
low on my priority list, and if I don't tackle it this month I'll have to bump
its priority in November.

Also, [Hacktoberfest][hacktoberfest] is happening. I don't think I'll organize
anything this year, but I'll probably join a local event. If you don't know
which project to contribute to, [talk to me][about]! I can probably help you
find something.


<aside markdown="1">
  If you enjoy my work, consider sponsoring me so I can keep on doing this full
  time: <https://github.com/sponsors/hugopeixoto>
</aside>


[cyberscore]: https://cyberscore.me.uk
[mentorados]: https://github.com/alumniei/mentorados
[ansol]: https://ansol.org
[hugo]: https://gohugo.io
[20anos]: https://ansol.org/20anos
[direitosdigitais]: https://direitosdigitais.pt
[gender-neutral]: https://pt.wikipedia.org/wiki/G%C3%AAnero_neutro
[mentorados-pr]: https://github.com/alumniei/mentorados/pull/37
[fzc]: https://fzerocentral.org
[locks]: https://locks.wtf/
[coc]: https://conversas.porto.codes
[rustconf-pokemon]: https://hugopeixoto.net/articles/rustconf2021-video-available.html
[twt]: http://thinkingwithtype.com/
[about]: https://hugopeixoto.net/about.html
[hacktoberfest]: https://hacktoberfest.digitalocean.com/
