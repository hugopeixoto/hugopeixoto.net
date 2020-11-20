---
kind: article
title: Brute forcing my own passphrase
created_at: 2020-11-20
excerpt: |
  Six months ago, I found an ssh key whose passphrase I couldn't remember. It's
  been bothering me ever since. Today I thought of a potential candidate and
  added some brute force to the mix.
---

<aside markdown="1">
  If you enjoy my work, consider sponsoring me so I can keep on doing this full
  time: <https://github.com/sponsors/hugopeixoto>
</aside>

Back in May, when I was [cleaning up the server that runs
`git.hugopeixoto.net`][fixing-hp-net], I found an ssh key whose passphrase I
couldn't remember. It's an old key that I created 10 years ago to use in my
employer's laptop. I don't work there anymore and I don't actively use this
key, so it's not like I lost access to anything. I have another user on this
server whose passphrase I remember. It still bothered me, though. When I first
found out about the missing passphrase, I made a list of potential passphrases
with variants for capitalization, punctuation and things like that, and tried
them all in a python script, but it got me nowhere.

From time to time, I remember a potential passphrase and try it. Today, I
remembered a new one to try, so I added it to the list. I was feeling kind of
lazy and didn't want to generate every possible combination of
punctuation/capitalization/etc, so I wrote an expansion function that works a
bit like bash's `{a,b}` syntax. The full script looks like this:

~~~~python
def expand(x):
    state = 0
    parts = [[""]]

    for f in x:
        if f == '{' and state == 0:
            state = 1
            parts.append([""])
        elif f == '}' and state == 1:
            state = 0
            parts[-1] = parts[-1][0].split(",")
            parts.append([""])
        else:
            parts[-1][0] += f

    def rec(parts, current, results):
        if parts:
            for part in parts[0]:
                rec(parts[1:], current + part, results)
        else:
            results.append(current)

    results = []
    rec(parts, "", results)

    return results

def expandall(*strings):
    ret = []
    for x in strings:
        ret += expand(x)

    return ret

# I used to have a manually generated list here
passphrases = expandall(
  "{f,F}irst template",
  "s{e,E}cond template",
)

print(len(passphrases))
for passphrase in passphrases:
  if subprocess.run([
    "ssh-keygen", "-yf", "/path/to/privatekey", "-P", passphrase
  ]).returncode == 0:
    print(passphrase)
    break
~~~~

There's probably a `flatmap` or a nested comprehension list I could use in
`expandall`, but I just wanted this to work and I'm not super familiar with
python. Using variable names like `f` and `x` is a good indication that I was
in "just write some code" mode. I don't even know why I fall back to python for
these kinds of scripts, instead of going with ruby. Maybe it's because when I'm
writing ruby I automatically go into "let's write this in a single chain of
method calls" mode?

Anyway, if you feed `expand` something like `"{w,W}hy{ ,}python{?,?!}"`, it
would generate a list of `2*2*2=8` strings:

- `why python?`
- `why python?!`
- `whypython?`
- `whypython?!`
- `Why python?`
- `Why python?!`
- `Whypython?`
- `Whypython?!`

Nothing fancy, but it saves me some work. Before testing the new passphrase
candidate, I changed the existing list to use the expand function, to reduce
the file size and try some new combinations. The list had ~100 manual
passphrase variations, stemming from ~10 templates. After converting them to
use `expand`, I ended up with ~1000 variations. These would take some time to
run, but why not? I launched the process and...

It found the answer after ~50 attempts!

It found the answer as it was iterating variations of the second passphrase
template, so I did know the passphrase... mostly. I tried connecting to the
server using that key, entered the passphrase, and it worked. It's kind of
stupid but I was super excited when the script found the answer, even if it's
useless. This problem lived in the back of my head for six months, and I was a
bit worried and frustrated by the fact that I had no idea what the passphrase
could be. I'm happy that I can take this out of my mind.


<aside markdown="1">
  If you enjoy my work, consider sponsoring me so I can keep on doing this full
  time: <https://github.com/sponsors/hugopeixoto>
</aside>

[fixing-hp-net]: https://hugopeixoto.net/articles/2020-05-03.html#what-else-is-missing
