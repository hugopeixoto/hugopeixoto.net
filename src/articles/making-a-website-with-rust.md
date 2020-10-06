---
kind: journal
title: Making a website with Rust
created_at: 2020-10-05
---

<aside markdown="1">
  If you enjoy my work, consider sponsoring me so I can keep on doing this full
  time: <https://github.com/sponsors/hugopeixoto>
</aside>


## Introduction

A couple of days ago, in a random chat, someone mentioned setting up a image
host on their servers. This led me to search for self hosted FOSS alternatives
to services like imgur. I found a few:

- [linx-server](https://github.com/andreimarcu/linx-server)
- [pictshare](https://github.com/HaschekSolutions/pictshare)

They both look to have more than enough features. This should have been the end
of the story, but, well.

I figured this would be a good example to try to build in Rust. I never built
anything web related in Rust, and this webapp would only have two pages: one
for uploading files and one for displaying an uploaded file.

I started by going to [Are we web yet](https://www.arewewebyet.org/). I think
that this website doesn't get many updates, but it's a good starting point.

They present us with a list of web frameworks. I've heard of `actix-web`,
`rocket`, `gotham`, and `warp`. I decided to with `warp`, with no real
reasoning behind it except the examples in their readme. Most of the news I've
been seeing regarding rust webdev are related to async I/O, which are probably
great news, but for me right now the performance doesn't matter as much as the
ease of use.

My goal was to build something with the following endpoints:

- `GET /`: returns an HTML page with a form with a file field
- `POST /file`: receives an image, stores it, and redirects to the display page
- `GET /image/<id>`: returns an HTML page displaying the uploaded image
- `GET /image/raw/<id>`: returns the raw contents

Since this is a simple app, I decided to go minimal, to minimize the framework
requirements. No database, files would be stored directly on disk. No html
templates, strings would be hardcoded. No asset management. No authentication,
no CORS.

## First iteration

It took me a couple of hours to get it running. This is what my first iteration
looked like:

~~~~rust
use futures::stream::TryStreamExt;
use http::Uri;
use std::fs::File;
use std::io::prelude::*;
use warp::Buf;
use warp::Filter;

fn index() -> impl warp::Reply {
  warp::reply::html("<html>form goes here </html>")
}

async fn upload(form: warp::multipart::FormData) -> Result<impl warp::Reply, warp::Rejection> {
  let mut parts: Vec<warp::multipart::Part> = form
    .try_collect()
    .await
    .map_err(|_e| warp::reject::reject())?;

  let id: u128 = rand::random();
  let mut file = File::create(format!("public/{}", id)).unwrap();

  file.write_all(parts[0].data().await.unwrap().unwrap().bytes())
    .unwrap();

  Ok(warp::redirect::redirect(
    format!("/image/{}", id).parse::<Uri>().unwrap(),
  ))
}

fn show_html(id: String) -> impl warp::Reply {
  warp::reply::html(format!("<html><img src='{}'/></html>", id))
}

#[tokio::main]
async fn main() {
  let index = warp::path::end().and(warp::get()).map(index);
  let upload = warp::path("upload")
    .and(warp::multipart::form().max_length(100_000_000))
    .and_then(upload);
  let show_html = warp::path!("image" / String)
    .and(warp::get())
    .map(show_html);
  let show_raw = warp::path!("image" / "raw" / ..)
    .and(warp::fs::dir("public"));

  let router = index.or(upload).or(show_html).or(show_raw);

  warp::serve(router).run(([127, 0, 0, 1], 3030)).await;
}
~~~~

This is very janky and full of `unwrap`s, but I wanted to get something working
first. I got rid of most of them in the following iterations.


## Multipart handling

The main thing that tripped me was handling multiparts. `warp` has [some
functionality to match multipart
requests](https://docs.rs/warp/0.2.5/warp/filters/multipart/index.html), but
working with multipart content is not that easy. In this first attempt I'm not
even making sure that I'm looking at the right part.

There's a [`multipart`](https://crates.io/crates/multipart) crate that creates
an abstraction layer for that, but it's only for sync APIs. The async
([`multipart-async`](https://github.com/abonander/multipart-async)) version
hasn't seen any releases yet.

After a while I added support for `alt` text for the images, which required
having another parameter in the POST payload. This required me to start
handling multipart forms properly. I created some methods to help with
extracting information from the `FormData` object:

~~~~rust
async fn readall(
    stream: impl futures::Stream<Item = Result<impl Buf, warp::Error>>,
) -> Result<Vec<u8>, warp::Error> {
  stream
    .try_fold(vec![], |mut result, buf| {
      result.append(&mut buf.bytes().into());
      async move { Ok(result) }
    })
    .await
}

async fn parse_upload_multipart(
    form: warp::multipart::FormData,
) -> Result<UploadForm, Box<dyn std::error::Error>> {
  let mut parts = form.try_collect::<Vec<_>>().await?;

  let mut get_part = |name: &str| {
    parts
      .iter()
      .position(|part| part.name() == name)
      .map(|p| parts.swap_remove(p))
      .ok_or(format!("{} part not found", name))
  };

  let alt = get_part("alt")?;
  let file = get_part("file")?;

  let file_content_type = file.content_type().map(|ct| ct.to_string());
  let file_contents = readall(file.stream()).await?;
  let alt_text = readall(alt.stream()).await?;

  Ok(UploadForm {
    alt: String::from_utf8(alt_text)?,
    file: file_contents,
    content_type: file_content_type,
  })
}
~~~~

I had to [fight the borrow
checker](https://doc.rust-lang.org/1.8.0/book/references-and-borrowing.html) a
bit to get `get_part` working. Initially I was trying to use `find()` instead
of `position()`, but I wouldn't be able to call it twice; I need to move the
element out of the vector, and that would mean that `parts` would be moved
during the first call, which would make the second call uncompilable. Using
`position` and `swap_remove` lets me move the element out of the vector.

`readall` was weird to figure out. I was following [LogRocket's blog post on
file uploading](https://blog.logrocket.com/file-upload-and-download-in-rust/).
I tried to simplify it but I don't understand the `futures::Stream` interface
that well, so I ended up leaving it as is.

I thought about trying to avoid loading the whole `file_contents` array onto
memory and rely on piping it directly to disk, but I will eventually need to
access the bytes to do mime type detection (maybe using
[`mime_sniffer`](https://github.com/flier/rust-mime-sniffer)?). Also, since I'm
collecting the parts to be able to index them by name, the full payload must be
already read from the socket and in memory.


## Serde

To store the `alt` text I decided to use a JSON file per file. I knew that
serializing things was done with [`serde`](https://serde.rs/), so I gave it a
try. Storing basic types was straightforward:

~~~~rust
#[derive(Serialize, Deserialize)]
struct Upload {
  alt: String,
  content_type: Option<String>,
}

fn store_metadata(id: u128) {
  let metadata = Upload {
    alt: "Dancing Ferris".to_string(),
    content_type: Some("image/png".to_string()),
  };
  let metadata_file = File::create(format!("public/{}.json", id)).unwrap();
  serde_json::to_writer_pretty(metadata_file, &metadata).unwrap();
}
~~~~

I wanted to use `mime::Mime` instead of a `String` for the content type,
though. Since that type does not implement Serialize nor Deserialize, making it
work was a bit painful. I can't implement a trait for a type when both of them
come from external crates. This is called the [orphan
rule](https://doc.rust-lang.org/book/ch10-02-traits.html#implementing-a-trait-on-a-type).
Serde is aware of this limitation, and they have a [page in their documentation
addressing this issue and how to work around it
](https://serde.rs/remote-derive.html). Unfortunately, since in this case the
type is wrapped in an `Option`, none of their solutions applies.

At first, I ignored this problem and used `Option<String>`, but this feels like
one of those things that I will need to fully understand if I want to use rust
for webdev effectively, since there's always a lot of serialization and
deserialization going on.

After some experimentation, I was able to come up with two solutions. The first
one involves creating a proxy object, `UploadSerializable`, that uses
`Option<String>`:

~~~~rust
#[derive(Clone, Serialize, Deserialize)]
#[serde(try_from = "UploadSerializable")]
#[serde(into = "UploadSerializable")]
struct Upload {
  alt: String,
  content_type: Option<mime::Mime>,
}

#[derive(Serialize, Deserialize)]
struct UploadSerializable {
  alt: String,
  content_type: Option<String>,
}

impl std::convert::TryFrom<UploadSerializable> for Upload {
  type Error = mime::FromStrError;

  fn try_from(value: UploadSerializable) -> Result<Upload, Self::Error> {
    Ok(Upload {
      alt: value.alt,
      content_type: value.content_type
                         .map(|ct| ct.parse::<mime::Mime>())
                         .transpose()?,
    })
  }
}

impl std::convert::From<Upload> for UploadSerializable {
  fn from(value: Upload) -> UploadSerializable {
    UploadSerializable {
      alt: value.alt,
      content_type: value.content_type.map(|ct| ct.to_string()),
    }
  }
}
~~~~

This is not ideal, because every time I change `Upload` I need to adapt
`UploadSerializable` and both trait implementations. I searched [serde's
attribute list](https://serde.rs/attributes.html) to see if I could use
something else, and found `serialize_with` and `deserialize_with`. This led me
to the second solution:

~~~~rust
use core::fmt;

#[derive(Clone, Serialize, Deserialize)]
struct Upload {
  alt: String,
  #[serde(serialize_with = "optional_mime_serializer")]
  #[serde(deserialize_with = "optional_mime_deserializer")]
  content_type: Option<mime::Mime>,
}

fn optional_mime_serializer<S>(
  t: &Option<mime::Mime>,
  serializer: S,
) -> Result<S::Ok, S::Error>
  where S: serde::Serializer
{
  t.clone().map(|v| v.to_string()).serialize(serializer)
}

fn optional_mime_deserializer<'de, D>(
  deserializer: D,
) -> Result<Option<mime::Mime>, D::Error>
  where D: serde::Deserializer<'de>
{
  struct OptionalMimeVisitor;
  impl<'de> serde::de::Visitor<'de> for OptionalMimeVisitor {
    type Value = Option<mime::Mime>;

    fn expecting(&self, formatter: &mut fmt::Formatter) -> fmt::Result {
      formatter.write_str("an optional mime type")
    }

    fn visit_some<D>(self, deserializer: D) -> Result<Self::Value, D::Error>
      where D: serde::Deserializer<'de>
    {
      deserializer.deserialize_string(OptionalMimeVisitor)
    }

    fn visit_str<E>(self, v: &str) -> Result<Self::Value, E>
      where E: serde::de::Error
    {
      Some(v.parse::<mime::Mime>())
        .transpose()
        .map_err(serde::de::Error::custom)
    }

    fn visit_none<E>(self) -> Result<Self::Value, E>
        where E: serde::de::Error
    {
      Ok(None)
    }
  }

  deserializer.deserialize_option(OptionalMimeVisitor)
}
~~~~

The serializer looks ok, but the deserializer is kind of terrible. The only
lines that really matter are `v.parse::<mime::Mime>().transpose()`. I wish I
didn't have to write the rest of the boilerplate. Maybe there's an easier way
to do this, somehow tell serde that whenever it sees a `mime::Mime` in the
object tree it should use a given proxy object, but I didn't find it.


Now that I had mime types stored on disk, I could use them to render the HTML
according to the type of file we're serving. With serde, reading the JSON file
was easy:

~~~~rust
fn show_html(id: String) -> impl warp::Reply {
  let upload: Result<Upload, _> =
    serde_json::from_reader(File::open(format!("public/{}.json", id)).unwrap());

  match upload {
    Ok(u) => {
      let ct = u.content_type.unwrap_or("image/png".to_string());
      // render things based on ct
    },
    Err(_) => { /* ... */ },
  }
}
~~~~

I had some duplication here, since some of the document markup is the same
independently of the content type, but it was good enough, considering I didn't
want to deal with templates.


## Serving files from disk with custom headers

I also wanted to change `show_raw` to send the stored Content-Type, instead of
it trying to infer from the filename extnsion (the default behaviour of
`warp::fs::dir`). This is what I ended up with:

~~~~rust
fn to_rejection<E>(_e: E) -> warp::Rejection {
    warp::reject::reject()
}

async fn show_raw(id: String) -> Result<impl warp::Reply, warp::Rejection> {
  let upload: Upload = File::open(format!("public/{}.json", id))
    .map_err(to_rejection)
    .and_then(|file| serde_json::from_reader(file).map_err(to_rejection))?;

  let ct = upload.content_type.unwrap_or("image/png".to_string());

  tokio::fs::File::open(format!("public/{}", id))
    .await
    .map(|file| {
      tokio_util::codec::FramedRead::new(
        file,
        tokio_util::codec::BytesCodec::new(),
      )
    })
    .map(hyper::Body::wrap_stream)
    .map(|body| {
      warp::http::Response::builder()
        .header("Content-Type", ct)
        .body(body)
    })
    .map_err(to_rejection)
}
~~~~

I'm being a bit lazy and returning a `warp::Rejection` on every failure
scenario, which isn't super correct. Rejections should be used to signal that
the route does not match the request. A JSON parse error should display an
error page, not move to the next route.

Returning the body was a bit more complex that I would have liked. I had to
grab tools from `tokio::fs`, `tokio_util::codec`, `hyper`, and `warp::http`
(which is an alias to the `http` crate). Ideally I would just have written:

~~~~rust
warp::reply::file(format!("public/{}", id))
  .with_header("Content-Type", ct)
~~~~

There's already a bunch of code in `warp::filters::fs::file` to deal with
serving file contents, so maybe this is something that could be extracted.


## Conclusions

I want to try another framework (probably `actix-web`) to see if the experience
is any different, or if the changes are mostly cosmetic. The `actix-web`
repository contains a [file upload
example](https://github.com/actix/examples/blob/master/multipart/src/main.rs),
so maybe I'll give it a try.

This experience is very different from using something like [Ruby on
Rails](https://rubyonrails.org/). It feels closer to using something like
[express](https://expressjs.com/). I'm feeling tempted to try to build
something that's closer to rails, with batteries included. Having a project
blueprint that pulls in certain libraries by default and sets conventions on
where files should be located and having a [generator
cli](https://guides.rubyonrails.org/command_line.html#rails-generate) are
things that help you getting started.

This also led me to the [AreWeWebYet
repository](https://github.com/rust-lang/arewewebyet). I noticed that there are
a lot of outdated and duplicate issues, so I tried to help by reviewing some of
them.

The git repository for the image host project is available on my github
account:

<https://github.com/hugopeixoto/imghost>

I documented the features that I want to build next directly in the README. I
should probably create issues instead. It's far from being "production ready",
but it was a good starting point to get me into rust webdev.
