---
kind: article
title: Advent of code 2019
created_at: 2020-01-04
excerpt: |
  [Advent of Code](https://adventofcode.com) is an anual programming contest
  made of 25 programming puzzles, unlocked from the 1st to the 25th of
  December. It started in 2015, and I try to participate each year.
---
[Advent of Code](https://adventofcode.com) is an anual programming contest made
of 25 programming puzzles, unlocked from the 1st to the 25th of December. It
started in 2015, and I try to participate each year.

## My history with this contest

When it first came out, [I was still into programming
contests](/articles/first-impressions-of-haskell.html), and I managed to finish
22 puzzles. I used C++, because that's my default language for these type of
challenges.

2017 and 2016 were not so great. I managed to solve roughly 10 problems each
year before getting distracted with something else. Mid 2016 I switched jobs
and started working mainly in ruby, so this was the language I used in these
two editions.

I didn't even participate in 2018.

This year, although I still mostly work with ruby (and that's definitely one of
my favorite languages), I decided to try something different. I started solving
these in [Rust](https://www.rust-lang.org/).

I managed to do the first two days on the day they were released, but then
didn't manage to have the time to pick it up again until the 8th. By the 21st,
I had finished day 13. This is where I would probably quit, based on the
previous year's pattern. Instead, I decided to push through, and by the 30th, I
had finished day 21. I managed to find some headspace to work on the following
problems, and by January 3rd I submitted the 25th problem. Success!

During the first years, I had other folks that would participate, so there was
an extra bit of motivation to get them done on the day, and we could celebrate
advancing together. I lost touch with some of them, and they probably stopped
participating as well.

Now that I managed to finish one edition, I'm kind of feeling the urge to go
and work on the previous editions. Or to participate in
[UVA](https://onlinejudge.org/). Or [Project Euler](https://projecteuler.net/).
My original goal in Project Euler was to raise my [ranking among Portugal
users](https://projecteuler.net/location=Portugal). Most top accounts haven't
submitted anything in a while, so maybe it's easy to get a top20 position.


## Takeaways from using rust in AoC 2019

The first problem was easy. Take in a bunch of numbers, multiply them by a
constant, and sum the results. Lucky me, because I had to get used to Rust.
Parsing the input files was the hardest part. I had to read a set of numbers,
one per line, from a file. In ruby, I would do something like:

~~~~ ruby
ARGF.readlines.map(&:to_i)
~~~~

In rust, I had to deal with some extra stuff:

~~~~ rust
use std::io::{self, BufRead};

fn main() {
    let modules = io::BufReader::new(io::stdin())
        .lines()
        .filter_map(Result::ok)
        .map(|line| line.parse::<i32>())
        .filter_map(Result::ok)
        .collect::<Vec<_>>();

    // ..
}
~~~~

As soon as I got the input in a vector, solving the actual problem was easy.
One cool thing is that unit tests go directly inside the file, and `cargo` has
the runner built in, so there was no extra setup:

~~~~ rust
fn fuel(mass: i32) -> i32 {
    (mass / 3 - 2).max(0)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
     fn test_fuel() -> Result<(), String> {
         assert_eq!(0, fuel(1));
         assert_eq!(2, fuel(12));
         assert_eq!(2, fuel(14));
         assert_eq!(654, fuel(1969));
         assert_eq!(33583, fuel(100756));

         Ok(())
     }
}

fn main() {
  // ...
}
~~~~

Running `cargo test`:

~~~~terminal?prompt=$,#&output=plaintext%3ftoken=Text&lang=plaintext%3ftoken=Generic.Strong
hugopeixoto@zephos$ cargo test
   Compiling adventofcode2019 v1.0.0 (challenges/adventofcode/2019)
    Finished test [unoptimized + debuginfo] target(s) in 0.39s
     Running target/debug/deps/day1-b04522aba678e51a

running 1 test
test tests::test_fuel ... ok

test result: ok. 1 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out
~~~~

One thing I noted was that I ended up having a single test per function, with
multiple test cases in it. I guess this is a consequence of the type of
problems I was solving and the fact that each puzzle was single file.

On the first few days I was actively avoiding calls to `unwrap()`, considering
them bad practice. After a while, I stopped pretending this was a critical
project and embraced the unwraps, effectively using them as asserts.

One of the puzzles was a maze, where the starting point was marked by a
character `A`. `fn starting_point(&self) -> (i32, i32)` function would call
`find(|p, c| c == 'A').unwrap()`. I could have made it return an `Option<(i32,
i32)>`, but in this context, that would just be noisy. Having it explode and
looking at the stacktrace was more helpful than writing code to propagate and
handle Nones.

Another issue I had was with passing strings around, specially during parsing.
This was a common pattern in my implementations:

~~~~ rust
fn parse(source: &String) -> Vec<(usize, usize)> {
    source
        .lines()
        .enumerate()
        .flat_map(|(y, r)| r.chars().enumerate().map(move |(x, c)| (x, y, c)))
        .filter(|&(_, _, c)| c == '#')
        .map(|(x, y, _)| (x, y))
        .collect::<Vec<_>>()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_parse() -> Result<(), String> {
        assert_eq!(
            parse(&".#..#\n.....\n#####\n....#\n...##".to_string()),
            vec![
                (1, 0), (4, 0),
                (0, 2), (1, 2), (2, 2), (3, 2), (4, 2),
                (4, 3),
                (3, 4), (4, 4),
            ],
        );

        Ok(())
    }
}

fn main() {
     let mut buffer = String::new();
     io::stdin().read_to_string(&mut buffer).unwrap();

     let asteroids = parse(&buffer);
}
~~~~

When writing the tests, I had to constantly use the `&"...".to_string()`
pattern. Maybe I should have used `parse(source: &str)` instead. I still
haven't grokked the differences, and how they convert from one to the other.

Similarly, I kept adding and removing `&`s whenever I did maps and filters on
iterators, and switching between `iter()` and `into_iter()`.

I used `collect::<Vec<_>>()` excessively to avoid dealing with passing
Iterators around. I spent some time refactoring some of the solutions, but they
still have a long way to go. I wanted to return iterators to avoid excessive
copying, but couldn't get the return types right.

There seems to be an [`impl Trait`
feature](https://doc.rust-lang.org/rust-by-example/trait/impl_trait.html) that
makes this possible. The `parse` function above would become:

~~~~ rust
fn parse<'a>(source: &'a String) -> impl Iterator<Item=(usize, usize)> + 'a {
    source
        .lines()
        .enumerate()
        .flat_map(|(y, r)| r.chars().enumerate().map(move |(x, c)| (x, y, c)))
        .filter(|&(_, _, c)| c == '#')
        .map(|(x, y, _)| (x, y))
        // note the lack of collect here
}

// this would also work:
// fn parse(source: &String) -> impl Iterator<Item=(usize, usize)> + '_ {
~~~~

I also had some hard times dealing with `flat_map`. Since it returns an `impl
Iterator` that might outlive the scope of the `flat_map` closure, I had some
issues with lifetimes. I ended up almost never using it. Note the `move` in the
example above, to deal with `y` being borrowed into the inner closure that
outlives the outer closure.

I missed some features that come with other programming language's standard library.
These were the extra crates I ended up importing:

- [regex](https://docs.rs/regex): regular expression engine
- [itertools](https://docs.rs/itertools): for `iproduct!`, available in ruby as
  [`Array#product`](https://ruby-doc.org/core-2.7.0/Array.html#method-i-product).
  I would probably not require this if I didn't derp as much as I did with
  `flat_map`.
- [gcd](https://docs.rs/gcd): available in ruby as
  [`Integer#gcd`](https://ruby-doc.org/core-2.7.0/Integer.html#method-i-gcd). I
  ended up writing a custom version, because I needed the extended algorithm
  instead of the basic one.
- [num-rational](https://docs.rs/num-rational): available in ruby as
  [`Rational`](https://ruby-doc.org/core-2.7.0/Rational.html). I needed this
  because `f32` are only partially comparable in Rust and I wanted to avoid
  dealing with `partial_cmp`, and with floating point imprecisions in general.

Additionally, I copied over an implementation of `next_permutation`, available
in C++ as
[`std::next_permutation`](https://en.cppreference.com/w/cpp/algorithm/next_permutation).


## Puzzles overview

The puzzles alternated between two categories. `intcode` related problems and
miscellaneous problems. `intcode` problems started by requiring the
implementation of a virtual machine that deals with `i64` and has a limited
number of instructions. The later `intcode` problems used provided `intcode`
programs as black boxes.

The miscellaneous problems required some knowledge of modular arithmetic
properties, graph algorithms (common ancestors, shortest paths), and one
problem, 16 part 2, that seemed related to
[FFT](https://en.wikipedia.org/wiki/Fast_Fourier_transform) but I could quite
figure out the relationship. I will probably review this one, as well as puzzle
22 (the modular arithmetic one).


## Conclusions

I'm super happy that I finished this, and that I got to do it in a new
language. I kind of miss playing around in C++, template shenanigans included,
and rust is kind of close to it.
