---
kind: article
title: Knee deep in a LAMP project
created_at: 2020-08-08
excerpt: |
  I've been lending a hand with the development of Cyberscore. It's a video
  game records community with almost 20 years of existence. I have a friend
  that sometimes helps out with maintenance, and they were having some issues
  so I decided to help out as well.
---

<aside markdown="1">
  I am accepting sponsors via github: <https://github.com/sponsors/hugopeixoto>

  If you enjoy my work, consider sponsoring me so I can keep on doing this full
  time.
</aside>

I've been lending a hand with the development of
[Cyberscore](https://www.cyberscore.me.uk/). It's a video game records
community with almost 20 years of existence. I have a friend that sometimes
helps out with maintenance, and they were having some issues so I decided to
help out as well.

[The site history](https://www.cyberscore.me.uk/history.php) tells us that the
current version started development in 2007. This was when frameworks like
[Rails](https://rubyonrails.org), [CakePHP](https://cakephp.org/) and
[Django](https://www.djangoproject.com/) were starting to gain traction.

This codebase doesn't use any frameworks, though. It's what I'd call
[LAMP](https://en.wikipedia.org/wiki/LAMP_%28software_bundle%29)-style.

## LAMP-style PHP

In this style, you put your PHP files in the directory that's being served by
`apache2`, and access them directly from the browser: Access
`https://example.com/hello.php` and it would serve the file
`/var/www/html/hello.php`, preprocessed by
[mod_php](https://www.php.net/manual/en/install.unix.debian.php).

The router was the file system, sometimes enhanced by an [`.htaccess`
file](https://en.wikipedia.org/wiki/.htaccess).

It was common for people to accidentally misconfigure apache and end up serving
the source code instead of the processed result. This was particularly
dangerous because you'd have the database password or other credentials
hardcoded into the source.

It was also common to suffer from SQL injections. SQL queries were built by
concatenating strings and user input, and user input was not always escaped.

The way files were laid out lended itself to a specific pattern. A typical PHP
page would look like this:

~~~~php
<?php require_once("db.php"); ?>
<?php require_once("header.php"); ?>
<h1>Welcome to my blog</h1>
<?php
  $posts = db_query("SELECT * FROM posts ORDER BY published_date");
  while ($post = mysqli_fetch_assoc($posts)) {
?>
  <h2><?php echo $post['title']; ?></h2>
  <p><?php echo nl2br($post['body']); ?></p>
<?php } ?>
<?php require_once("footer.php"); ?>
~~~~

This makes it very easy to use. Shared hosts were very popular, everything
configured for you. You'd just need to open up a php file and start writing
code. On the other hand, SQL, PHP, and HTML were tightly linked. This could
become a maintenance nightmare if you weren't disciplined.

One thing that was great about PHP is that each function (see
[array_map](https://www.php.net/manual/en/function.array-map.php), for example)
had plenty of examples and use cases, along with user contributed notes.

[PHP had plenty of
criticism](https://eev.ee/blog/2012/04/09/php-a-fractal-of-bad-design/), but it
was super easy to get a website working.

MySQL was always included in the bundle, coupled with
[phpMyAdmin](https://www.phpmyadmin.net/). The web admin allows you to query
the database, create or change tables with a few clicks.

There were two MySQL common storage engines: MyISAM (the default) and InnoDB. MyISAM
does not support transactions nor foreign keys, but since it was the default,
it's what everyone used. The default
[collation](https://en.wikipedia.org/wiki/Collation) was also a weird one:
`latin1_swedish_ci`.

I recently found out that MySQL has an option that you can disable called
[strict
mode](https://dev.mysql.com/doc/refman/8.0/en/sql-mode.html#sql-mode-strict).
If you disable it, tables with non-NULL columns with no default value stop
requiring that you specify their values when inserting rows. They also stop
requiring that you pass valid values. Instead of erroring out, MySQL picks a
value for you (usually the zero value for that type).

Not having strict mode can cause some surprises. Here's are some SQL queries
that got me confused me for a while:

~~~~sql
select count(1) from games where date_published is null;
2214
select count(1) from games where date_published is not null;
2511
select count(1) from games;
2511
~~~~

Most values in this table are considered both null **and** not null. Turns out
this happens when you have the datetime `0000-00-00 00:00:00`, which is not a
valid date, but allowed when strict mode is disabled. This is documented in
[this bug](https://bugs.mysql.com/bug.php?id=940) and the [IS NULL operator
documentation](https://dev.mysql.com/doc/refman/8.0/en/comparison-operators.html):

> For DATE and DATETIME columns that are declared as NOT NULL, you can find the
> special date '0000-00-00' by using a statement like this:
>
> `SELECT * FROM tbl_name WHERE date_column IS NULL`
>
> This is needed to get some ODBC applications to work because ODBC does not
> support a '0000-00-00' date value.

One thing that for me marks the difference between mysql and postgresql is the
handling of selected columns in queries with group by statements.

I just hit this when trying to get the game that has the most record submissions.

~~~~sql
-- mysql happily picks an arbitrary game_id
select game_id, count(1) from records order by 2 desc limit 2;
2, 1440821

-- pgsql complains that I can't just use game_id
select game_id, count(1) from records order by 2 desc limit 2;
ERROR:  column "records.game_id"
        must appear in the GROUP BY clause
        or be used in an aggregate function

-- the query that I actually wanted to write
select game_id, count(1) from records group by game_id order by 2 desc limit 2;
 23, 62421
390, 37054
~~~~

In MySQL, you can select columns that were not in the GROUP BY clause without
any aggregate functions. When I first started using postgresql I used to
complain that it didn't behave like mysql, but they eventually added support
for selecting functionally dependent columns, which is what you usually want.

Selecting functionally dependent columns means that you can group by a table
primary key and select the other columns from that table, since they're
guaranteed to be unique. The first query would work in postgresql, while the
second wouldn't:

~~~~sql
-- games.game_name is functionally dependent on games.game_id
select games.game_id, games.game_name, count(1) as total_records
from records
join games using (game_id)
group by games.game_id

-- records.user_id is not functionally dependent on games.game_id
select games.game_id, records.user_id, count(1) as total_records
from records
join games using (game_id)
group BY games.game_id
~~~~


## Cyberscore

The website relies on cached score and ranking calculations whose rebuild
process is queued whenever someone submits a new record. The whole thing stops
responding for a few minutes at a time, and sometimes the server even reboots.
The maintainers were delaying those cronjobs to try to alleviate the problem,
but it kept happening.

We started by adding a swap file to reduce errors caused by RAM usage bursts.

Next, I started investigating their cron jobs. Most of these were introduced
when running the calculations inline became too costly, and they were usually
written under pressure because the cost of running them inline brought the
website down.

I started with one that rebuilds the scoreboards for a given game. There are
some complex calculations going on, but rebuilding the scoreboards for [Super
Smash Bros. Melee](https://www.cyberscore.me.uk/game/23) was taking ~10 minutes
on my laptop.

To profile this, I wrote a helper function:

~~~~php
function wikilog($message) {
  // every query goes through a db_query function that
  // tracks total number of queries done so far.
  global $db_num_queries;

  static $previous = 0;
  static $previous_db_queries = 0;

  if ($previous == 0) $previous = hrtime(true);
  if ($previous_db_queries == 0) $previous_db_queries = $db_num_queries;
  $now = hrtime(true);
  $delta = $now - $previous;
  $previous = $now;

  $delta_queries = $db_num_queries - $previous_db_queries;
  $previous_db_queries = $db_num_queries;

  $secs = intdiv($delta, 1000000000);
  $msecs = intdiv($delta, 1000000) % 1000;

  echo "[$delta_queries sql][{$secs}s{$msecs}ms] $message\n";
  flush();
  ob_flush();
}
~~~~

This function prints the time ellapsed and number of queries between two
consecutive calls. It has a very specific name because I want to be able to get
rid of them at commit time, and it also helps navigating between them.

Placing one call at the start of the file and one at the end reported that this
script made a whopping *160 thousand* queries.

Given that the game has ~60k records submitted from ~600 different users, we
probably have a N+1 problem.

The first thing I did was clean up the indentation of the file. There was a mix
of tabs and spaces, SQL queries were not split across several lines, and the
brace style was inconsistent. Not only did it make editing easier, it also
forced me to read through the code and understand what was going on, and how
some pieces of code were more or less copy-pasted in several places.

I kept sprinkling `wikilog`s through the code and changed the code to improve
these numbers. Most of the problems came from this kind of pattern:


~~~php
function foo($game_id) {
  $users = db_query("
    SELECT user_id, SUM(some_fields)
    FROM records
    WHERE game_id = $game_id
    GROUP BY user_id
  ");

  while ($user = mysqli_fetch_assoc($users)) {
    $total_users = db_query("
      SELECT COUNT(DISTINCT user_id)
      FROM records
      WHERE game_id = $game_id
    ");

    $score = foo_score($game_id, $user, $total_users);

    db_query("
      INSERT INTO foo_cache (user_id, score)
      VALUES ({$user['user_id']}, $total_users)
    ");
  }
}
~~~

Note that the `$total_users` query doesn't depend on `$user` at all, so it can
be moved to before the user loop. Sometimes the queries used `$user`, but they
could be folded onto the `$users` query through joins or extra selections.

I also built an `insert_all` function to mass insert the cached values. This
requires more memory, since we'd be keeping everything in an array and
stringify it into a single query. The number of iterations is under 1000,
though, so the extra memory usage doesn't cause any problems.

The final result looked a bit like this:

~~~php
function foo($game_id) {
  $users = db_query("
    SELECT user_id, SUM(some_fields)
    FROM records
    WHERE game_id = $game_id
    GROUP BY user_id
  ");

  $total_users = db_query("
    SELECT COUNT(DISTINCT user_id)
    FROM records
    WHERE game_id = $game_id
  ");

  $records = [];
  while ($user = mysqli_fetch_assoc($users)) {
    $score = foo_score($game_id, $user, $total_users);

    $records[]= array('user_id' => $user['user_id'], 'score' => $total_users);
  }
  insert_all("foo_cache", $records);
}
~~~

The constant queries weren't always obvious. Sometimes they'd be in functions
that were written to be used elsewhere, so it's expected that they decided to
reuse them, not considering this cost.

Right now, this example is taking ~35 seconds to run, and it makes 1400
queries. It still sounds like a lot, but since this is running in a cron job,
it's acceptable. The missing N+1 situation would require a monster query and it
would probably kill the readability of the thing, so I opted for moving to
other sections to optimize.

Here's another example where rewriting the function helped me understand what
was going on and detect a bug:

~~~~php
else if ($p_function == 'TransferModifiers') {
    $modifiers = db_query("SELECT * FROM levels JOIN level_modifiers USING level_id");

    while($chart = db_get_result($modifiers))
    {
        db_query("DELETE FROM chart_modifiers WHERE level_id = '".$chart['level_id']."'");

        $m = db_query("SELECT * FROM level_modifiers WHERE level_id = '".$chart['level_id']."'");
        $chart_type = db_extract("SELECT ranked FROM levels WHERE level_id = '".$chart['level_id']."'");
        $game_id = db_extract("SELECT game_id FROM levels WHERE level_id = '".$chart['level_id']."'");
        if($chart_type == 3) $r->AddModifier($chart['level_id'], $game_id, "chart_flag", 1);
        if($chart_type == 6) $r->AddModifier($chart['level_id'], $game_id, "chart_flag", 2);
        if($m['user_challenge'] == 1) $r->AddModifier($chart['level_id'], $game_id, "chart_flag", 4);
        if($m['unranked'] == 1) $r->AddModifier($chart['level_id'], $game_id, "chart_flag", 2);
            if($m['region_differences'] == 1) $r->AddModifier($chart['level_id'], $game_id, "csp_modifier", 1); //Regional Differences
            if($m['device_differences'] == 1) $r->AddModifier($chart['level_id'], $game_id, "csp_modifier", 2); //Device Differences
            if($m['big_regional'] == 1) $r->AddModifier($chart['level_id'], $game_id, "csp_modifier", 3); //Regional Differences (significant)
            if($m['big_device'] == 1) $r->AddModifier($chart['level_id'], $game_id, "csp_modifier", 4); //Device Differences (significant)
            if($m['patience_chart'] == 1) $r->AddModifier($chart['level_id'], $game_id, "csp_modifier", 5); //Patience Chart
            if($m['computer_generation'] == 1) $r->AddModifier($chart['level_id'], $game_id, "csp_modifier", 6); //Computer Generated Chart
            if($m['earnable_upgrades_mtx'] == 1) $r->AddModifier($chart['level_id'], $game_id, "csp_modifier", 7); //Earnable Premium Upgrades
            if($m['unearnable_upgrades_mtx'] == 1) $r->AddModifier($chart['level_id'], $game_id, "csp_modifier", 8); //Non-Earnable Premium Upgrades
            if($m['premium_dlc'] == 1) $r->AddModifier($chart['level_id'], $game_id, "csp_modifier", 9); //Premium DLC
    }
        $cs->WriteNote(true, "Modifiers Rebuild");
    $redirect = "/mod_scripts/rebuild_center.php";
}
~~~~

This was on the top level of a file, not in a function. Note the mixed
indentation (those are spaces and tabs). The first step was to extract the meat
of the code into a function, so that I could easily call it from a custom
script.

~~~~php
function TransferModifiers() {
  global $r;
  $modifiers = db_query("SELECT * FROM levels JOIN level_modifiers USING level_id");

  while($chart = db_get_result($modifiers)) {
    db_query("DELETE FROM chart_modifiers WHERE level_id = '".$chart['level_id']."'");

    $m = db_query("SELECT * FROM level_modifiers WHERE level_id = '".$chart['level_id']."'");
    $chart_type = db_extract("SELECT ranked FROM levels WHERE level_id = '".$chart['level_id']."'");
    $game_id = db_extract("SELECT game_id FROM levels WHERE level_id = '".$chart['level_id']."'");

    if ($chart_type == 3) $r->AddModifier($chart['level_id'], $game_id, "chart_flag", 1);
    if ($chart_type == 6) $r->AddModifier($chart['level_id'], $game_id, "chart_flag", 2);
    if ($m['user_challenge'] == 1) $r->AddModifier($chart['level_id'], $game_id, "chart_flag", 4);
    if ($m['unranked'] == 1) $r->AddModifier($chart['level_id'], $game_id, "chart_flag", 2);

    if ($m['region_differences'] == 1) $r->AddModifier($chart['level_id'], $game_id, "csp_modifier", 1); //Regional Differences
    if ($m['device_differences'] == 1) $r->AddModifier($chart['level_id'], $game_id, "csp_modifier", 2); //Device Differences
    if ($m['big_regional'] == 1) $r->AddModifier($chart['level_id'], $game_id, "csp_modifier", 3); //Regional Differences (significant)
    if ($m['big_device'] == 1) $r->AddModifier($chart['level_id'], $game_id, "csp_modifier", 4); //Device Differences (significant)
    if ($m['patience_chart'] == 1) $r->AddModifier($chart['level_id'], $game_id, "csp_modifier", 5); //Patience Chart
    if ($m['computer_generation'] == 1) $r->AddModifier($chart['level_id'], $game_id, "csp_modifier", 6); //Computer Generated Chart
    if ($m['earnable_upgrades_mtx'] == 1) $r->AddModifier($chart['level_id'], $game_id, "csp_modifier", 7); //Earnable Premium Upgrades
    if ($m['unearnable_upgrades_mtx'] == 1) $r->AddModifier($chart['level_id'], $game_id, "csp_modifier", 8); //Non-Earnable Premium Upgrades
    if ($m['premium_dlc'] == 1) $r->AddModifier($chart['level_id'], $game_id, "csp_modifier", 9); //Premium DLC
  }
}
~~~~

You can see that the `$m`, `$chart_type`, and `$game_id` queries are all
redundant. Those fields were already selected in `$modifiers`, so they could be
removed and replaced with references to `$chart`.

The if statements also felt a bit noisy. There's a lot of repetition of
`$r->addModifier($chart['level_id'], $game_id', X, Y)`. It makes it hard to see
what's important.

`AddModifier` makes an `INSERT` query, so I also decided to replace them with
`insert_all`.

The `DELETE` query was also inside the loop, so I moved it out. In this case, I
decided it would be OK to delete every record, since there's a 1-1 mapping
between `chart_modifiers` and `level_modifiers`.

This is the result:

~~~~php
function TransferModifiers() {
  global $r;
  $level_modifiers = db_query("SELECT * FROM levels JOIN level_modifiers USING level_id");
  db_query("DELETE FROM chart_modifiers");

  $modifiers = [];
  while ($m = db_get_result($level_modifiers)) {
    $csp_modifiers = [];
    $chart_modifiers = [];

    if ($m['ranked'] == 3)         $chart_modifiers[]= 1;
    if ($m['ranked'] == 6)         $chart_modifiers[]= 2;
    if ($m['user_challenge'] == 1) $chart_modifiers[]= 4;
    if ($m['unranked'] == 1)       $chart_modifiers[]= 2;

    if ($m['region_differences'] == 1)      $csp_modifiers[]= 1; //Regional Differences
    if ($m['device_differences'] == 1)      $csp_modifiers[]= 2; //Device Differences
    if ($m['big_regional'] == 1)            $csp_modifiers[]= 3; //Regional Differences (significant)
    if ($m['big_device'] == 1)              $csp_modifiers[]= 4; //Device Differences (significant)
    if ($m['patience_chart'] == 1)          $csp_modifiers[]= 5; //Patience Chart
    if ($m['computer_generation'] == 1)     $csp_modifiers[]= 6; //Computer Generated Chart
    if ($m['earnable_upgrades_mtx'] == 1)   $csp_modifiers[]= 7; //Earnable Premium Upgrades
    if ($m['unearnable_upgrades_mtx'] == 1) $csp_modifiers[]= 8; //Non-Earnable Premium Upgrades
    if ($m['premium_dlc'] == 1)             $csp_modifiers[]= 9; //Premium DLC

    foreach ($chart_modifiers as $modifier) {
      $modifiers[]= array(
        'game_id' => $chart['game_id'],
        'level_id' => $chart['level_id'],
        'type' => 'chart_flag',
        'value' => $modifier)
    }

    foreach ($csp_modifiers as $modifier) {
      $modifiers[]= array(
        'game_id' => $chart['game_id'],
        'level_id' => $chart['level_id'],
        'type' => 'csp_modifier',
        'value' => $modifier)
    }
  }

  insert_all('chart_modifiers', $modifiers);
}
~~~~

The function became a bit longer, as a consequence of inlining and batching
`AddModifier`. It could make sense to make some extra changes to avoid that
repetition.

Once thing I noticed after this change is that the `chart_modifiers` values are
`1, 2, 4, 2`. Two modifiers with the same value seemed odd, and indeed it
should have been `3`.

Now I'm focusing on improving page loads. [The full game
list](https://www.cyberscore.me.uk/games.php?site_id=all) had a stray query
inside the games loop, for example.

Using the `wikilog` function here would sometimes screw up the page layout, so
I started using an adapted version that would capture all the debug messages
and print them at the end of the page:

~~~~php
$wikilog_messages = array();

function delayed_wikilog() {
  global $wikilog_messages;
  echo "<div style='background-color: white'>";
  foreach($wikilog_messages as $message) {
    echo "<p>[{$message['sql']} sql][{$message['time']}] {$message['message']}";
    echo "</p>";
  }
  echo "</div>";
}

function wikilog_register($message) {
  global $db_num_queries;
  global $wikilog_messages;

  static $previous = 0;
  static $previous_db_queries = 0;

  if ($previous == 0) $previous = hrtime(true);
  if ($previous_db_queries == 0) $previous_db_queries = $db_num_queries;
  $now = hrtime(true);
  $delta = $now - $previous;
  $previous = $now;

  $delta_queries = $db_num_queries - $previous_db_queries;
  $previous_db_queries = $db_num_queries;

  $secs = intdiv($delta, 1000000000);
  $msecs = intdiv($delta, 1000000) % 1000;

  $wikilog_messages[]= array('sql' => $delta_queries, 'time' => "{$secs}s{$msecs}ms", 'message' => $message);
}
~~~~

My current task is optimizing the view_records.php page (which I'm not linking
to avoid encouraging people from visiting it until it's fixed), and while it
doesn't have many queries, it's calling
[get_headers](https://www.php.net/manual/en/function.get-headers.php), which
makes an HTTP request, once per record. Fixing this is probably going to be a
bit more involved.

## Conclusion

I'm having fun. I haven't touched a codebase using this style in a long time,
and there's a lot of low hanging fruit.

It's impressive that the Cyberscore community has kept this platform going for
so many years, as a hobby project.

I'm trying to keep a balance between optimizing things and keeping code
accessible. I'd like to eventually turn MySQL's strict mode back on, and maybe
add a migration tool (someone recommended [Phinx](https://phinx.org/)) at least
to keep track of indexes.

But before I do any of that, I want to spend some more time optimizing the
existing pages. Let's see if I can get anything done before this year's
[SGDQ](https://gamesdonequick.com/).
