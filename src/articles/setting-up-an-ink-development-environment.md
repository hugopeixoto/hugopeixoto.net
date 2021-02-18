---
kind: journal
title: Setting up an ink! development environment
created_at: 2021-02-18
excerpt: |
  I'm working on bringing upgradeability to ink! smart contracts, so this post
  describes how I setup my ink! development environment.
---

<aside markdown="1">
  If you enjoy my work, consider sponsoring me so I can keep on doing this full
  time: <https://github.com/sponsors/hugopeixoto>
</aside>

I'm currently working on bringing upgradeability to [ink! smart
contracts][ink], as part of [this grant proposal][w3f-ogp]. This post will
contain the steps it took me to get things up and running.

The first thing I did was to stop using [asdf][asdf] for rust. I enjoy using it
for things like ruby and nodejs, but using it for rust nightly has not been
great. Every time I want to bump to a more recent nightly version I end up
having to reinstall all of my rust tools. [rustup][rustup] is the recommended
tool anyway, so I decided to give it a try. The rustup installation is kind
enough to provide me information on which paths and environment variables it
uses, so I was able to configure those before proceeding.

To setup an `ink!` environment, I followed almost to the letter the setup in
their [recommended tutorial][ink-workshop]. There is some nightly vs stable
confusion in the instructions. Since I don't have the stable toolchain installed,
my installation commands were as follows:

~~~~
# apt install clang libclang-dev libz-dev

$ rustup component add rust-src --toolchain nightly
$ rustup target add wasm32-unknown-unknown --toolchain nightly
$ cargo install canvas-node --git https://github.com/paritytech/canvas-node.git --tag v0.1.4 --force --locked
$ cargo install cargo-contract --vers 0.8.0 --force --locked
$ cargo contract new flipper
~~~~

Later they suggest running `cargo +nightly test`. Unsure why folks need to
specify `+nightly` here, when the other cargo commands didn't. I'm able to run
`cargo test` without any issues.

Running `cargo contract build` outputs a couple of files to `target`:

- `flipper.contract`
- `flipper.wasm`
- `metadata.json`

After running the local node with `canvas --dev --tmp`, I tried to access it
using <https://paritytech.github.io/canvas-ui>. It connects to a test node /
network by default, but changing it to `Local Node` worked fine and I was able
to deploy and call functions on my contract.

Deploying a contract is a two step operation:

1. Calling `put_code` with the wasm blob
2. Calling `contract.instantiate` with the code address

This was easier than I expected, although the `cargo install` steps took
forever.

Just like in ethereum, the way that calling contract functions works is by
sending a transaction with the deployed contract address and a payload. The
wasm blob will pick the right codepath based on data. For example, when I
called the `flip` function on my contract, it sent the data `0xc096a5f3`.
Looking at the contract metadata (`metadata.json`), I can find that number
under the `spec.messages` key:

~~~jsonc
// cat target/metadata.json  | jq '.spec.messages[0]'
{
  "args": [],
  "docs": [
    " A message that can be called on instantiated contracts.",
  " This one flips the value of the stored `bool` from `true`",
  " to `false` and vice versa."
  ],
  "mutates": true,
  "name": [
    "flip"
  ],
  "payable": false,
  "returnType": null,
  "selector": "0xc096a5f3"
}
~~~

Using the `canvas-ui` thing, I can call methods either as RPC calls or as
transactions. The next step is to figure out how cross contract calls are made
and how storage is handled.


<aside markdown="1">
  If you enjoy my work, consider sponsoring me so I can keep on doing this full
  time: <https://github.com/sponsors/hugopeixoto>
</aside>

[asdf]: https://asdf-vm.com/
[ink]: https://paritytech.github.io/ink/
[w3f-ogp]: https://github.com/w3f/Open-Grants-Program/pull/238
[rustup]: https://rustup.rs/
[ink-workshop]: https://substrate.dev/substrate-contracts-workshop/
