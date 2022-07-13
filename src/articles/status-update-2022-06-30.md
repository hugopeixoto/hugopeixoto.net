---
kind: article
title: Status update, June 2022
created_at: 2022-07-12
excerpt: |
  Cyberscore ran out of space so I had to shuffle some things around. ANSOL is
  replacing their CiviCRM installation with a custom made solution.
---

<aside markdown="1">
  If you enjoy my work, consider sponsoring me so I can keep on doing this full
  time: <https://github.com/sponsors/hugopeixoto>
</aside>

## Personal Infrastructure

My backup server (which stores backups for cyberscore.me.uk and other websites)
is at 73% of disk capacity. It's has a single HDD of 300GB, so I'm replacing it
with a 4TB HDD. The server only has one disk bay, so replacing it will be a bit
troublesome, but I'll need to get it done soon.


## Cyberscore

I had to fix an outage caused by a corruption on the `games` table. We were
adding a new column to the start of the table and somehow the data didn't shift
correctly or something, corrupting practically everything. Thankfully this
table doesn't get updates often (only when a new game is added to the website),
so restoring it from the daily backup wasn't a big problem.

A few days prior, we had merged some untested code that broke some things, so I
took the opportunity to fix those as well. I also removed a couple of concepts
that were no longer used (splits and DLC preferences) that resulted in the
removal of ~500 lines of code.

Shortly after fixing the corruption, the disk ran out of space. Now that we
don't scale down submission proofs, they're taking a lot more disk space than
usual. I started by deleting some old local backups to clear up some room just
to make the website work again while I figured out the next step.

We're already storing some of the old proofs on an AWS S3 bucket, so it was
time to migrate some more. Uploading things took a while, because I took the
opportunity to rename the files to their SHA256 checksum instead of database
id. By making them content-addressable, I saved around 6GB of duplicate proofs
(sometimes a single screenshot acts as proof for a bunch of charts).


## ANSOL

Internally, we use [CiviCRM](https://civicrm.org/) to keep track of
memberships, payments and payment reminders. CiviCRM is a very powerful tool,
but it hasn't been working for us. In part, it's due to the customization it
requires and the time we'd have to spend to learn how to use it effectively,
but it's also because we don't want to maintain the host platform -- CiviCRM
needs to be applied to a CMS (Drupal, in our case).

We've had new membership requests and due payments left without any feedback
for weeks because it's too troublesome to register them. This is not
acceptable, so I'm working on a replacement. I'm not sure that this will fix
our underlying issue, but I have all the required functionality working so I'll
probably deploy it this week so we can give it a go. It's basically a
spreadsheet with email reminders and an audit log. What could go wrong?


<aside markdown="1">
  If you enjoy my work, consider sponsoring me so I can keep on doing this full
  time: <https://github.com/sponsors/hugopeixoto>
</aside>
