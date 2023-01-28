---
kind: article
title: Printer certificate shenanigans
created_at: 2023-01-29
excerpt: |
  After moving, my computer and printer stopped talking to each other.
  Obviously, I only noticed the issue when I was in a hurry to print something.
  Today I finally stopped to fix it.
---

<aside markdown="1">
  If you enjoy my work, consider sponsoring me so I can keep on doing this full
  time: <https://github.com/sponsors/hugopeixoto>
</aside>

After moving, my computer and printer stopped talking to each other. Obviously,
I only noticed the issue when I was in a hurry to print something. Today I
finally stopped to fix it.

CUPS would detect the printer, and I was able to queue the job, but as soon as
the job started processing, it would fail and the printer would enter a
"Paused" state.

I don't know much about printers or CUPS, so I looked for some log files in
`/var/log/`. There are two: `/var/log/cups/access_log` and
`/var/log/cups/error_log`.

I enabled debug logging with `cupsctl --debug-logging`, restarted cups, and
queued another print job. I'm not sure if this was necessary to debug this
particular issue, but it wouldn't hurt.

The error log contained the following snippet (with some identifiers hidden
just in case):

~~~~
D [28/Jan/2023:19:49:18 +0000] [Notifier] state=3
D [28/Jan/2023:19:49:18 +0000] [Notifier] JobProgress
D [28/Jan/2023:19:49:18 +0000] [Notifier] state=3
D [28/Jan/2023:19:49:18 +0000] [Notifier] state=3
D [28/Jan/2023:19:49:18 +0000] [Notifier] state=3
D [28/Jan/2023:19:49:18 +0000] [Notifier] PrinterStateChanged
D [28/Jan/2023:19:49:19 +0000] [Job 32] update_reasons(attr=0(), s=\"-cups-certificate-error\")
D [28/Jan/2023:19:49:19 +0000] [Job 32] Connection is encrypted.
I [28/Jan/2023:19:49:19 +0000] Expiring subscriptions...
D [28/Jan/2023:19:49:19 +0000] [Job 32] Credentials are invalid (New credentials are older than stored credentials.)
D [28/Jan/2023:19:49:19 +0000] [Job 32] Printer credentials: HPFFFFFF-2 (issued by HP) / Sat, 28 Sep 2032 03:45:61 GMT / RSA-SHA256 / AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
D [28/Jan/2023:19:49:19 +0000] [Job 32] Stored credentials: HPFFFFFF (issued by HP) / Tue, 07 Jun 2037 10:24:56 GMT / RSA-SHA256 / BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
D [28/Jan/2023:19:49:19 +0000] [Job 32] update_reasons(attr=0(), s=\"-cups-pki-invalid,cups-pki-changed,cups-pki-expired,cups-pki-unknown\")
D [28/Jan/2023:19:49:19 +0000] [Job 32] update_reasons(attr=0(), s=\"+cups-pki-invalid\")
D [28/Jan/2023:19:49:19 +0000] [Job 32] STATE: +cups-pki-invalid
D [28/Jan/2023:19:49:19 +0000] cupsdMarkDirty(P----)
D [28/Jan/2023:19:49:19 +0000] cupsdSetBusyState: newbusy="Printing jobs and dirty files", busy="Printing jobs and dirty files"
D [28/Jan/2023:19:49:19 +0000] cupsdMarkDirty(---J-)
D [28/Jan/2023:19:49:19 +0000] cupsdSetBusyState: newbusy="Printing jobs and dirty files", busy="Printing jobs and dirty files"
D [28/Jan/2023:19:49:19 +0000] cupsdMarkDirty(----S)
D [28/Jan/2023:19:49:19 +0000] cupsdSetBusyState: newbusy="Printing jobs and dirty files", busy="Printing jobs and dirty files"
D [28/Jan/2023:19:49:19 +0000] [Notifier] state=3
D [28/Jan/2023:19:49:19 +0000] [Notifier] PrinterStateChanged
D [28/Jan/2023:19:49:19 +0000] [Notifier] state=3
D [28/Jan/2023:19:49:19 +0000] [Job 32] The IPP Backend exited with the status 4
D [28/Jan/2023:19:49:19 +0000] [Client 8] HTTP_STATE_WAITING Closing for error 32 (Broken pipe)
~~~~

It seems that the printer, when connecting to the new network, started
announcing its name with a `-2` suffix. My desktop had a cached certificate
with the old name (without the suffix), so the connection failed.

To solve the problem all I had to do was remove the now stale certificate:

~~~~bash
$ rm /etc/cups/ssl/HPEEEEEEFFFFFF.local.crt
~~~~

Immediately requesting another print job worked, no need to restart cups.

Comparing both the old and the new cached certificate, I confirmed that the
Subject had a different CN in both: no suffix on the old one, `-2` suffix on
the new one. Not sure why the printer decided to change names, but it probably
had something to do with having to configure a new wifi network.

<aside markdown="1">
  If you enjoy my work, consider sponsoring me so I can keep on doing this full
  time: <https://github.com/sponsors/hugopeixoto>
</aside>
