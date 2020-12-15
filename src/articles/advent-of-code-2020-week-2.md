---
kind: article
title: Advent of code 2020, week 2
created_at: 2020-12-14
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

I'm publishing my solutions here, with a delay of a day or two:
<https://github.com/hugopeixoto/aoc2020>

Here are my personal stats so far:

~~~~
      -------Part 1--------   -------Part 2--------
Day       Time  Rank  Score       Time  Rank  Score
 14   00:10:17   343      0   00:33:07   779      0
 13   02:25:27  9424      0   03:26:30  4825      0
 12   01:26:32  7219      0   01:39:25  5711      0
 11   01:13:35  5964      0   01:20:22  4033      0
 10   00:52:14  9128      0   01:01:41  3367      0
  9   00:22:35  5624      0   00:34:57  4854      0
  8   00:49:35  8777      0   00:56:21  6027      0

  7   00:17:27   801      0   00:30:15  1022      0
  6   00:08:04  2745      0   00:13:41  2145      0
  5   00:23:43  4339      0   00:28:12  3544      0
  4   00:20:52  4184      0   00:56:14  3896      0
  3   00:56:04  8977      0   01:04:08  8165      0
  2   00:07:32  1519      0   00:10:52  1224      0
  1   01:10:16  6419      0   01:16:28  6046      0
~~~~

Day 9 and day 14 were the only ones where I was awake at release time, but I'm
still solving them same day, which was my main goal. This week had some harder
problems. Day 10 and 13 stumped some folks. Here's what I found interesting so
far each day:


## Day 8

I initially brute-forced part 2, but after submitting the solution I optimzed
it with a node marking depth first search. To make sure that it was indeed
faster, I started using `cargo bench` to compare the running time of my
solutions.

I tried using [`scan_fmt`](https://crates.io/crates/scan_fmt/) instead of
regular expressions when parsing the input file.


## Day 9

The first part was similar to the 2SUM problem but with a rolling window kind
of thing. I used `itertools::minmax` in the second part. It's a bit clunky,
though:

~~~~rust
if let MinMaxResult::MinMax(x, y) = numbers[lower..i].iter().minmax() {
  println!("{}", x + y);
  break;
}
~~~~


## Day 10

I solved part 2 using dynamic programming. At this point I started
preallocating vectors, and it would be nice to have something shorter than
this:

~~~rust
  let mut ways: Vec<u64> = Vec::new();
  ways.resize(numbers.len(), 0);
~~~

I could probably squeeze this to use constant memory with a small circular
buffer.


## Day 11

This is a variation of game of life. Initially I had a function that received a
board state and returned the new game state, but I changed it to something
similar to the double buffering technique so that memory isn't constantly being
allocated, using mutable references to mutable vectors and the
`destructuring_assignment` nightly feature:

~~~~rust
#![feature(destructuring_assignment)]

fn next(a: &Vec<bool>, b: &mut Vec<bool>, neighbors: &Vec<usize>, thresh: usize) -> bool;

fn main() {
  // ...
  let mut a = &mut compact_state.clone();
  let mut b = &mut compact_state.clone();

  while next(a, b, &neighbors, 5) {
    (a, b) = (b, a);
  }
}
~~~~


## Day 12

Just a bunch of `match` statements, nothing particularly interesting.

## Day 13

This one required some maths, so it took me about an hour to get the second
part solved. Nothing fancy on the rust side.


## Day 14

I brute forced part 2, and I have no idea if there's a smarter way. I learned a
bit about passing slices around:

~~~~rust
fn gen2(mask: &[char], addr: u64, x: u64, results: &mut Vec<u64>) {
  if mask.len() == 0 {
    results.push(addr);
  } else {
    match mask[0] {
      // ...
    }
  }
}

fn gen(mask: &Vec<char>, addr: u64) -> Vec<u64> {
    let mut r = vec![];
    gen2(&mask, addr, 0, &mut r);
    r
}
~~~~


## Benchmark results

I'm benchmarking the `main` functions directly, including the input file I/O,
using `cargo bench`. Here are the current results:

~~~~rust
test bench_day01 ... bench:      33,130 ns/iter (+/- 9,334)
test bench_day02 ... bench:     106,041 ns/iter (+/- 45,522)
test bench_day03 ... bench:      36,203 ns/iter (+/- 9,872)
test bench_day04 ... bench:   1,602,220 ns/iter (+/- 214,088)
test bench_day05 ... bench:     131,899 ns/iter (+/- 42,727)
test bench_day06 ... bench:     618,439 ns/iter (+/- 244,812)
test bench_day07 ... bench:   2,163,174 ns/iter (+/- 410,470)
test bench_day08 ... bench:     321,834 ns/iter (+/- 51,744)
test bench_day09 ... bench:     123,836 ns/iter (+/- 10,562)
test bench_day10 ... bench:       8,940 ns/iter (+/- 4,849)
test bench_day11 ... bench:   7,497,058 ns/iter (+/- 748,109)
test bench_day12 ... bench:      22,708 ns/iter (+/- 8,289)
test bench_day13 ... bench:       7,517 ns/iter (+/- 1,562)
test bench_day14 ... bench:   8,969,778 ns/iter (+/- 770,472)
~~~~

I was trying to squeeze them to fit under a millisecond each, but I'm having
trouble with some of them. Day 4 and day 7 use regular expressions, and while I
could remove them, the code complexity would sky rocket. Day 11 is the game of
life variant, and I don't see how I can improve it. I haven't spent much time
optimizing day 14, but it would probably require a non bruteforce approach.

I kind of went all-in on day 2, and parsed everything manually to avoid going
through each character in the input file more than once. I learned that I could
use a match statement like this:

~~~~rust
let state = 0;
for character in input.chars() {
  match (character, state) {
    ('\n', _) => { /* ... */ },
    ('0'..='9', 1) => { /* ... */ },
    ('0'..='9', _) => { /* ... */ },
  }
}
~~~~


## Bonus - Project euler

I got carried away and solved five more project euler problems: [121][p121],
[122][p122], [123][p123], [125][p125], and [126][p126]. I enjoyed solving 126
and 122. I got stuck on 127.


<aside markdown="1">
  If you enjoy my work, consider sponsoring me so I can keep on doing this full
  time: <https://github.com/sponsors/hugopeixoto>
</aside>

[p121]: https://projecteuler.net/problem=121
[p122]: https://projecteuler.net/problem=122
[p123]: https://projecteuler.net/problem=123
[p125]: https://projecteuler.net/problem=125
[p126]: https://projecteuler.net/problem=126
