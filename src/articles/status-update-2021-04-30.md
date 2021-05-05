---
kind: article
title: Status update, April 2021
created_at: 2021-05-05
excerpt: |
  April is over, and so are my current consulting gigs. I moved to a new
  apartment and had to deal with two security breaches.
---

<aside markdown="1">
  If you enjoy my work, consider sponsoring me so I can keep on doing this full
  time: <https://github.com/sponsors/hugopeixoto>
</aside>

Most of my month was spent packing things and moving them to the new place.
Unfortunately, this was also the month where two websites that I help maintain
were hacked, so I had to deal with that.


## ink! upgradeability gig

During the review process, it came up that the testing process should be
automated. I spent a couple of days working on this
(<https://github.com/trustfractal/ink-upgrade-template/pull/2>) and afterwards
the project was accepted.


## AlumniEI Mentorados

We had a pending PR to deal with dark/light/system theme toggling. The user
preferences were being persisted, but there was no effect on the CSS, so I
finished implementing it. I also implemented language detection based on
`Accept-Language` (<https://github.com/alumniei/mentorados/pull/21>).


## Cyberscore

On April 24th, a group of people joined our discord and started bragging that the
website was now theirs. They had found a way to login as any user. Since no one
from the staff team was online at the time, they got not attention so they
started escalating the damage and eventually found a way to our builtin SQL
editor and dropped every database table.

When I found this, the website was non-functional, so I shut down apache and
started looking for the vulnerability. Our logging capabilities are
non-existent, so I had to rely mostly on the discord chat and apache logs to
find what had happened. The attackers had used the live search to find a user
that they wanted to harass, so I was able to track their IP addresses and grab
their history of HTTP requests.

From their request history, I was able to find a pattern in which the attackers
accessed the forgot password pages, went through all the steps, and ended up in
the `/user/:id` page, with a different id every time. This pointed to the
vulnerability being in the "forgot password" functionality. Running the site
locally, I tried to recover the password of a random user, and one of the steps
is to either answer a secret question or enter a code that was sent to the
user's email. I tried leaving that field blank, and the website let me proceed
to change the user's password.

Going through the code to find the problem, I found this (reformatted for clarity):

~~~~php
if ($p_verification != "") {
  if ($vanswer != $p_verification) {
    $_SESSION['authed'] = "n";
    db_close();
    header("Location: resetpass_2.php?err=wrong");
    exit;
  }
}

// proceed to the next step
~~~~

The surrounding `if` statement is the cause of the vulnerability. Removing it
fixes the immediate problem. It had been there for years, it's kind of
surprising that it had only been found now.

I ended up rewriting the whole thing, only allowing recovery via email code
(and not via secret question), and fixed a few other vulnerabilities in the
process.

Unfortunately, we don't have automated backups, and the last backup I had made
was from the beginning of March, so we lost practically two months of data
(around 11k submissions).

This was a very low effort exploit, dropping tables wasn't that damaging. They
could've compromised the server, or deleted the image proofs, which were not
backed up at the time.

My next step is to automate the backup process and probably remove the builtin
SQL editor. It's handy for folks who are not used to dealing with SSH, but it
creates a huge hole in the website.


## F-Zero Central

[F-Zero Central](https://fzerocentral.org) is a community with leaderboards,
world record tracking and forums around the F-Zero games. I don't maintain the
website, but I did help them migrate servers in the past with some ansible
automation. It's a PHPBB installation with some extra pages and other tweaks.

On April 18th, the website's front page was replaced with one of those generic
"HaCkEd By \<xxx\>" messages. The PHPBB installation is super old (it's still
running 2.x), so there are probably a lot of known exploits.

I'm working on upgrading it to PHPBB 3.3. Not sure if we'll restore the website
before the upgrade is complete, but this will probably take a while.


<aside markdown="1">
  If you enjoy my work, consider sponsoring me so I can keep on doing this full
  time: <https://github.com/sponsors/hugopeixoto>
</aside>
