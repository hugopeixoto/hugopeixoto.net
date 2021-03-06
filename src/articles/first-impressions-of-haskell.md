---
kind: article
title: First impressions of Haskell
created_at: 2015-05-10
excerpt: |
  A couple of weeks ago, HackerRank sponsored a functional programming contest.
  48 hours to solve seven problems in a functional language. This was the
  perfect opportunity to try out Haskell.
---

I usually enjoy trying out new languages, but it's not always easy to find an
excuse to do so. If I have the time, I usually do a [mergesort
example](https://github.com/hugopeixoto/mergesort). This forces me to go
through the setup phase (getting a compiler, creating a hello world) and try
some basic things like lists and recursion, but it's definitely not enough.

Fortunately, I'm a fan of programming competitions such as [Google Code
Jam](https://codingcompetitions.withgoogle.com/codejam), [Project
Euler](https://projecteuler.net), and recently
[HackerRank](https://hackerrank.com). A couple of weeks ago, HackerRank
sponsored a functional programming contest. 48 hours to solve seven problems in
a functional language. This was the perfect opportunity to try out Haskell.

Having previously played around a bit with it, I had expected to bump into some
problems.


## Dealing with I/O

There's the meme that as I/O is implemented using monads, it is pretty
complicated. Fortunately, these competition problems have very limited I/O.
Usually one just reads the problem parameters, and outputs the result. I did
not set out to fully understand
[monads](https://wiki.haskell.org/Monad_tutorials_timeline) during the contest,
but it still took me a while to manage reading lines of integers, apply some
function to them and print the results one in each line. This happened because
I wanted to write the code in a way such that each line would be read,
transformed and printed before the next line would be read (to avoid pulling
everything into memory). Something like:

~~~~
while line = getNextLine
  result = solve line
  print line
~~~~

Eventually some random stackoverflow answer explained that functions like
`getContents` are processed in a lazy way, which means that it will read bytes
as you require them. So something like the following would read, process and
write a line at a time:

~~~~haskell
solve x = show (length x)
main = do
  queries <- getContents
  putStr (unlines (map solve (lines queries)))
~~~~

Another issue with I/O that came up was debugging. During these contests, part
of the challenge is figuring out patterns for given inputs, so it usually helps
to print intermediate values along the way. It's impossible to place `putStr`
instructions throughout the code without changing everything, due to their
monadic nature.

Apparently, Haskell developers thought about this, and introduced the
`Debug.Trace.trace` function which is a workaround using unsafe I/O operations.
It is designed for debugging purposes only. So the previous example could be
modified as follows:

~~~~haskell
import Debug.Trace
solve x = trace x $ show (length x)
~~~~

This would print each line before printing the operation result, without the
need to sprinkle everything with `IO`.


## Memoization and random access

Programming contests usually require some form of [dynamic
programming](http://en.wikipedia.org/wiki/Dynamic_programming) approach. To put
it simply, this means to solve a problem of size N by combining the solutions
to the subproblems of size less than N. These subproblem solutions are usually
cached, to avoid redundant computation.

A typical problem is calculating the Nth term of the fibonacci sequence.
Without any kind of caching, the naive implementation would be exponential in
time, as many subproblems would be solved multiple times:

~~~~ haskell
fib 0 = 0
fib 1 = 1
fib n = fib (n - 1) + fib (n - 2)

-- this would expand as follows:
-- fib 4 = fib 3 + fib 2
--       = (fib 1 + fib 2) + fib 2
--       = (1 + fib 2) + fib 2
--       = (1 + (fib 0 + fib 1)) + fib 2
--       = (1 + (0 + fib 1)) + fib 2
--       = (1 + (0 + 1)) + fib 2
--       = (1 + (0 + 1)) + (fib 0 + fib 1)
--       = (1 + (0 + 1)) + (0 + fib 1)
--       = (1 + (0 + 1)) + (0 + 1)
--       = 3
~~~~

In C++, the dynamic programming approach could be implemented as follows:

~~~~ c++
const int MAX_N = 100;
int fib[MAX_N+1];

void prepare() {
  fib[0] = 0;
  fib[1] = 1;
  for (int i = 2; i <= MAX_N; i++) {
    fib[i] = fib[i-1] + fib[i-2];
  }
}

int main() {
  prepare();
  cout << fib[4] << endl;
}
~~~~


In Haskell, the usual precomputed approach goes something like:

~~~~ haskell
fib n = cached !! n
  where cached = 0 : 1 : zipWith (+) cached (tail cached)

main = do
  putStr $ show $ fib 4
~~~~

In this implementation, each fibonacci result is cached after being (itself or
a higher number) requested for the first time. There's just one small detail
that, performance wise, might make a difference. The C++ sample uses an array,
whose indexing operation runs in constant time, while the Haskell version uses
a list, increasing the indexing running time to linear.

It took me a while to solve the indexing problem, but I finally did it by
creating an array. This allows us to calculate the ith value by refering to
values which were previously calculated:

~~~~ haskell
import Data.Array

maxn = 100
fib n = cached ! n
  where cached = fromList
                   (0, maxn)
                   ([0, 1] ++
                    [cached!(i-2) + cached!(i-1) | i <- [2..maxn]])

main = do
  putStr $ show $ fib 4
~~~~

Using an array guarantees constant time indexing, just like the C++ version.
The potential drawbacks of this solution are that it is no longer lazy, and the
bounds must be specified.


## Immutability vs standard algorithms

Just like the previous example, most algorithms are implemented with mutability
in mind. Take for example a depth first search. It requires some way of
tracking which nodes are already visited, to avoid looping forever. Since nodes
are usually numbered from 1 to `N`, or 1 to `N-1`, we can implement it with a
boolean array which is updated every time the search visits a node:

~~~~ python
def dfs(g):
  visited = [False]*len(g)
  ordered = []

  def dfs_aux(v):
    if not visited[v]:
      visited[v] = True
      ordered.append(v)

      for w in g[v]:
        dfs_aux(w)

  for v in range(len(g)):
    dfs_aux(v)

  return ordered

graph = [[1, 2], [3], [0, 1], [], []]
print("\n".join(map(str, dfs(graph))))
~~~~

This implementation has a running time of `O(|V|+|E|)`, which is as good as it
gets. It depends on the mutation of two variables: `visited` and `ordered`.
To write this in Haskell we'd need to get rid of those two states.

Removing the mutation of `ordered` without compromising the time complexity is
simple. Removing the mutation of `visited`, however, is not trivial. If linear
time is not a requirement, a possible implementation would be to use a `Set`
instead of a mutable array (a little more verbose than needed for clarity):

~~~~ haskell
import Data.Array
import qualified Data.Set as Set

type Graph = Array Int [Int]
type VisitedSet = Set Int
type State = (VisitedSet, [Int])

dfs :: Graph -> [Int]
dfs g =
  let (_, result) = foldl
                      (dfs' g)
                      (Set.empty, [])
                      (indices g) in reverse result

  where
    dfs :: Graph -> State -> Int -> State
    dfs' g state@(visited, result) v
      | Set.member v visited = state
      | otherwise = foldl
                      (dfs' g)
                      (Set.insert v visited, v:result)
                      (g ! v)

graph = listArray (0, 4) [[1, 2], [3, 4], [0, 1], [], []]
main = do
  putStr $ unlines (map show (dfs graph))
~~~~

This would bring the complexity up to `O((|V| + |E|) log |V|)`, as each
iteration would require a search and insertion into the set. Note: In order to
make the `result` construction constant time, I had to prepend the nodes as
nodes where found. This caused the final list to be reversed, which is why
there is a `reverse` call right before returning the ordered nodes.

After some research, I found a paper titled _[Structuring Depth-First Search
Algorithms in
Haskell](http://www.researchgate.net/publication/2252048_Structuring_Depth-First_Search_Algorithms_in_Haskell)_.
It describes an approach to the DFS algorithm in linear time using the ST
monad. This monad allows us to emulate an imperative style of programming, in a
contained way (without leaking the state to the caller). Instead of
implementing their technique of generating infinite trees and pruning them with
the ST monad, I opted for rewriting the code above with the ST monad instead:

~~~~ haskell
import Data.Array
import Data.Foldable
import Data.Array.ST
import Control.Monad.ST

type Graph = Array Int [Int]
type VisitedSet s = STArray s Int Bool
type State s = (VisitedSet s, [Int])

dfs2 :: Graph -> [Int]
dfs2 g = runST $
  newArray (bounds g) False >>= \visited ->
    foldlM
      (dfs' g)
      (visited, [])
      (indices g) >>= \(_, result) ->
        return $ reverse result

  where
    dfs' :: Graph -> State s -> Int -> ST s (State s)
    dfs' g state@(visited, result) v =
      readArray visited v >>= \is_visited ->
          case is_visited of
            True  -> return state
            False -> (writeArray visited v True) >>
                       foldlM
                         (dfs' g)
                         (visited, v:result)
                         (g ! v)

graph = listArray (0, 4) [[1, 2], [3], [0, 1], [], []]
main = do
  putStr $ unlines (map show (dfs2 graph))
~~~~

Note: I avoided Haskell's `do` notation on purpose. I am still trying to grok
monads, and I feel that the raw syntax helps.

The resulting overall shape of the code is the same as the suboptimal one, but
its use of monads makes it non trivial for someone who has not played with them
for a while.

There are probably libraries that implement these algorithms in an efficient
way, but my goal (in the context of programming competitions) is usually to
learn how they work and how to implement them.


## Conclusion

Using Haskell in a programming competition was an interesting challenge.

It felt limiting not being able to implement the algorithms in the way that I
usually do. During the contest I was not able to figure out how to use the
monad techniques I presented above, so some of my solutions were sub optimal.
In the end it didn't make much difference, but it still felt uncomfortable.

On the other hand, it was great to try out something different and have to
figure out how to do things that I always took for granted. I really liked lazy
evaluation as well. First, once I got used to it, the I/O handling code became
way simpler. Second, I started using infinite lists to avoid having to think
about limits and edge cases.
