---
title: Rails and PostgreSQL prepared statements leak
created_at: 2015-08-29
excerpt: |
  Postgres database memory usage went crazy due to a prepared statement "leak"
  in the code of a ruby on rails application. By adding a debug endpoint that lists
  every prepared statement of the current connection, I was able to figure out the source
  of the issue and fix it.
---

At work, we have several services running on rails backed by a postgres
database. One day, after a few changes, we noticed that postgresql memory usage
kept growing up to the point where the server restarted due to out of memory
issues.

After a bit of debugging and [searching through rails github
issues](https://github.com/rails/rails/issues/14645), I noticed that the number
of prepared statements created by each rails database connection was increasing
with time, until it reached the pool size limit ([which defaults to
1000](https://github.com/rails/rails/blob/master/activerecord/lib/active_record/connection_adapters/postgresql_adapter.rb#L258)).
This meant that a method was probably generating a prepared statement with
hardcoded values in the query, instead of using a bind parameter.

To find out which section of the code was to blame, I added a debug endpoint to
our service that returned the list of prepared statements for the current
connection:

~~~~ruby
module DebugPreparedStatements
  def self.count
    all.count
  end

  def self.all
    ActiveRecord::Base
      .connection
      .execute("select * from pg_prepared_statements")
      .map do |x|
        {
          name: x["name"],
          statement: x["statement"],
          created_at: DateTime.parse(x["prepare_time"])
        }
      end
  end
end

class DebugController < ApplicationController
  def prepared_statements
    render json: { data: DebugPreparedStatements.all }
  end
end
~~~~

I deployed this to a staging environment with a single unicorn worker and
started making requests. It was important to either use a single worker or
configure the database connection pool size to one. Otherwise, the call to
*`/debug/prepared_statements`* would return inconsistent results, as each
connection has its own set of prepared statements.

After a while, a pattern started to emerge. Each call to *`/api/products/:id`*
with a different id would generate a new prepared statement. After going
through roughly 1000 different ids, the number of prepared statements stopped
growing, as expected.

Being able to see the actual prepared statement helped to detect which method
was causing this. It turned out that we were using string interpolation to
create a join statement with a subquery, and that subquery had the product id
in it. Due to the string interpolation, the id was being hardcoded into the
prepared statement. The offending code looked something like this:

~~~~ruby
# `files` is an ActiveRecord::Relation object with bind parameters
def foo(files)
  maximals = files.group('...').select('...')

  ids = files.joins("NATURAL JOIN (#{maximals.to_sql}) x")

  # ...
end
~~~~

After fixing this issue with some Arel magic, the number of prepared statements
would not grow above 30, which is a much more reasonable number.
