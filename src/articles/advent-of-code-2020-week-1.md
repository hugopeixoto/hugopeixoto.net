---
kind: article
title: Advent of code 2020, week 1
created_at: 2020-12-07
excerpt: |
  I've been solving the advent of code problems. Here's what's up so far.
---

<aside markdown="1">
  If you enjoy my work, consider sponsoring me so I can keep on doing this full
  time: <https://github.com/sponsors/hugopeixoto>
</aside>

[Advent of code 2020](https://adventofcode.com) is ongoing. I've been solving
the problems daily using rust. So far so good. I have a private leaderboard
with a few folks, anyone is free to join, here's the code: `9779-59e7cb46`.

My schedule has been kind of compatible with the time of release, so I've been
able to start working on them almost immediately. So far I haven't got any
points (rank <= 100), though. Here are my personal stats so far:

~~~~
      -------Part 1--------   -------Part 2--------
Day       Time  Rank  Score       Time  Rank  Score
  7   00:17:27   801      0   00:30:15  1022      0
  6   00:08:04  2745      0   00:13:41  2145      0
  5   00:23:43  4339      0   00:28:12  3544      0
  4   00:20:52  4184      0   00:56:14  3896      0
  3   00:56:04  8977      0   01:04:08  8165      0
  2   00:07:32  1519      0   00:10:52  1224      0
  1   01:10:16  6419      0   01:16:28  6046      0
~~~~

Days 1-6 were straightforward, while day 7 was a bit more involved. Last year I
wrote some tests. This year, I'm trying to get the solutions out of the door as
fast as I can, so there's none of that. I'm mostly using `println!`s.

Here's what I found interesting so far each day:


## Day 1

I learned about using [break with labels](https://doc.rust-lang.org/stable/std/keyword.break.html):

~~~~rust
'part1: for a in lines.iter() {
  for b in lines.iter() {
    if a + b == 2020 {
      println!("{}", a * b);
      break 'part1;
    }
  }
}
~~~~


## Day 2

I tried to speedrun this one to see if I could get some leaderboard points, so
I did this in ruby instead, but it still took me 7 minutes to get the initial
solution. I rewrote it in rust afterwards. It was a good problem to exercise
using regular expressions.


## Day 3

I read the whole input into a string and worked with it without any conversion.
So far I've been using a buffered reader to read lines.

~~~~rust
use std::fs::read_to_string;

pub fn main() {
  let area = read_to_string("inputs/day3.in").unwrap();
}
~~~~


## Day 4

I used a bunch of regular expressions, even for numeric range checking. Things
like this:

~~~~rust
let hgt = Regex::new(r"^hgt:(1([5-8]\d|9[0-3])cm|(59|6\d|7[0-6])in)$").unwrap();
~~~~

It took me a while to get some of these right. Maybe I should have gone with
something simpler.


## Day 5

This problem was basically implementing parsing numbers in base 2:

~~~~rust
i32::from_str_radix(
  &x
    .replace("F", "0")
    .replace("B", "1")
    .replace("R", "1")
    .replace("L", "0"),
  2,
)
~~~~

For part two, I kind of missed ruby's `Enumerable#each_cons`. Thankfully, the
[`itertools`](https://docs.rs/itertools/0.9.0/itertools/index.html) crate has
`tuple_windows`:

~~~~rust
let missing = lines
  .iter()
  .tuple_windows()
  .filter(|&(prev, current)| current - prev > 1)
  .map(|(_, current)| current - 1)
  .next()
  .unwrap();
~~~~


## Day 6

This day I learned that `trim` doesn't return a copy of the string, but
something that references it. That means I can't do something like this:

~~~~rust
# this doesn't work
let text = read_to_string("inputs/day6.in").unwrap().trim();
~~~~

I would need to either call `to_string()` on it, to make a copy, or to keep the
full text around:

~~~~rust
# either copy it
let text = read_to_string("inputs/day6.in").unwrap().trim().to_string();
# or keep it around
let text = read_to_string("inputs/day6.in").unwrap();
let trimmed = text.trim();
~~~~

## Day 7

This was the first problem this year that looked like a graph problem. I wrote
a couple of DFS-like functions. I expected to have some more trouble with
ownership of the arguments, but it was kind of easy. I used a bunch of
`std::collections::HashMap`s.


<aside markdown="1">
  If you enjoy my work, consider sponsoring me so I can keep on doing this full
  time: <https://github.com/sponsors/hugopeixoto>
</aside>
