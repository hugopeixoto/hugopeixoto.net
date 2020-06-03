---
kind: article
title: Backing up my gmail account with rust
created_at: 2020-06-03
---

I have been using a gmail account as my primary email address since 2004. I
don't usually delete things, so I have thousands of emails in there. Depending
on google to maintain this for me, without any backups, is kind of scary, but I
have been putting off backing these up for a while now.

I'm aware that there's a data export functionality. You should probably use
that. A few years ago, that didn't work that great. It failed creating full
exports, and I had to resort to filter them by year to be able to successfully
export them and download them. I hope this is fixed by now.

In 2014, I tried using [offlineimap](http://www.offlineimap.org/). I don't
remember what went wrong there, but I do remember that it took forever and
failed a lot. It seems that it is being replaced with
[imapfw](http://imapfw.offlineimap.org/), but it isn't ready yet.

This week I was cleaning up my inbox, and noticed that I get a lot of emails
per day. I wanted to get an idea of what kind of emails I get, do some basic
analysis.

Since I have found myself with a lot of free time lately, I decided to create a
rust tool to back up the emails via IMAP. This would provide me with a local
backup and allow me to have a local copy I can easily analyze.

## Getting my feet wet

There's an [imap crate](https://crates.io/crates/imap). I'll be using that. To
connect to your gmail account, you need to enable IMAP access in your settings.
I also needed to create an "App password (by going to
<https://myaccount.google.com/apppasswords>). Not sure if this is the safest
thing to do.

Using the example in the imap crate readme, I was able to view the first
message I have in my account.

Before starting to implement the backup process, I decided to get an overview
of what I was getting into. I wanted to check how many emails I would have to
backup, and, while I'm at it, how are they spread across the years.

This is what I ended up with:

~~~~ rust
extern crate imap;
extern crate native_tls;
extern crate chrono;

type ImapSession = imap::Session<native_tls::TlsStream<std::net::TcpStream>>;
type DateTime = chrono::DateTime<chrono::offset::FixedOffset>;

fn message_date(n: u64, imap_session: &mut ImapSession) -> Option<DateTime> {
    if let Ok(messages) = imap_session.fetch(n.to_string(), "INTERNALDATE") {
        if let Some(message) = messages.first() {
            return message.internal_date();
        }
    }

    None
}

fn main() {
    let tls = native_tls::TlsConnector::builder().build().unwrap();

    let client = imap::connect(
        ("imap.gmail.com", 993),
        "imap.gmail.com",
        &tls,
    ).unwrap();

    let username = std::env::var("USERNAME").unwrap();
    let password = std::env::var("PASSWORD").unwrap();

    let mut imap_session = client.login(username, password).unwrap();

    imap_session.select("[Gmail]/All Mail").unwrap();

    for idx in 0.. {
       let msg = if idx == 0 { 1 } else { idx * 1000 };

       if let Some(date) = message_date(msg, &mut imap_session) {
           println!("{} {}", msg, date.to_rfc3339());
       } else {
           break;
       }
    }
}
~~~~

This grabs each thousandth message and prints the message date. Running it as:

~~~~
hugopeixoto@laptop:mail-tools export USERNAME=email
hugopeixoto@laptop:mail-tools export PASSWORD=password
hugopeixoto@laptop:mail-tools cargo run | tee stats.txt
1 2004-09-03T21:53:26+00:00
1000 2007-09-18T14:08:24+00:00
2000 2007-12-20T17:48:38+00:00
3000 2008-02-27T01:40:51+00:00
4000 2008-04-07T22:45:39+00:00
[...]
144000 2019-11-25T22:05:33+00:00
145000 2020-01-20T20:00:24+00:00
146000 2020-03-09T12:39:42+00:00
147000 2020-04-21T17:31:33+00:00
148000 2020-05-21T11:10:44+00:00
~~~~

I would usually plot these with gnuplot, but decided to try
[R](https://www.r-project.org/) instead:

~~~~ R
library(ggplot2)
data = read.table(
  "stats.txt",
  col.names=c("count", "date"),
  colClasses = c("numeric", "POSIXct")
)
ggplot(data, aes(x = date, y = count)) + geom_line()
~~~~

![Email count growing with time](/articles/time-to-email-count.png)

I have roughly 150000 emails in need of backup, and it seems that the new
emails rate is decreasing.

To calculate the exact number of messages, I wrote an [exponential
search](https://en.wikipedia.org/wiki/Exponential_search) function:

~~~~ rust
fn highest_message_number(imap_session: &mut ImapSession) -> u64 {
    let mut lower = 0;
    let mut upper = 0;
    for e in 0.. {
        let idx = 2u64.pow(e);

        if let Some(_date) = message_date(idx, imap_session) {
            lower = idx;
        } else {
            upper = idx;
            break
        }
    }

    while lower + 1 != upper {
        let middle = (lower + upper) / 2;

        if let Some(_date) = message_date(middle, imap_session) {
            lower = middle;
        } else {
            upper = middle;
        }
    }

    lower
}
~~~~

This starts by exponentially increasing the message index to determine a lower
and upper bound. `lower` will always refer to an existing message index, while
`upper` will always point to a non existing message index. The second step is
to run a binary search.

Now that I have the exact number of messages that need to be backed up, I
should store them.


## Fetching message contents via IMAP

Ideally, what would end up being backed up is what you see when, in gmail, you
"Show original message". Every header and body part. You can specify which
fields are fetched in the second argument of `fetch`. Using `RFC822` fetches
the entire message, including headers.

You can also fetch more than one message per `fetch` by specifying a range in
the first argument. I wrapped this in a `messages` function:

~~~~ rust
extern crate imap;
extern crate native_tls;
extern crate chrono;

type ImapSession = imap::Session<native_tls::TlsStream<std::net::TcpStream>>;

#[derive(Debug)]
struct Message {
    uid: imap::types::Uid,
    body: Vec<u8>,
}

fn messages(from: u64, to: u64, imap_session: &mut ImapSession) -> Vec<Message> {
  let result = imap_session.fetch(format!("{}:{}", from, to), "(UID RFC822)")

    if let Ok(messages) = result {
        return messages.iter().map(|message|
            Message {
                uid: message.uid.unwrap(),
                body: message
                  .body()
                  .map(|x| x.into_iter().map(|&x| x).collect())
                  .unwrap(),
            }
        ).collect::<Vec<_>>();
    }

    vec![]
}
~~~~

This is significantly faster than fetching messages one by one. Comparing the
batched versus the one by one method:

~~~~ rust
fn main() {
    // ...

    {
        let now = Instant::now();
        println!("one by one");

        for i in 1..101 {
            println!("{:?}", messages(i, i, &mut imap_session).first().unwrap().uid);
        }

        println!("{}", now.elapsed().as_secs());
    }

    {
        let now = Instant::now();
        println!("batched");

        for message in messages(1, 101, &mut imap_session).into_iter() {
            println!("{:?}", message.uid);
        }

        println!("{}", now.elapsed().as_secs());
    }
}
~~~~

~~~~
hugopeixoto@laptop:~/w/p/mail-tools cargo build --release
hugopeixoto@laptop:~/w/p/mail-tools ./target/release/mail-tools
batched
[...]
11
one by one
[...]
37
~~~~

In this scenario, batching was 3 times faster. These results are not super
precise, the time to fetch a single message varies a lot, but I don't see why
batching would be worse.


## Storing RFC822 messages

With the body and message unique identifier loaded, the next step is to store
it in the file system:

~~~~ rust
pub fn message_store(message: &Message) -> Result<(), Box<dyn std::error::Error>> {
    let mut file = std::fs::File::create(format!("messages/{:07}.txt", message.uid))?;

    file.write_all(&message.body)?;

    Ok(())
}

pub fn messages_store_from(base: u64, imap_session: &mut ImapSession) {
    let max = highest_message_number(imap_session);
    println!("Going up to {}", max);

    let step = 500;

    for i in 0.. {
        let lower = base + i * step;
        let upper = base + (i + 1) * step;

        if lower > max {
            break;
        }

        println!("batching {}:{}", lower, upper);
        for message in messages(lower, upper, imap_session).into_iter() {
            message_store(&message).unwrap();
        }
    }
}
~~~~

This stores one email per file, in the `messages/` directory, in the format
specified by [RFC5322](https://tools.ietf.org/html/rfc5322) (which supersedes
[RFC2822](https://tools.ietf.org/html/rfc2822) and
[RFC822](https://tools.ietf.org/html/rfc822)).

The `base` parameter will allow me to resume downloading if anything fails, or
to fetch new emails incrementally. I increased the batch size from 100 to 500.

This is good enough for a first prototype. If I wanted to turn this into a
library, I would create a message iterator with built in batching.

This took ~35 minutes to download 100k messages, and ~60 minutes to download
everything. I ended up with `9.6G` of messages.

I could try to paralelize these requests with multiple IMAP sessions. Using 10
workers could improve the running time to 5 minutes, assuming there are no
server side bottleneck. According to [GMail's support
page](https://support.google.com/mail/answer/7126229), "You can only use 15
IMAP connections per account". They don't mention any other limits.

## Email analysis

Reading 9.6G spread across 150k files in a single run is not going to be fast.
I used [`mailparse`](https://crates.io/crates/mailparse), and it takes ~70
seconds to read every file and pass them through the `parse_mail` function.

During parsing, I found two malformed emails coming from Yahoo, when they were
handling the Delicious data migration. There was no empty line between the
headers and the body.

I tried fetching the date of each email, using `mailparse::dateparse`, but I
hit some malformed headers as well. Here are the malformed ones I found:

- `Date: Sat, 19 Feb 2005 05:59:26 Pacific Standard Time`: uses named timezone instead of offset
- `Date: Fri 06-Nov-2009 07:47 +0100`: uses dashes as separators
- `Date: Fri, 18 Dec 2009 13:15:52 --0800`: double minus sign
- `Date: Dom, 1 Dez 2013 13:36:43 -000`: portuguese weekdays and months

I solved these with a bunch of string `replace` function calls. Using
[`itertools`](https://crates.io/crates/itertools) and
[`chrono`](https://crates.io/crates/chrono), I calculated the maximum number of
emails per day:

~~~~ rust
extern crate chrono;

use itertools::Itertools;

use std::fs;
use std::io;

use chrono::{DateTime, NaiveDateTime, Utc};
use std::io::prelude::*;
use mailparse::*;

fn main() {
    let mut entries = fs::read_dir("messages")
        .unwrap()
        .map(|res| res.map(|e| e.path()))
        .collect::<Result<Vec<_>, io::Error>>()
        .unwrap();

    entries.sort();

    let dates = entries
        .iter()
        .map(|path| {
            let mut file = fs::File::open(path).unwrap();
            let mut contents = Vec::<u8>::new();
            file.read_to_end(&mut contents).unwrap();

            contents
        })
        .map(|contents| {
            parse_headers(&contents)
                .unwrap()
                .0
                .get_first_value("Date")
                .unwrap()
                .replace("Pacific Standard Time", "PST")
                .replace(" --", " -")
                .replace("-Nov-", " Nov ")
                .replace("Dom", "Sun").replace("Dez", "Dec")
        })
        .map(|date| dateparse(&date).unwrap())
        .map(|ts| NaiveDateTime::from_timestamp(ts, 0))
        .map(|datetime| DateTime::<Utc>::from_utc(datetime, Utc).date())
        .group_by(|&date| date)
        .into_iter()
        .map(|(_date, v)| v.count())
        .max();

    println!("{}", entries.len());
    println!("{:?}", dates);
}
~~~~

This takes too long to process, so I may decide I want to store both the
original message and a pre-processed index somewhere. I could create a `mbox`
file per year, for example, or store them in a sqlite database.

## Conclusions

Thanks to the `imap` crate, I was able to quickly download every email from my
gmail account. With `mailparse`, I can run some analytics on my emails. I also
have the ability to add some automation, like turning newsletters to RSS feeds,
or register invoices in [ledger](https://plaintextaccounting.org/).

I've published these tools under an MIT license. You can check it out at:

<https://github.com/hugopeixoto/mail-tools>
