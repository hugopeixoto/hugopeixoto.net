---
kind: article
title: Recompiling firefox to change some keyboard shortcuts
created_at: 2020-07-14
---

I'm trying to migrate from [Chromium](https://www.chromium.org/) to
[Firefox](https://mozilla.org/firefox/new).

One of the things that caught me by surprise is that the keyboard shortcuts to
select the n-th tab are different. In chromium, they're `Ctrl+1` through
`Ctrl+9`, while in firefox they're `Alt+1` through `Alt+9`. These shortcuts
conflict with the ones I'm using in [sway](https://swaywm.org/), where they're
used to navigate between workspaces.

This is not fixable via a setting change, so I decided to build a custom
version of firefox. Since I'm using debian, this should be straightforward:

~~~~
$ sudo apt build-dep firefox    # install build dependencies
$ apt source firefox            # download source package
$ cd firefox-78.0.2/
$ make-necessary-changes-to-files
$ dpkg-source --commit          # create a patch file and changes version
$ dpkg-buildpackage -us -uc     # build the deb files
~~~~

I was having some trouble finding what changes to make, though, and firefox's
codebase is not exactly small. [tokei](https://github.com/XAMPPRocky/tokei)
reports ~200k files and ~27M lines of code. `ack`ing didn't help much, so I
cloned the source repository to see if I could find something through the
commit messages. Firefox uses mercurial, but there's an official git mirror:

<https://developer.mozilla.org/en-US/docs/Mozilla/Git>

> The current official git mirror of the Firefox code base (also known as
> "gecko" or "mozilla-central") can be found at
> <https://github.com/mozilla/gecko-dev>.

After some tries, I found this:

~~~~
$ git log --grep "Ctrl+9"
commit 032ccdebf21b0e8493a28c4bee3ed759f87c5a40
Author: steffen.wilberg%web.de <steffen.wilberg%web.de>
Date:   Wed Jun 7 21:40:07 2006 +0000

    Bug 340553: Document that Ctrl+9 focuses last tab. p=zeniko@gmail.com, r=me

commit ce743abf4705fdbbf7695be3b929506f5563d183
Author: gavin%gavinsharp.com <gavin%gavinsharp.com>
Date:   Tue Jun 6 16:28:09 2006 +0000

    Bug 338348: Make Ctrl+9 select the last tab instead of the ninth tab, patch
    by Simon Bünzli <zeniko@gmail.com>, r=mconnor
~~~~

The second commit was a good starting point. The code had changed a lot since
that commit in 2006, but I was able to track it down by looking to the files
history with a combination of `git log -p <filename>` and `git show <commit-sha>`.
I ended up doing the following change:

~~~~diff
--- firefox-78.0.2.orig/browser/base/content/browser-sets.inc
+++ firefox-78.0.2/browser/base/content/browser-sets.inc
@@ -315,11 +315,7 @@
     <key id="key_undoCloseTab" command="History:UndoCloseTab" data-l10n-id="tab-new-shortcut" modifiers="accel,shift"/>
     <key id="key_undoCloseWindow" command="History:UndoCloseWindow" data-l10n-id="window-new-shortcut" modifiers="accel,shift"/>

-#ifdef XP_GNOME
-#define NUM_SELECT_TAB_MODIFIER alt
-#else
 #define NUM_SELECT_TAB_MODIFIER accel
-#endif

 #expand    <key id="key_selectTab1" oncommand="gBrowser.selectTabAtIndex(0, event);" key="1" modifiers="__NUM_SELECT_TAB_MODIFIER__"/>
 #expand    <key id="key_selectTab2" oncommand="gBrowser.selectTabAtIndex(1, event);" key="2" modifiers="__NUM_SELECT_TAB_MODIFIER__"/>
~~~~

By removing the `ifdef`, it now always uses `accel`. It took roughly one hour
to compile and it generated a bunch of deb files:

~~~~
$ ls -1 *.deb
firefox-dbgsym_78.0.2-1.1_amd64.deb
firefox-l10n-ach_78.0.2-1.1_all.deb
firefox-l10n-af_78.0.2-1.1_all.deb
[...]
firefox-l10n-zh-cn_78.0.2-1.1_all.deb
firefox-l10n-zh-tw_78.0.2-1.1_all.deb
firefox_78.0.2-1.1_amd64.deb
~~~~

I installed the last one via `dpkg -i firefox_78.0.2-1.1_amd64.deb`, restarted
firefox, and it works!

Not sure how I'll keep recompiling firefox every time there's a new firefox
version. This doesn't seem like something that would be accepted upstream. I
didn't see any keyboard shortcuts on that file whose modifiers depend on a
configuration setting.

It would probably have been easier to install [an extension for
this](https://addons.mozilla.org/en-US/firefox/addon/ctrl-number-to-switch-tabs/).

Here are some firefox bug reports and commits related to this keyboard shortcut
that I found along the way:

- (2002) [Adding support for ALT+n to select the nth tab.](https://github.com/mozilla/gecko-dev/commit/470789b11c912c021a9813c5f298e7129eac0f45)
- (2002) [make ctrl+num switch to tabs instead of alt+num](https://github.com/mozilla/gecko-dev/commit/e770181c662ca0f9c0fec7820ac160938c4eb8a7)
- (2004) [[Linux] N-th tab shortcuts should use Alt-1 to Alt-9 rather than Ctrl-1 to Ctrl-9](https://bugzilla.mozilla.org/show_bug.cgi?id=256635)
- (2006) [Ctrl+9 to select last tab instead of ninth tab, ala IE 7](https://bugzilla.mozilla.org/show_bug.cgi?id=338348)
- (2007) [Numeric accesskeys still conflicting with tab switching](https://bugzilla.mozilla.org/show_bug.cgi?id=366084)
