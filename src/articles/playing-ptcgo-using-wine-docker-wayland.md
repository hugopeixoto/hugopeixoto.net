---
kind: article
title: Playing Pokémon TCG online using wine, docker, and wayland
created_at: 2021-03-30
excerpt: |
  I've recently restarted playing Pokémon TCG, and wanted to try the online
  version. Since there's no Linux support, I had to try my luck with wine in a
  docker container. Had some issues getting it to work under wayland, but
  eventually managed to get everything working.
---

<aside markdown="1">
  If you enjoy my work, consider sponsoring me so I can keep on doing this full
  time: <https://github.com/sponsors/hugopeixoto>
</aside>

Back in the early 2000s, I used to play [Pokémon TCG][ptcg] (Base to Neo? I
don't think there was any competitive play back then). I remember using a deck
built around a [neo discovery Kabutops][kabutops-nd6] that was wasn't very good
but managed to win some games at the local league.

![
Kabutops from Neo Discovery. A stage 2 Pokémon, with 90 HP, with an attack
Hydrocutter: Flip a number of coins equal to the number of Energy cards
attached to Kabutops. This attack does 40 damage times the number of heads. You
can't flip more than 3 coins this way
](/articles/kabutops-nd6.jpg){:id="kabutops"}

I didn't touch the TCG again until Sun & Moon came out (2017). I played at a
theme deck tournament for a couple of weeks and attended a prerelease event for
the Guardians Rising set, but I had no time or the motivation to participate in
competitive play, so I stopped playing again. This month a new set came out
(Battle Styles), and I conviced a friend to get a prerelease kit and play some
games with me. One thing led to another, and I started buying singles and
building a few casual decks.

Thanks to the pandemic, most of the TCG events have been cancelled or moved
online. There's an official client, [Pokémon TCG Online (ptcgo)][ptcgo],
available for windows, mac, ipad, and android tablets. Since I don't have any
device running any of those systems, I decided to try my luck with wine.

I had managed to get this to working with wine before, but I was using X
instead of wayland at the time, and this time I wanted to get it working in a
docker container so I could easily port this to another computer.

I started all in, trying to get wine running under docker with wayland, but
things weren't working and I was having trouble figuring out where the problems
where coming from, so I went back to basics and installed it in the host system
instead of docker, and using xwayland. Everything worked fine with the
exception of [some known bugs][wine-ptcgo].

After doing some research, I found that wine doesn't support wayland, but folks
from Collabora [announced an experimental wayland driver][collabora] in
December, so I tried to make that work. Since I had to compile wine from
source, I tried to compile it without wayland support first just to make sure
that any problems that came up were from the wayland driver and not from me not
knowing how to compile wine.

Wine has to be compiled twice: once for 64 bits support and once for 32 bits.
Without the 32 bit version, explorer.exe worked fine, but the pokémon installer
would hang waiting on a file descriptor for something. Once I had both versions
compiled, the installer booted successfully but failed to install. I ran it
again and changed the install path from `Pokémon` to `Pokemon` and it worked,
so I figured I was missing something related to character sets or locales. The
docker image I was using didn't have locales configured, and setting that to
`en_US.UTF-8` solved the problem.

I had to tweak the user id and user groups to get video and audio working, but
I was able to get the game running. You can find the dockerfile here:

<https://gist.github.com/hugopeixoto/c55eebafa7be705e25b85aafe7dde742>

And this is how I'm running it:

~~~~
$ docker run -it --rm \
  --device=/dev/snd:/dev/snd \
  --device=/dev/dri/card0:/dev/dri/card0 \
  --device=/dev/dri/renderD128:/dev/dri/renderD128 \
  -v /run/user/1000:/run/user/1000 \
  -v $(pwd):/hostdata \
  ptcgo

$ wine start "C:\users\hugopeixoto\Desktop/Pokémon Trading Card Game Online.lnk"
~~~~

Those three device maps are needed to get audio and graphics working. The
`/run/user/` volume can probably be restricted down to `wayland-0` and
`pulse/`.

Curiously, one of the known bugs ("Interface may become unresponsive when the
window lose and regain the focus") doesn't happen using wayland. The game
window doesn't seem to be focused (the title bar is gray instead of blue), so
that's probably related. The game does crash from time to time when searching
for a match in versus mode, which is kind of annoying, but it doesn't happen
too often.

There a few things I'd like to improve on my setup, I still feel some friction
when running the game.

I can't run the wine command as the docker entrypoint command because the `wine
start` process launches a subprocess and exits, so the docker container would
terminate at launch. This means I have to launch it via the terminal and enter
the command manually, instead of running it via an application launcher. I
probably need a wrapper script to wait on a specific process.

The game [crashes when exiting][wine-ptcgo-bug-exit], which is a bit more
annoying. I have to go to the terminal and terminate the container manually.
The game is written in Unity, and whenever it crashes it spawns a "Unity crash
handler" process, so I guess I could detect its presence on the wrapper script
and exit.

I have my username and user id hardcoded in the dockerfile. I could probably
provide it in the `docker run` command with the `--user` flag.

I installed the application during run time, not during build time, so the
docker image is not enough to run the game in another computer. I'm not sure if
the installer would work headlessly, but the main problem is that I don't know
how to handle the [wine prefix][wine-prefix] directory. Most of the files are
probably static, but I need some persistence between calls to store login
credentials and cached content. I would need to understand which directories
have contents that would have to be persisted between game runs and only volume
mount them. There's also the fact that the application auto updates itself, and
these updates wouldn't be persisted. I would have to automate the download of
the installer to make the process easier.


<aside markdown="1">
  If you enjoy my work, consider sponsoring me so I can keep on doing this full
  time: <https://github.com/sponsors/hugopeixoto>
</aside>

[ptcg]: https://tcg.pokemon.com/en-us/
[kabutops-nd6]: https://bulbapedia.bulbagarden.net/wiki/Kabutops_(Neo_Discovery_6)
[ptcgo]: https://www.pokemon.com/us/pokemon-tcg/play-online/
[wine-ptcgo]: https://appdb.winehq.org/objectManager.php?sClass=version&iId=30004
[wine-wayland-ann]: https://www.winehq.org/pipermail/wine-devel/2020-December/178575.html
[wine-ptcgo-bug-exit]: https://bugs.winehq.org/show_bug.cgi?id=47441
[wine-prefix]: https://wiki.winehq.org/FAQ#Wineprefixes
