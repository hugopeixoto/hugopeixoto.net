---
kind: article
title: Status update, May 2022
created_at: 2022-06-09
excerpt: |
  TODO Excerpt
---

<aside markdown="1">
  If you enjoy my work, consider sponsoring me so I can keep on doing this full
  time: <https://github.com/sponsors/hugopeixoto>
</aside>


## Personal infrastructure

I started the month by moving away from PTISP to a slightly cheaper host with
IPv6 support. That particular server was hosting a bunch of
[dokku](https://dokku.com) web applications, most of which could be shut down.
The only one that survived was my [Miniflux](https://miniflux.app/)
installation. Instead of serving it through dokku, I'm now using
[podman](https://podman.io/).

I've also decided, for some reason that I don't remember, to enable
[IndieAuth](https://indieauth.net/) on my domain (as an identity provider).
I implemented the necessary endpoints in a new project in Rust: <https://github.com/hugopeixoto/iars>


## Veloren

[Veloren](https://veloren.net/) is a multiplayer voxel RPG written in Rust,
fully open-source and licensed under GPL 3. I was giving it a try when I
noticed a weird NPC behavior. They would get stuck for no apparent reason in
certain positions, ending up in weird clusters:

<iframe title="Veloren path finding bug" src="https://viste.pt/videos/embed/a3fb1f86-b8fd-46c1-a935-2c7b6939a41f"
  allowfullscreen="" sandbox="allow-same-origin allow-scripts allow-popups"
  width="560" height="315" frameborder="0"
  style="margin: 2em auto; display: block"></iframe>

Since the game development is community driven and open source, I tried to
contribute with some patches. Instead of starting with the NPC bug, I searched
the issue tracker for something that felt easier so I could test the waters. I
found one that required adding a feature in one of the shaders, and submitted a
MR: [Split sky shader's twilight into dawn and dusk](https://gitlab.com/veloren/veloren/-/merge_requests/3390).

After that was done, I started tackling the NPC bug. I was able to find a
couple of bugs and fix them: [Fix path finding
bugs](https://gitlab.com/veloren/veloren/-/merge_requests/3376). Even with
these fixes applied there are still some issues. I have prepared a fix or two
for some of those, but haven't submitted MRs yet.


## ANSOL

Right now, the only way we have for members to pay their membership fees is via
bank transfer. We're working on adding a couple more payment methods, so I've
been exploring [ifthenpay](https://ifthenpay.com/)'s APIs and figuring out how
to integrate it with our systems.


<aside markdown="1">
  If you enjoy my work, consider sponsoring me so I can keep on doing this full
  time: <https://github.com/sponsors/hugopeixoto>
</aside>
