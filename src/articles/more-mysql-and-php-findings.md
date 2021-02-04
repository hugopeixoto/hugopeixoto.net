---
kind: article
title: More PHP and MySQL findings
created_at: 2021-01-14
excerpt: |
  As I continue to work on [Cyberscore](https://cyberscore.me.uk), I keep finding
  new quirks / features in PHP and MySQL.
---

<aside markdown="1">
  If you enjoy my work, consider sponsoring me so I can keep on doing this full
  time: <https://github.com/sponsors/hugopeixoto>
</aside>

As I continue to work on [Cyberscore](https://cyberscore.me.uk), I keep finding
new quirks / features in PHP and MySQL. All of the tests below are being run on
mysql 5.7, unless otherwise noted. This is the version that's currently being
used by Cyberscore. Maybe one day I'll be able to migrate this to a recent
MariaDB version.

## Alternative INSERT syntax

Apparently, [mysql supports an alternative insert syntax][insert-set] that uses
an assignment list instead of value tuples:

~~~sql
-- standard syntax
INSERT INTO tablename (col1, col2) VALUES (val1, val2);

-- alternative mysql syntax, not standard
INSERT INTO tablename SET col1 = val1, col2 = val2;
~~~


## Character set handling

I was having some trouble running cyberscore locally: a form with Japanese text
was being stored in the database as a bunch of question marks. The codebase
sets everything to UTF-8 by having the following in a startup file:

~~~php
mb_http_input('UTF-8');
mb_http_output('UTF-8');
mb_internal_encoding('UTF-8');
mb_regex_encoding('UTF-8');
mb_language('uni');
ob_start('mb_output_handler');

db_query("SET NAMES utf8");
db_query("SET CHARACTER SET utf8");

define("CHARSET", "UTF-8");
~~~

There are a some interesting things here. First, we're executing both `SET
NAMES` and `SET CHARACTER SET`, which is redundant. Here's what those two
statements do:

~~~sql
SET NAMES X;
-- is equivalent to:
character_set_client = X;
character_set_connection = X;
character_set_results = X;

SET CHARSET X;
-- results in:
character_set_client = X;
character_set_connection = character_set_database;
character_set_results = X;
~~~

Both statements set the same variables, so they override each other. We should
only be using one of those two statements. In production,
`character_set_database` is set to `utf8`, so there's no difference between
them. On my development environment, even though the tables and columns are all
set to `utf8`, the database itself is set to `latin1`.

This difference explains why I was getting encoding errors locally, but to
understand what's going on here, we need to understand what each of those
settings does.

The first one, `character_set_client`, lets the server know what is the
character set of the strings being sent through the socket (after any TLS
processing is done). For example, if a client sends the query `select
'pokémon'` in UTF-8, what's actually being sent down the pipe are the following
bytes:

~~~
12 00 00 00  03 73 65 6C   .....sel
65 63 74 20  39 70 6F 6B   ect 'pok
C3 A9 6D 6F  6E 39         ..mon'
~~~

The first three bytes are the length of the payload (little endian) and the
fourth byte is the sequence number. The payload begins with a packet identifier
(0x03, in this case), and the query body follows. There's no indication of
character set, and no null termination. The client lets the server know what
character set it is using during the [initial connection
handshake][handshake-response], but it can be changed mid-connection by setting
`character_set_client`.

`character_set_connection` is the character set of the representation by the
server of the statements sent from the client. For example, if the client sends
the query `SELECT HEX('pokémon')` via a UTF-8 connection, it may be useful to
have the server interpret that string as being in another character set. Here's
an example illustrating the difference:

~~~sql
SET @@character_set_connection = 'utf8';
SELECT HEX('pokémon');                         -- => 706F6BC3A96D6F6E
SELECT HEX(CONVERT('pokémon' USING 'latin1')); -- => 706F6BE96D6F6E

SET @@character_set_connection = 'latin1';
SELECT HEX('pokémon');                         -- => 706F6BE96D6F6E
~~~

The last command being executed, in my case, was `SET CHARACTER SET utf8`. With
`character_set_database` set to `latin1`, all string literals were being
converted from `utf8` to `latin1`. Since japanese characters are not
representable in `latin1`, they were converted to question marks:

~~~sql
SET @@character_set_connection = 'utf8';
SELECT 'ポケットモンスター';  -- => ポケットモンスター

SET @@character_set_connection = 'latin1';
SELECT 'ポケットモンスター';  -- => ?????????
~~~

Note that `INSERT` statements convert any strings from their character set to
the character set of the column they're being inserted into, so you don't need
to worry with conversions:

~~~sql
CREATE TABLE encoding_tests(
  name TEXT CHARSET utf8 COLLATE utf8_unicode_ci
) CHARSET=utf8 COLLATE=utf8_unicode_ci;

INSERT INTO encoding_tests(name)
  VALUES(CONVERT('pokémon' USING 'latin1'));

SELECT HEX(name) from encoding_tests; -- => 706F6BC3A96D6F6E
~~~

You can also tell mysql to interpret a sequence of bytes with a given charset
by using [character set introducers][charset-introducers]. I'm not sure what
you'd use this for, but I guess it could be used to transmit UTF-8 data over an
ASCII connection, even if you could use CONVERT and UNHEX to achieve the same effect:

~~~sql
-- connection using --default-character-set=ascii
INSERT INTO encoding_tests(name) VALUES(_utf8 X'706F6BC3A96D6F6E');

SELECT HEX(name) from encoding_tests;     -- => 706F6BC3A96D6F6E
SELECT name from encoding_tests;          -- => pok?mon
SELECT CHARSET(name) from encoding_tests; -- => utf8

-- same as:
INSERT INTO encoding_tests(name) VALUES(CONVERT(UNHEX('706F6BC3A96D6F6E') USING utf8));
~~~

Maybe it is useful when you need to send queries with mixed encodings. This
sounds like it could go wrong in many ways, though.

`character_set_database` is the character set used for the storage of new
tables unless it's being explicitly set:

~~~sql
SELECT @@character_set_database;       -- => latin1

CREATE TABLE encoding_tests(name text);
SELECT table_collation
  FROM information_schema.tables
  WHERE table_name = 'encoding_tests'; -- => latin1_swedish_ci

DROP TABLE encoding_tests;
CREATE TABLE encoding_tests(name text)
  CHARACTER SET utf8;

SELECT table_collation
  FROM information_schema.tables
  WHERE table_name = 'encoding_tests'; -- => utf8_general_ci
~~~

Finally, `character_set_results` is the character set used by the server when
encoding [results and metadata being sent back to the
client][com-query-response]. Column values stored in a different character set
will be converted before being sent through the pipe.


Another thing I bumped into is the fact that MySQL has both a `utf8` encoding
and a `utf8mb4` encoding. All our tables and columns are using `utf8`, which is
limited to codepoints that are encoded using a maximum of three bytes.
Codepoints that require four bytes are not supported. The `utf8mb4` type is the
one to use if you want to support the full range.


Finally, if you're communicating with MySQL through PHP and you're using
`mysql_real_escape_string`, you shouldn't send a `SET NAMES` or `SET CHARACTER
SET` query directly. Instead, use [`mysqli_set_character_set` or your
extension's equivalent][mysql-set-charset]. The escaping function does not
monitor every query being sent, and it does not query the server for the
currently set charset, so it won't be aware of any changes caused by raw
queries, [as noted by PHP's documentation][mysql-charset-escaping].

## GROUP BY limitation

Consider the following dataset, where we keep track of the date on which each
user joined the website. If we wanted a report on how many users joined each
month, we'd use a GROUP BY statement, grouping by year/month pairs.

~~~sql
SELECT * FROM users;
+----+----------+---------------------+
| id | username |date_joined          |
+----+----------+---------------------+
|  1 | squirtle | 2020-12-10 00:00:00 |
|  2 | totodile | 2020-12-15 00:00:00 |
|  3 | mudkip   | 2020-12-20 00:00:00 |
|  4 | piplup   | 2021-01-05 00:00:00 |
|  5 | oshawott | 2021-01-10 00:00:00 |
+----+----------+---------------------+

SELECT COUNT(1), YEAR(date_joined), MONTH(date_joined)
FROM users GROUP BY YEAR(date_joined), MONTH(date_joined);
+----------+-------------------+--------------------+
| count(1) | year(date_joined) | month(date_joined) |
+----------+-------------------+--------------------+
|        3 |              2020 |                 12 |
|        2 |              2021 |                  1 |
+----------+-------------------+--------------------+
~~~

The expressions in the group by statement act like a composite primary key of
the result set. Each column in the result set must either be part of the
primary key, functionally dependent on it, or an aggregate expression.

In other words, this means that you can't select columns whose value would be
ambiguous. Take the following query. It would have to return two rows, one for
each year (2020 and 2021). But for each row, there's more than one username, so
MySQL wouldn't know which one to pick:

~~~sql
SELECT COUNT(1), YEAR(date_joined), username
FROM users
GROUP BY YEAR(date_joined);

-- ERROR 1055 (42000):
-- Expression #3 of SELECT list is not in GROUP BY clause and
-- contains nonaggregated column 'test.users.username' which
-- is not functionally dependent on columns in GROUP BY clause;
-- this is incompatible with sql_mode=only_full_group_by
~~~

MySQL is able to detect some more advanced cases. For example, if you group by
a table's primary key, you're able to select any other column from that table,
since there won't be more than one table row per result row:

~~~sql
SELECT id, username FROM users GROUP BY id;
+----+----------+
| id | username |
+----+----------+
|  1 | squirtle |
|  2 | totodile |
|  3 | mudkip   |
|  4 | piplup   |
|  5 | oshawott |
+----+----------+
~~~

Given all of this, I would expect to be able to make the following query, since
the second column is functionally dependent on the `GROUP BY` expressions, but
MySQL doesn't agree:

~~~sql
SELECT COUNT(1), CONCAT(YEAR(date_joined), '-', MONTH(date_joined))
FROM users
GROUP BY YEAR(date_joined), MONTH(date_joined);

-- ERROR 1055 (42000):
-- Expression #1 of SELECT list is not in GROUP BY clause and
--   contains nonaggregated column 'test.users.date_joined' which
--   is not functionally dependent on columns in GROUP BY clause;
--   this is incompatible with sql_mode=only_full_group_by
~~~

The second column depends on `YEAR(date_joined)` and `MONTH(date_joined)`, and
both expressions are in the `GROUP BY` clause, so in theory this should work.
There's no ambiguity here. Fortunately there are some ways to work around this:

~~~sql
SELECT COUNT(1), CONCAT(YEAR(date_joined), '-', MONTH(date_joined))
FROM users
GROUP BY CONCAT(YEAR(date_joined), '-', MONTH(date_joined))

-- or
SELECT COUNT(1), CONCAT(YEAR(date_joined), '-', MONTH(date_joined)) AS month_joined
FROM users
GROUP BY month_joined
~~~

I thought that this could have been fixed in a later version of MySQL, but the
result is the same. Both MariaDB and postgresql support this.


## PHP null coalescing operator, isset, and array access overloading

In PHP, you can make your classes support the subscript operator by
implementing the [ArrayAccess interface][php-array-access]. Here's a simplified
example that caches translations stored in a database table:

~~~php
<?php

class Translation implements ArrayAccess {
  private $cache = [];
  private $locale = 'pt';
  public function offsetGet($offset) {
    if (array_key_exists($offset, $this->cache)) {
      return $this->cache[$offset];
    }

    return $this->cache[$offset] =
      select('text')->
      from('translations')->
      where(['key' => $offset, 'locale' => $this->locale]);
  }
  public function offsetExists($offset) {
    $this->offsetGet($offset);
    return $this->cache[$offset] === NULL;
  }
  public function offsetUnset($offset) { /* noop */ }
  public function offsetSet($offset, $value) { /* noop */ }
}

$t = new Translation();

echo $t['hello']; // => "Olá"
~~~

Initially, we were only implementing `offsetGet`, throwing an exception in the
other three methods. This was fine until I tried to use the [null coalescing
operator][php-null-coalescing], which raised an exception:

~~~php
<h1><?= $t['my_games_title'] ?? 'My games' ?></h1>
<!-- exception raised in Translation::offsetExists -->
~~~

I thought it would only check for `NULL` values, but it seems that it actually
uses `isset`. `isset` doesn't just check if the variable is set, but also
checks if it's not null. Also, for expressions such as `isset($t['x'])`, it
returns whatever `offsetExists` returns as a boolean:

~~~php
<?php
echo $t['my_games_title'] ?? 'My games';
// this is the same as
echo isset($t['my_games_title']) ? $t['my_games_title'] : 'My games';

$a = NULL;
$b = 0;
echo isset($a) // => false
echo isset($b) // => true
echo isset($c) // => false

echo isset($t['hello']);
// this is the same as
echo (bool)$t->offsetExists('hello');
~~~

While investigating this behavior, I discovered that PHP supports using the
["ternary operator" (`?:`)][php-ternary-operator] as... a binary operator,
which is similar to `??` but using `!empty` instead of `isset`:

~~~php
echo $t['my_games_title'] ?: 'My games';
// this is the same as
echo !empty($t['my_games_title']) ? $t['my_games_title'] : 'My games';
~~~

<aside markdown="1">
  If you enjoy my work, consider sponsoring me so I can keep on doing this full
  time: <https://github.com/sponsors/hugopeixoto>
</aside>

[insert-set]: https://dev.mysql.com/doc/refman/8.0/en/insert.html
[handshake-response]: https://dev.mysql.com/doc/internals/en/connection-phase-packets.html#packet-Protocol::HandshakeResponse
[charset-introducers]: https://dev.mysql.com/doc/refman/8.0/en/charset-introducer.html
[com-query-response]: https://dev.mysql.com/doc/internals/en/com-query-response.html
[mysql-set-charset]: https://www.php.net/manual/en/mysqli.set-charset.php
[mysql-charset-escaping]: https://www.php.net/manual/en/mysqlinfo.concepts.charset.php
[php-array-access]: https://www.php.net/manual/en/class.arrayaccess.php
[php-null-coalescing]: https://www.php.net/manual/en/language.operators.comparison.php#language.operators.comparison.coalesce
[php-ternary-operator]: https://www.php.net/manual/en/language.operators.comparison.php#language.operators.comparison.ternary
