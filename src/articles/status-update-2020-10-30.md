---
kind: article
title: Status update, October 2020
created_at: 2020-10-30
excerpt: |
  October is over, onto November.
---

<aside markdown="1">
  If you enjoy my work, consider sponsoring me so I can keep on doing this full
  time: <https://github.com/sponsors/hugopeixoto>
</aside>

October is known for [Hacktoberfest][hacktoberfest]. Last year I organized a
couple of local events to promote contributions and help folks get motivated.
This year, I limited myself to attending a portuguese online event:
[Interruptor x Hacktoberfest][hacktoberfest-interruptor]. In the morning I
watched some talks, and during the afternoon we worked on a [project that
displays how cultural facilities are spread throughout the
country][ate-onde-chega-a-cultura]. My main contribution was a webpage that
uses leaflet to display data dynamically fetched from wikidata:

* <https://github.com/InterruptorPt/ate-onde-chega-cultura/pull/30>

I also built a dashboard to display how many hacktoberfest-qualifying
contributions each participant had made. With all the fuss this year of how
hacktoberfest was disregarding maintainers by making projects opt-out instead
of opt-in, I had to rewrite this when Hacktoberfest changed the rules. The
dashboard itself was hosted at `hacktoberfest.hugopeixoto.net`, but since I'll
probably tear it down now that the event is over, here's the [internet archive
link][hacktoberfest-dashboard]. The source code is available on my github
account:

* <https://github.com/hugopeixoto/hacktoberfest-dashboard/>

This dashboard was written in rails, and I was growing tired of following the
setup instructions described in [a previous post][mentorados-rewrite], so I
built a rails template repository. that can be used whenever I need to start
another app from scratch. I wrote a [very short post about
it][rails-template-post], but here's the link to the repository:

* <https://github.com/hugopeixoto/rails-template>


I edited and published the 30th episode of my podcast, [Conversas em
Código][conversas]:

* [Conversas em Código #30: Lighthouse][conversas-post]

In september, I had written a couple of posts about using Bevy for gamedev.
These posts were featured on the [This Month in Rust GameDev
newsletter][rust-gamedev-newsletter]. Having spent some time experimenting with
Rust for gamedev, this month I spent some time [experimenting with Rust for
webdev][rust-webdev]. I wrote a simple file sharing website, first using
[warp][warp], then using [actix-web][actix-web]:

* <https://github.com/hugopeixoto/imghost>

This was a relatively simple website, so I didn't even bother with setting up a
database or using html templates.


Another thing that happened this month was that Rocket.Chat announced that
[they will be limiting the number of push notifications that self-hosted
instances could send through their gateway][rc-push-limit].
[D3](https://direitosdigitais.pt/) uses Rocket Chat, and we're way over the 5k
limit, so I spent some time figuring out what we should do. I wrote a blog post
about an unrelated bug we found in their React frontend:

* [Fixing a bug in Rocket Chat](/articles/fixing-a-bug-in-rocket-chat.html)

One alternative we considered was switching platforms. One thing led to another
and I spent a week learning about [Matrix](https://matrix.org), the main
company behind it, the protocols, [their processes][matrix-msc], different
implementations and clients, and [how hard it is to use a search engine to find
anything related to it][matrix-search]. I don't think they're ready to replace
our Rocket Chat instance, but I'll keep an eye on them.

In other random news, I finally took the time to stop using [The Old
Reader](https://theoldreader.com/) and started using a self hosted instance of
[Miniflux](https://miniflux.app/). I was using their free tier, and I always
had the feeling that I would lose my unread count if I didn't login in time, so
I decided to switch. Setting Miniflux in my dokku server was easy, since they
have instructions to get it deployed to Heroku. It's also nice that it's
written in Go: the app itself only consumes around 11 megabytes of RAM.

<aside markdown="1">
  If you enjoy my work, consider sponsoring me so I can keep on doing this full
  time: <https://github.com/sponsors/hugopeixoto>
</aside>

[rust-gamedev-newsletter]: https://rust-gamedev.github.io/posts/newsletter-014/#rust-gamedev-ecs-and-bevy
[hacktoberfest]: https://hacktoberfest.digitalocean.com
[hacktoberfest-dashboard]: https://web.archive.org/web/20201101174618/https://hacktoberfest.hugopeixoto.net/
[hacktoberfest-interruptor]: https://interruptor.pt/artigos/interruptor-x-hacktoberfest
[ate-onde-chega-a-cultura]: https://github.com/InterruptorPt/ate-onde-chega-cultura
[warp]: https://crates.io/crates/warp
[actix-web]: https://actix.rs/
[rust-webdev]: /articles/making-a-website-with-rust.html
[mentorados-rewrite]: /articles/rewriting-a-small-rails-and-react-application.html
[rails-template-post]: /articles/rails-template.html
[rc-push-limit]: https://forums.rocket.chat/t/final-update-on-registration-requirement-to-utilize-push-gateway/8951
[matrix-msc]: https://matrix.org/docs/spec/proposals
[matrix-search]: https://twitter.com/whitequark/status/1321172527914323969
[conversas]: https://conversas.porto.codes
[conversas-post]: /articles/conversas-em-codigo-episode-30.html
