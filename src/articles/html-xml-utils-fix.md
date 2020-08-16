---
kind: article
title: HTML-XML-utils bug fix
created_at: 2020-08-16
excerpt: |
  While working on <https://github.com/marado/RNID>, I hit a bug in `hxselect`,
  a C tool from [HTML-XML-utils](https://www.w3.org/Tools/HTML-XML-utils/). I
  found the bug, sent it upstream, and I'm now trying to get it packaged by
  Debian.
---
I've been working on <https://github.com/marado/RNID>, a project that monitors
failures to comply with the national open standards regulation. It is basically
a set of bash scripts that check if there has been any updates to the websites
found in breach.

One of the command line tools it uses is `hxselect`, coming from the
[HTML-XML-utils package](https://www.w3.org/Tools/HTML-XML-utils/). `hxselect`
prints html elements that match a CSS selector. Here's an example usage (`-s`
specifies the separators between matches):

~~~~
$ cat sample.html
<html>
  <body>
    <h1>Hello</h1>
    <p>Lorem ipsum</p>
    <ul>
      <li>first</li>
      <li>second</li>
    </ul>
    <p>Dolor sit amet</p>
  </body>
</html>
$ cat sample.html | hxselect 'body > p' -s '\n'
<p>Lorem ipsum</p>
<p>Dolor sit amet</p>
~~~~

One of the things that `marado/RNID` checks for is [WCAG 2.0
AA](https://www.w3.org/TR/WCAG20/) compliance. Instead of doing a full
accessibility check, the scripts use some proxy checks, like checking for image
tags without or with empty `alt` attributes.

Although `hxselect` is used throughout the project, the scripts are using `grep
"alt=''"` to check for empty `alt` attributes. I decided to try to use
`hxselect`, since we can filter elements by attribute values using CSS selectors:

~~~~
$ echo "<img alt=''>" | hxselect -s '\n' 'img[alt=""]'
Segmentation fault
~~~~

Since I had installed this via apt, I found the upstream via `apt show
html-xml-utils`, which pointed to <https://www.w3.org/Tools/HTML-XML-utils/>.
I downloaded the latest version to confirm that the bug hadn't been fixed.

There's no git repository, so I downloaded the latest version, extracted it,
and iniitialized a local git repository and commited everything, mostly so I
could track what my changes. I [pushed it to
github](https://github.com/hugopeixoto/html-xml-utils) just to have a backup.

Since I'm a [puts
debuggerer](https://tenderlovemaking.com/2016/02/05/i-am-a-puts-debuggerer.html),
I started sprinkling `printf` statements throughout the code, starting from
`main`. Eventually I found that it crashed in a `*s == *t && strcmp(s,t) == 0`.
This suggested that the attribute value in the query, while empty, was being
set to `NULL`.

I tracked this down to `parse_selector`. It only allocated the string when
visiting the first character in the value's string. The main change ended up
being small:

~~~~diff
diff --git a/selector.c b/selector.c
index 25a5f7c..a068527 100644
--- a/selector.c
+++ b/selector.c
@@ -314,12 +314,20 @@ EXPORT Selector parse_selector(const string selector, string *rest)
       else errexit("Expected string or name after \"=\" but found \"%c\"\n",*s);
       break;
     case DSTRING:                              /* Inside "..." */
-      if (*s == '"') {s++; state = AFTER_VALUE;}
+      if (*s == '"') {
+        s++;
+        if (!sel->attribs->value) sel->attribs->value = newstring("");
+        state = AFTER_VALUE;
+      }
       else if (*s == '\\') parse_escape(&s, &sel->attribs->value);
       else {strappc(&sel->attribs->value, *s); s++;}
       break;
     case SSTRING:                              /* Inside "..." */
-      if (*s == '\'') {s++; state = AFTER_VALUE;}
+      if (*s == '\'') {
+        s++;
+        if (!sel->attribs->value) sel->attribs->value = newstring("");
+        state = AFTER_VALUE;
+      }
       else if (*s == '\\') parse_escape(&s, &sel->attribs->value);
       else {strappc(&sel->attribs->value, *s); s++;}
       break;
~~~~

This initializes the string if it hadn't been initialized when the end quote
marker is detected. I added a unit test and struggled a bit with `autotools` to
see it working.

Once it was working, I had to figure out how to send it upstream. I checked
[the changelog](https://www.w3.org/Tools/HTML-XML-utils/ChangeLog), and got an
email address. I generated a patch via `git format-patch`:

~~~~
$ git format-patch HEAD~
0001-Fix-segfault-when-querying-for-empty-attributes.patch
~~~~

A few hours after I emailed the patch, the author released a new version (7.9).

The next step is to get it packaged for Debian. Going to
<https://tracker.debian.org/pkg/html-xml-utils> pointed me to a [Salsa
repository](https://salsa.debian.org/rnaundorf-guest/html-xml-utils). I made a
merge request that refreshes the upstream source code from 7.7 to 7.9:

<https://salsa.debian.org/rnaundorf-guest/html-xml-utils/-/merge_requests/2>

It's still pending review, and I'll need to work on a merge request to the
actual `debian` files. This is the first time I'm involved with the release of
a Debian package, so I'm not sure how long this process is going to take.
