---
kind: article
title: Advent of code 2020, week 3 and 4
created_at: 2020-12-27
excerpt: |
  I've been solving the advent of code problems. Here's what's up so far.
---

<aside markdown="1">
  If you enjoy my work, consider sponsoring me so I can keep on doing this full
  time: <https://github.com/sponsors/hugopeixoto>
</aside>

[Advent of code 2020](https://adventofcode.com) is over. I solved every problem
using rust. I've published my solutions with benchmarks:
<https://github.com/hugopeixoto/aoc2020>

Here are my personal stats:

~~~~
      -------Part 1--------   -------Part 2--------
Day       Time   Rank  Score       Time   Rank  Score
 25   16:07:07  10724      0   16:08:35   8001      0
 24   05:43:08   7036      0   06:06:22   5933      0
 23   10:55:04   9956      0   19:54:39   9020      0
 22   01:35:57   4756      0   02:13:51   3366      0

 21   06:38:31   6795      0   06:42:32   6487      0
 20   07:25:40   6174      0   08:45:53   2504      0
 19   00:31:32    641      0   01:22:30   1083      0
 18   00:53:33   2883      0   01:27:32   2880      0
 17   00:39:43   1662      0   00:47:24   1572      0
 16   00:11:37    597      0   00:57:35   1711      0
 15   05:00:28  13550      0   05:01:55  11579      0

 14   00:10:17    343      0   00:33:07    779      0
 13   02:25:27   9424      0   03:26:30   4825      0
 12   01:26:32   7219      0   01:39:25   5711      0
 11   01:13:35   5964      0   01:20:22   4033      0
 10   00:52:14   9128      0   01:01:41   3367      0
  9   00:22:35   5624      0   00:34:57   4854      0
  8   00:49:35   8777      0   00:56:21   6027      0

  7   00:17:27    801      0   00:30:15   1022      0
  6   00:08:04   2745      0   00:13:41   2145      0
  5   00:23:43   4339      0   00:28:12   3544      0
  4   00:20:52   4184      0   00:56:14   3896      0
  3   00:56:04   8977      0   01:04:08   8165      0
  2   00:07:32   1519      0   00:10:52   1224      0
  1   01:10:16   6419      0   01:16:28   6046      0
~~~~

Here's some remarks on days 15-25:


## Day 15

This one is a variant of the [Van Eck's sequence](https://oeis.org/A181391). I
don't think that we can do this sublinearly. I got this down to a memory read
and a memory write per iteration.


## Day 16

I started by using a `Vec<HashSet<RuleId>>` to keep track of which rules were
compatible with each ticket position. I switched to a `Vec<usize>`, using the
`usize`s as bitmasks to make things faster.


## Day 17

Another game of life, but in 3 and 4 dimensions. Just like in day 11, I
allocated two boards and flipped between them instead of allocating a new one
per iteration:

~~~~rust
#![feature(destructuring_assignment)]

fn next4(a: &mut Vec<bool>, b: &mut Vec<bool>, /* ... */) {
  // ...
}

fn main() {
  // ...
  let mut a = &mut state.clone();
  let mut b = &mut state.clone();

  for t in 0..turns {
    next4(a, b, width, height, depth, wefth, turns - t);
    (a, b) = (b, a);
  }
}
~~~~


## Day 18

For the initial rust implementation, I used the [Shunting-yard
algorithm][shunting-yard] to transform the expressions from infix to postfix
notation. Fortunately I ran into this algorithm a couple of months ago when
experimenting with <https://github.com/hugopeixoto/pokequiz>, so I knew what to
use.

As an alternative implementation, I took advantage of ruby's monkey patching
and eval mechanisms:

~~~~ruby
x = "(#{File.read("inputs/day18.in").strip.gsub("\n", ")+(")})"

class Integer
  def -(other)
    self * other
  end
end

puts eval(x.gsub("*", "-"))

class Integer
  def -(other)
    self * other
  end

  def /(other)
    self + other
  end
end

puts eval(x.gsub("*", "-").gsub("+", "/"))
~~~~


## Day 19

My implementation for this one is terrible and I want to figure out a better
way to do this. Instead of implementing a grammar matching algorithm, I used
string substitutions to turn the input into a regular expression, and then used
the regular expression to check if the messages were valid.

For part 2, since the only two substitutions were `8: 42 | 42 8`, which means
`42+`, and `11: 42 31 | 42 11 31`, which means `42{k}31{k}`, and the root rule
is `0: 8 11`, I compiled a few regexps and brute forced the length of the 8th
rule expansion and the value of `k`:

~~~~rust
    let maxk = messagesstr.lines().map(|x| x.len()).max().unwrap() / 2;
    let re8 = Regex::new(&format!("^{}+$", &cache[&8])).unwrap();
    let regexps = (0..=maxk).map(|k| {
        Regex::new(
            &format!("^({}){{{}}}({}){{{}}}$", &cache[&42], k, &cache[&31], k),
        ).unwrap()
    }).collect::<Vec<_>>();

    let mut p2 = 0;
    for message in messagesstr.lines() {
        'x: for i in 1..message.len() {
            let p8 = &message[0..i];
            if re8.is_match(p8) {
                let p11 = &message[i..];
                for k in 1..=p11.len()/2 {
                    let re11 = &regexps[k];
                    if re11.is_match(p11) {
                        p2 += 1;
                        break 'x;
                    }
                }
            }
        }
    }
~~~~

This ends up compiling ~50 regular expressions, which takes some time (it takes
~500ms for the whole thing to run). Initially I was compiling the regular
expressions inside the loop, which takes even longer (around ~30 secs).


## Day 20

The first part of this day is an edge matching puzzle, and it reminded me of
the [Eternity II puzzle](https://en.wikipedia.org/wiki/Eternity_II_puzzle).

For the second part, tile are `8x8`, so they fit in a `u64`. I used a bunch of
bit operations to deal with the rotations / flips:

~~~~rust
fn transpose8(mut a: u64) -> u64 {
  let mut t;

  t = (a ^ (a >> 7)) & 0x00AA00AA00AA00AA;
  a = a ^ t ^ (t << 7);

  t = (a ^ (a >> 14)) & 0x0000CCCC0000CCCC;
  a = a ^ t ^ (t << 14);

  return (a & 0xF0F0F0F00F0F0F0F) |
    ((a >> 28) & 0xF0F0F0F0F0F0F0F0) |
    ((a << 28) & 0x0F0F0F0F0F0F0F0F);
}

fn rotate(tile: u64, rotation: usize) -> u64 {
  match rotation {
    0 => tile,
      1 => transpose8(tile).reverse_bits().swap_bytes(),
      2 => tile.reverse_bits(),
      3 => rotate(tile, 1).reverse_bits(),
      4 => tile.reverse_bits().swap_bytes(),
      5 => rotate(rotate(tile, 4), 1),
      6 => rotate(rotate(tile, 4), 2),
      7 => rotate(rotate(tile, 4), 3),
      _ => { panic!(); },
  }
}
~~~~

Initially I was doing the 90° rotation (`rotation == 1`) naively with maps and
folds, but I found [this implementation from Hacker's
Delight](https://stackoverflow.com/a/6932331). I adapted it to use `u64`
instead of two `u32` and ported it to rust and the total running time went down
~10µs.

This was a nice exercise to learn about bit operations on numeric types in rust.

## Day 21

I practically solved part 2 while solving part 1. In the initial
implementation, I was using `HashSet`s and `HashMap`s of `String`s, so there
were a lot of `to_string()` calls to deal with ownership issues. The optimized
solution used `&str` instead. Every string slice was referencing the initial
`input: String` parameter, so there were no string copies.


## Day 22

I didn't do anything special to optimize this, and it shows. The running time
is close to one second. I'm using VecDeques and pushing/popping elements, and
cloning them whenever I need to run a subgame.

I spent some time thinking about how to optimize the state representation: it
could be stored as the permutation number plus two lengths, bringing it to
approximately `log2(factorial(50) * 50 * 50) ~= 226` bits. It would be great if
I could do every operation directly on this representation, but I haven't
managed to do that yet. I don't think that rust has native 256 integers, so
I'll have to deal with two 128 bit unsigned integers.


## Day 23

I used a linked list backed by a single vector `ns: Vec<usize>`, where `ns[i]`
points to the element following `i`. I think it's impossible to solve
this without doing 10M iterations.


## Day 24

Yet another game of life, but this time based on a hexagonal grid. I used
[axial
coordinates](https://www.redblobgames.com/grids/hexagons/#coordinates-axial) to
map it into a 2D space, and used the following neighbors:

~~~~rust
const DELTAS: [(i32, i32); 6] = [
      (-1, -1), (0, -1),
    (-1,  0),     (1,  0),
       (0,  1), (1,  1),
];
~~~~


## Day 25

This is a diffie hellman key exchange, with small key sizes. To get this under
a millisecond, I used the [Baby-step
giant-step](https://en.wikipedia.org/wiki/Baby-step_giant-step) algorithm to
crack the private key and an iterative [exponention by
squaring](https://en.wikipedia.org/wiki/Exponentiation_by_squaring) algorithm
to compute the encryption key.


## Benchmark results

I'm benchmarking the `main` functions directly, including the input file I/O,
using `cargo bench`. Previously, I was benchmarking these in my laptop, but I
started running this on my desktop, since it's usually idle and the CPU is a
bit better (`i5-6200U @ 2.30GHz` vs `i7-5820K CPU @ 3.30GHz`). Here are the
current results:

~~~~rust
test bench_day01 ... bench:        15,994 ns/iter (+/- 246)
test bench_day02 ... bench:        82,259 ns/iter (+/- 515)
test bench_day03 ... bench:        21,439 ns/iter (+/- 411)
test bench_day04 ... bench:       221,002 ns/iter (+/- 3,184)
test bench_day05 ... bench:        82,721 ns/iter (+/- 2,241)
test bench_day06 ... bench:        96,749 ns/iter (+/- 1,036)
test bench_day07 ... bench:       552,138 ns/iter (+/- 44,540)
test bench_day08 ... bench:       266,660 ns/iter (+/- 8,425)
test bench_day09 ... bench:        98,035 ns/iter (+/- 1,408)
test bench_day10 ... bench:         3,393 ns/iter (+/- 18)
test bench_day11 ... bench:     6,354,845 ns/iter (+/- 47,374)
test bench_day12 ... bench:        16,390 ns/iter (+/- 180)
test bench_day13 ... bench:         2,821 ns/iter (+/- 21)
test bench_day14 ... bench:       392,718 ns/iter (+/- 83,019)
test bench_day15 ... bench:   414,424,116 ns/iter (+/- 3,444,111)
test bench_day16 ... bench:       498,829 ns/iter (+/- 4,667)
test bench_day17 ... bench:    13,511,301 ns/iter (+/- 118,371)
test bench_day18 ... bench:       378,241 ns/iter (+/- 3,810)
test bench_day19 ... bench:   441,570,670 ns/iter (+/- 5,892,836)
test bench_day20 ... bench:       330,477 ns/iter (+/- 8,771)
test bench_day21 ... bench:       319,326 ns/iter (+/- 2,778)
test bench_day22 ... bench:   991,391,287 ns/iter (+/- 4,371,697)
test bench_day23 ... bench:   324,300,525 ns/iter (+/- 2,250,144)
test bench_day24 ... bench:    23,309,053 ns/iter (+/- 220,611)
test bench_day25 ... bench:       316,581 ns/iter (+/- 4,405)

test bench_all   ... bench: 2,214,272,195 ns/iter (+/- 27,137,664)
~~~~

I ended up rewriting day 4 and day 7, removing the regular expressions and
using a manual parser instead. I also implemented a non-bruteforce approach for
day 14.

Day 15 and 23 are probably impossible to get under a millisecond. They both
require tens of millions of iterations and at least one memory read and write
per iteration.

Day 19 and 22 are the ones that I haven't spent much time optimizing yet.

There are three game of life implementations: day 11, day 17 and day 24.
They're pretty close to be sub-millisecond, but I don't know how to squeeze any
more performance out of them. I'll probably need to find a way to parallelize
them, either by using bitsets or SIMD.

My initial goal was to get every day below 1 millisecond, but since it's
probably impossible, I'll try to get `bench_all` below 1 second. This should be
doable by optimizing days 19 and 22.


## Conclusions

Around day 3 or 4, using rust started feeling natural. It was interesting to
see the differences in performance between using `regexp`, `scan_fmt`,
string splits, and hand-rolled parsers.

Algorithm-wise, days 10 and 13 were probably the hardest ones. Day 20 was the
one that required more twiddling.


<aside markdown="1">
  If you enjoy my work, consider sponsoring me so I can keep on doing this full
  time: <https://github.com/sponsors/hugopeixoto>
</aside>


[shunting-yard]: https://en.wikipedia.org/wiki/Shunting-yard_algorithm
