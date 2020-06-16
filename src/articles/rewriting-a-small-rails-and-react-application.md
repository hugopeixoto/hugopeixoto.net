---
kind: article
title: Rewriting a small rails & react application
created_at: 2020-06-16
---

## Introduction

In 2017, Life on Mars helped build <http://mentor.alumniei.pt/>. It's a portal
where college students can contact alumni (mentors) when they're facing career,
academic, or personal issues. We built the platform, contacted some alumni
members, but never got around to publish it. There's some talk of reviving the
project, so I decided to spend some time refreshing the code base and improving
things that, in retrospective, are off.

Here are some of the things that I think we should fix, even before logging in
to the platform or checking out the code:

- The website in english. We have translations set up, but they're not
  deployed. We have some static-ish content, like preset tag names, in database
  tables, and those are not translatable.
- The color scheme was not picked with accessibility in mind. The contrast on
  some of the text is very low. We should do some accessibility studies.
- We don't have `https`. I'm not even sure how this happened. We should enable
  it.
- We didn't plan for any abuse or moderation. Mentor/student communication
  happens outside the platform, so on one hand this increases their privacy but
  also exposes both parties. Mentors have their information available for
  anyone with a `@fe.up.pt` email address, which may be used for stalking or
  other bad behavior. We should review this with these misuse cases in mind.
- There's no privacy policy. Similar to the point above.

On the code side of things, the project has two components: a [rails api only
backend](https://github.com/lifeonmarspt/mentorados-backend) and a [react
frontend](https://github.com/lifeonmarspt/mentorados-frontend). These are both
deployed to Heroku as separate apps. Since we're currently serving this from
free apps, the cold start time isn't the best.

The project is not very big. You can log in as either a student or an mentor.
Mentors can edit their profile, and students can view and filter mentors.
There's no communication inside the website itself. Mentors specify their
preferred communication methods. There are some admin use cases as well.

Across both projects, this has 1200 lines of ruby, 3000 lines of jsx and 500
lines of scss.

I'm usually on board with this backend/frontend split, but in a single-ish
person team, with a project this small, I will be better served by a rails
monolith. I'm also not a big fan of requiring javascript to use the platform.

Before I do any of the improvements I mentioned, I'll start by putting this all
in a single codebase, without any javascript.

In this post, I will set up a rails application from scratch, with my personal
flavor of gems and modifications. Then I'll go through the process of adding
the registration flow.


## Setting up a new rails project

I'll be using ruby 2.7.0 in this project. I'm not sure if this is going to
work. I had some issues with rails spewing out a bunch of warnings before, but
maybe it's already fixed. I manage my ruby installations with
[asdf](https://asdf-vm.com/).

Usually, you're told to install rails globally so that you can run `rails new`.
I avoid that by creating an initial Gemfile with just the following:

~~~~ ruby
source "https://rubygems.org"

gem "rails"
~~~~

Rails has recently added a `rails new --minimal` option to disable things like
`spring`, `actiontext`, and other gems. This feature is not released yet, so I
created an app with a lot of options to disable things I don't like or use.

~~~~
$ bundle exec rails new \
  --skip-action-cable \
  --skip-action-mailbox \
  --skip-spring \
  --skip-turbolinks \
  --skip-webpack-install \
  --database=postgresql \
  .
~~~~

I'm removing `spring` because I don't trust it. Bootsnap seems to work fine,
though. `ActionMailbox` handles incoming email messages, which I won't need
here. `ActionCable` won't be needed either. I'm going with a no javascript
approach at first, so I'm also skipping turbolinks and webpack.

Running this will cause rails to ask to overwrite `Gemfile`, which is something
I want. This is enough to get the app started, but I do some changes to the
Gemfile before moving on.

I remove gems I don't need. In this case, I removed `webpacker`, `jbuilder`,
and `webdriver` related gems.

I remove most comments. They don't serve me any purpose after an initial scan.

I remove version restrictions for most gems. I rely on dependabot to create PRs
for the upgrades instead of doing them manually, and I want to keep up with
major version releases.

I sort gems in each group alphabetically. It makes the decision of where to put
new gems easy. Also, rubocop-rails enforces this by default.

The next step is adding some gems that I know I will use. Here's a list:

- [`dotenv-rails`](https://github.com/bkeepers/dotenv), to load `.env` files
  onto `ENV`
- [`factory_bot_rails`](https://github.com/thoughtbot/factory_bot_rails), to
  replace fixtures in rails tests
- [`faker`](https://github.com/faker-ruby/faker), to generate fake data, mostly
  in tests
- [`pundit`](https://github.com/varvet/pundit), to build the authorization system
- [`rubocop`](https://github.com/rubocop-hq/rubocop), a ruby linter
- [`rubocop-rails`](https://github.com/rubocop-hq/rubocop-rails), rails
  specific rules
- [`rubocop-performance`](https://github.com/rubocop-hq/rubocop-rails),
  performance specific rules

Most of these gems are useful in development or test environments. `pundit` is
the only one that will run in production. I probably will need some extra gems
as I add more code, but I'll figure those out along the way.

Before continuing, I need to tweak `.rubocop.yml` and fix `rubocop` warnings.
Rails does not generate a rubocop compatible project, so there's some work to do.
This is what my `.rubocop.yml` looks like:

~~~~ yaml
# I need to enable the extra plugins
require:
  - rubocop-performance
  - rubocop-rails

AllCops:
  # I'm excluding rails generated files to make
  # rails version upgrades easier.
  Exclude:
    - "db/**/*"
    - "bin/*"
    - "config.ru"
    - "config/**/*"
    - "Rakefile"
    - "vendor/**/*"
  # New cops that show up in new rubocop versions
  # should be enabled by default to avoid polutting
  # this config file.
  NewCops: enable

# I have become a trailing comma person
Style/TrailingCommaInArrayLiteral:
  EnforcedStyleForMultiline: comma

Style/TrailingCommaInHashLiteral:
  EnforcedStyleForMultiline: comma

Style/TrailingCommaInArguments:
  EnforcedStyleForMultiline: comma

# I don't want to be forced to write documentation for every class/module
Style/Documentation:
  Enabled: false
~~~~

The next step is to configure a database. I already have dotenv installed, so I
need to:

- add `DATABASE_URL=postgres://localhost/mentorados_development` to `.env.development.local`
- add `DATABASE_URL=postgres://localhost/mentorados_test` to `.env.test.local`
- run `git rm config/database.yml`
- add `/.env*.local` to `.gitignore`
- run `bin/rails db:create`
- run `RAILS_ENV=test bin/rails db:create`

Another thing that I also need to configure is the application timezone. This
application is aimed at a portuguese university, but I like having everything
in UTC and dealing with conversion at display time, if needed. I'll add this
initializer:

~~~~ ruby
# config/initializers/timezone.rb
Rails.application.config.time_zone = 'UTC'
Rails.application.config.active_record.default_timezone = :utc
~~~~

Running rails with `bundle exec rails server` now displays the "Yay! You're on
Rails!" page. I'm ready to start adding functionality.

![Rails default index page, showing Rails and Ruby versions](/articles/yay-rails.png)


## Adding user registration - Database

Before starting to create tables, I need to enable the `uuid` extension and use
it as the default primary key type:

~~~~ ruby
# db/migrate/20200608144955_enable_extension_uuid.rb
class EnableExtensionUuid < ActiveRecord::Migration[6.0]
  def change
    enable_extension 'pgcrypto'
  end
end

# config/initializers/generators.rb
Rails.application.config.generators do |g|
  g.orm :active_record, primary_key_type: :uuid
end
~~~~

The extension lets me use the `uuid` data type and the `gen_random_uuid()`
function. The generator configuration makes it that `bin/rails g migration`
generates code with `uuid` primary keys.

I want to keep the database close to what we had in the API only version. The
main entity here is `user`, which represents both students and mentors. Most of
the attributes are for mentor accounts. The only information we store on
students are the email address and password digest. I could split this up into
a `users` table, for login information, and a `mentors` table, for mentor
profiles, but the tradeoff isn't worthwhile. It introduces complexity and the
only gains are that it becomes clearer which attribute is for mentors and which
attributes are for every user. This is what the old `users` table looked like:


~~~~ ruby
create_table "users", id: :uuid do |t|
  t.string "email", null: false
  t.string "password_digest"
  t.boolean "blocked", default: false
  t.boolean "admin", default: false, null: false
  t.boolean "mentor", default: false, null: false
  t.boolean "active", default: false
  t.text "name"
  t.text "bio"
  t.text "picture_url"
  t.text "picture"
  t.integer "year_in"
  t.integer "year_out"
  t.text "links", default: [], array: true
  t.text "location"
  t.datetime "created_at", null: false
  t.datetime "updated_at", null: false
  t.index ["email"], name: "index_users_on_email", unique: true
end
~~~~

The fields `email`, `password_digest`, and `blocked` are account related
fields. `admin` and `mentor` are role fields. `created_at` and `updated_at` are
standard rails fields, for auditing purposes. The other fields are mentor
profile fields. If I decided to split this into two tables, it would look
something like this:

~~~~ ruby
create_table "users", id: :uuid do |t|
  t.string "email", null: false
  t.string "password_digest"
  t.boolean "blocked", default: false
  t.boolean "admin", default: false, null: false

  t.timestamps
  t.index ["email"], name: "index_users_on_email", unique: true
end

create_table "mentors", id: :uuid do |t|
  t.references :user, type: :uuid, null: false,
               foreign_key: true, index: { unique: true }

  t.boolean "active", default: false
  t.text "name"
  t.text "bio"
  t.text "picture_url"
  t.text "picture"
  t.integer "year_in"
  t.integer "year_out"
  t.text "links", default: [], array: true
  t.text "location"
  t.timestamps
end
~~~~

Maybe in a future iteration this separation will be worthwhile, but not for
now. I might want to have admins review changes to mentor profiles before they
go live, as a moderation step. If I do it, the split might make sense then.

I changed the migration to set the email uniqueness constraint to
`lower(email)` instead of just `email` to avoid having multiple users with the
same email in different cases. This is not in the standard, but most email
providers treat their addresses as case insensitive.


## Adding user registration - Routes

Now that I have the database set up, I'll create the model, routes, and
controllers. This is where you might use something like
[`devise`](https://github.com/heartcombo/devise) or
[`clearance`](https://github.com/thoughtbot/clearance). I'm going with using
rails's [`has_secure_password`
feature](https://guides.rubyonrails.org/active_model_basics.html#securepassword).

I will have four routes related to registrations:

- `GET /registrations/new` displays the registration form. I may alias it to `GET /register`.
- `POST /registrations` registers a new user and sends a confirmation email
- `GET /registration/:id`, linked in the email, displays a confirmation form
- `POST /registrations/:id/confirm` confirms the registration

This is what the routes for these endpoints look like:

~~~~ ruby
Rails.application.routes.draw do
  resources :registrations, only: %i[create new show] do
    member do
      post :confirm
    end
  end
end
~~~~

~~~~
$ bin/rails routes
              Prefix Verb URI Pattern                           Controller#Action
confirm_registration POST /registrations/:id/confirm(.:format)  registrations#confirm
       registrations POST /registrations(.:format)              registrations#create
    new_registration GET  /registrations/new(.:format)          registrations#new
        registration GET  /registrations/:id(.:format)          registrations#show
~~~~

I will need a registration ID and a way to track which users are confirmed. The
ID should not be guessable, as the purpose of this is to only allow the email
account owner to confirm the registration. I can either create a
`registrations` table, with a `confirmed_at` field, or add `registration_id`
and `confirmed_at` to the users table.

I'm going with the second approach. Since there's only one registration per
account, I don't think I'm losing anything. When I start working on the
password recovery flow, I might have a separate table, so that we can keep
track of every password recovery ever, for auditability.

Calling the new field `registration_id` could be misleading, because it looks
like a foreign key. I am aware of this and will proceed anyway. This is the
migration:

~~~~ ruby
class AddRegistrationIdAndConfirmedAtToUsers < ActiveRecord::Migration[6.0]
  def change
    change_table :users do |t|
      t.datetime :confirmed_at
      t.uuid :registration_id,
             null: false,
             unique: true,
             default: -> { "gen_random_uuid()" }
    end
  end
end
~~~~


## Adding user registration - Model

The `User` model will have some validations, and I'm also adding some scopes
and accessors that I will need soon:

~~~~ ruby
class User < ApplicationRecord
  scope :confirmed, -> { where.not(confirmed_at: nil) }
  scope :confirmation_pending, -> { where(confirmed_at: nil) }
  scope :student, -> { where(mentor: false) }
  scope :mentor, -> { where(mentor: true) }

  validates :email, presence: true, uniqueness: { case_sensitive: false }
  validate :validate_feup_email, on: :create, if: -> { student? }

  after_create :reload

  has_secure_password

  def confirmed?
    !confirmed_at.nil?
  end

  def student?
    !mentor
  end

  def mentor?
    mentor
  end

  def confirm!
    update(confirmed_at: Time.current)
  end

  private

  def validate_feup_email
    return if email.split('@').last == 'fe.up.pt'

    errors.add(:email, :feup_address_required)
  end
end
~~~~

I'm using a symbol `:feup_address_required` in `errors.add` to be able to
translate it.

Another gotcha here is that since the `registration_id` column has a database
default, `User#create` does not return a model with that column value. To
ensure it always gets loaded, there's a `after_create :reload` hook. This, by
itself, may be enough reason to create defaults in rails instead of in
postgresql until this gets solved. Here's the link to the issue:

<https://github.com/rails/rails/issues/34237>

It looks like it might be a good candidate for a pull request.

This model has a lot of code. Usually I would move on to work on the
controllers, but since there's already some logic in here, I'll add some tests
first.

~~~~ ruby
# test/test_helper.rb
ENV['RAILS_ENV'] ||= 'test'
require_relative '../config/environment'
require 'rails/test_help'

module ActiveSupport
  class TestCase
    parallelize(workers: :number_of_processors)

    include FactoryBot::Syntax::Methods
  end
end

# cat test/factories/users.rb
FactoryBot.define do
  factory :user do
    password { Faker::Internet.password }

    trait :student do
      mentor { false }
      email { Faker::Internet.email(domain: 'fe.up.pt') }
    end

    trait :mentor do
      mentor { true }
      email { Faker::Internet.email }
    end
  end
end

# test/models/user_test.rb
require 'test_helper'

class UserTest < ActiveSupport::TestCase
  test 'students with fe.up.pt email addresses are allowed' do
    assert build(:user, :student, email: 'student@fe.up.pt').valid?
    assert build(:user, :student, email: 'STUDENT@FE.UP.PT').valid?
  end

  test 'students without an fe.up.pt email address are not allowed' do
    assert_not build(:user, :student, email: 'student@example.org').valid?
  end

  test 'mentors without an fe.up.pt email address are allowed' do
    assert build(:user, :mentor, email: 'mentor@example.org').valid?
  end

  test 'confirm! confirms user' do
    user = create(:user, :student)

    user.confirm!

    assert user.confirmed?
    assert_not_nil user.confirmed_at
  end

  test 'two users with the same email address in different cases are not allowed' do
    user = create(:user, :student)

    assert_not build(:user, :student, email: user.email.upcase).valid?
  end

  test 'user creation includes registration_id' do
    user = create(:user, :student)

    assert_not_nil user.registration_id
  end
end
~~~~

## Adding user registration - Controller

Now that the model is done, I can add the four routes code. This is where most
of the action is happening. In a large application, I would probably bother
with having some of this code in an `app/services/` structure, but this is
simple enough that creating those will only cause more confusion when reading.

For now, I won't be sending the actual confirmation email.

~~~~ ruby
class RegistrationsController < ApplicationController
  def confirm
    registrations.find_by!(registration_id: params[:id]).confirm!

    redirect_to '/'
  rescue ActiveRecord::RecordNotFound
    render :not_found, status: :not_found
  end

  def create
    @user = registrations.create(create_params)

    if @user.valid?
      render status: :created
    else
      render :new, status: :bad_request
    end
  end

  def new
    @user = registrations.new
  end

  def show
    @user = registrations.find_by!(registration_id: params[:id])
  rescue ActiveRecord::RecordNotFound
    render :not_found, status: :not_found
  end

  private

  def registrations
    User.student.confirmation_pending
  end

  def create_params
    params.require(:user).permit(:email, :password)
  end
end
~~~~

The downsides of not creating a database table for registrations are showing
already. I'm using `User.student.confirmation_pending` everywhere, so I aliased
it to `registrations` to make the code a bit DRYer, but it returns a `User`
relation, so that might be a bit confusing. I also had to fight with form
building, particularly in `show.html.erb`, to make things work:

~~~~ erb
<h1>Confirm your account</h1>

<%= form_with url: confirm_registration_path(@user.registration_id), method: :post do |f| %>
  <%= f.submit %>
<% end %>
~~~~

If I had created the extra model, the `confirm` route would be a `PATCH`
instead, and the view would be a bit simpler:

~~~~ erb
<h1>Confirm your account</h1>

<%= form_with model: @registration, url: confirm_registration_path(@registration) do |f| %>
  <%= f.submit %>
<% end %>
~~~~

## Adding user registration - email setup

To send registration confirmations, I need an email provider. Recently, I've
used both [Sendgrid](https://sendgrid.com/pricing/) and [Amazon
SES](https://aws.amazon.com/ses/pricing/). Sendgrid has a free tier option,
while SES costs $0.10 per 1000 emails unless you're sending emails from an EC2
instance, in which case you have 62k free emails per month. They're both easy
to set up. Since I already have a personal AWS account, I'll go with that.

To use SES in rails, the easiest way is to use the [`aws-sdk-rails`
gem](https://github.com/aws/aws-sdk-rails) and configure rails action mailer to
use it:

~~~~ ruby
# Gemfile

gem 'aws-sdk-rails'

# config/initializers/mailer.rb

if Rails.env.test? == false
  Rails.application.config.action_mailer.delivery_method = :ses
end
~~~~

This gem needs an AWS access key to work, unless you're running this in an EC2
instance. I have an `~/.aws/credentials` file set up, but it has multiple
profiles without any defaults, so that I avoid using the wrong account. To
explicitly set the profile, I need to set the `AWS_PROFILE` environment
variable. The gem also needs to know which aws region it should use, so I'll
add these two variables to `.env.development.local`:

~~~~ env
AWS_PROFILE=hugopeixoto
AWS_REGION=eu-central-1
~~~~

The last SES setup step I need to do is to validate a few email addresses so
that I can send and receive emails while testing. To use this in production, I
will validate the sender domain, but for development, having a few validated
addresses is enough.

I'm setting things up in `eu-central-1`, so I need to go to the following URL
and verify some addresses:

<https://eu-central-1.console.aws.amazon.com/ses/home?region=eu-central-1#verified-senders-email>

I validated my two `@fe.up.pt` addresses and a `@gmail.com` one that I'll be
using as the sender.

The emails I'm going to send will have some links pointing back to the
application, so the mailer needs to be aware of which domain I'm using. I
configured this by adding a new environment variable:

~~~~ env
BASE_URL=http://localhost:3000
~~~~

And I used this variable in the mailer initializer:

~~~~ ruby
# config/initializers/mailer.rb

if Rails.env.test? == false
  Rails.application.config.action_mailer.delivery_method = :ses
end

Rails.application.config.action_mailer.default_url_options = { host: ENV.fetch("BASE_URL") }
~~~~

I also need to specify what address will be sending the emails, so I added
another environment variable, `EMAIL_SENDER_ADDRESS`, to
`.env.development.local`, and configured it globally in
`app/mailers/application_mailer.rb`:

~~~~ ruby
# frozen_string_literal: true

class ApplicationMailer < ActionMailer::Base
  default from: ->{ ENV.fetch("EMAIL_SENDER_ADDRESS") }
    layout 'mailer'
  end
end
~~~~

## Adding user registration - email sending

Now that everything's configured, I need a mailer. Mailers are similar to
controllers, where their actions represent messages.

~~~~
$ bin/rails generate mailer registrations
    create  app/mailers/registrations_mailer.rb
    invoke  erb
    create    app/views/registrations_mailer
    invoke  test_unit
    create    test/mailers/registrations_mailer_test.rb
    create    test/mailers/previews/registrations_mailer_preview.rb
~~~~

I could have created the message directly using `generate mailer registrations
confirmation`. It creates the action stub automatically, with two placeholder
templates (text and html). I'm going to override those (including the
filenames), so I skipped that. This is what my mailer looks like:


~~~~ ruby
class RegistrationsMailer < ApplicationMailer
  def confirmation
    @user = params[:user]
    @base_url = ENV.fetch("BASE_URL")
    @confirmation_url = registration_url(@user.registration_id)

    mail(to: @user.email, subject: default_i18n_subject)
  end
end
~~~~

I'm passing a `User` object directly via `params[:user]`.

Before, I used to serialize the `id` and fetching the model explicitly. I used
to do this because email sending is something that you usually don't do
synchronously, but instead goes through a queueing mechanism like
[Sidekiq](https://sidekiq.org/) or
[Shoryuken](https://github.com/phstc/shoryuken). When using a queue, you
probably don't want to serialize the full `User` object and send it over. It
may be stale by the time it is processed, you'll be potentially storing
sensitive information in the queue, and you'll have to deal with object
marshalling. Turns out my rails knowledge was super outdated, and `ActiveJob`
uses [`globalid`](https://github.com/rails/globalid), which serializes
`ActiveRecord` into URLs:

~~~~ irb
irb(main):002:0> User.first.to_global_id.to_s
=> "gid://mentorados/User/4c29d8db-11f3-400a-a4e7-59bbda8a71bf"
~~~~

This means that I no longer have to pass `id`s manually.


I'm also using `subject: default_i18n_subject` in the `#mail` call.
`default_i18n_subject` infers a translation key based on the mailer class and
the method name. In this case, it is
`registrations_mailer.confirmation.subject`. Using `default_i18n_subject` is
the default, so I could omit the `subject` parameter, but I want to be sure
that anyone looking at this knows what's going on.

Now I need to write the email body template. I want these to be translatable,
and I don't want to deal with creating arbitrary translation keys for each
paragraph (like `body_1`, `body_2`, etc) nor deal with interpolation
shenanigans. To avoid this, I will create a template per language, with the
locale in the filename. These are the contents of
`app/views/registrations_mailer/confirmation.en.text.erb`:

~~~~ erb
We're sending someone registered this email address in <%= @base_url %>.

Before proceeding, we need you to confirm your email address:

<%= @confirmation_url %>

If you need any help or run into any issues:

mentor@alumniei.pt
~~~~

The portuguese version goes in the file
`app/views/registrations_mailer/confirmation.pt.text.erb`.

Rendering a different template based on the locale is handled by `ActionView`,
so this works for mailer templates and controller templates.

Now that the mailer is done, I need to trigger the delivery of the email.
I'll change the registrations controller directly:

~~~~ ruby
# app/controllers/registrations_controller.rb
class RegistrationsController < ApplicationController
  def create
    User.transaction do
      @user = User.student.confirmation_pending.create(create_params)

      if @user.valid?
        RegistrationsMailer.with(user: @user).confirmation.deliver_now!

        render status: :created
      else
        render :new, status: :bad_request
      end
    end
  end
end
~~~~

This is a basic approach for a basic project. It is sending the email messages
synchronously, inside a database transaction. This is not the best approach,
but given the low volume we're expecting, it's good enough. The database
transaction is there to avoid creating a user record if the email message
sending fails.

In some projects, at this point I'd consider extracting the registration logic
into its own class / method / service. Something redundant, like
`app/services/registrations.rb` with a `Registrations::create` method. I'm not
having any of that in this project unless the controller gets really messy.

## Wrapping up

I have a base rails project with my personal tweaks.

I learned about `globalid`, and how it interacts with `ActiveJob` and
`ActionMailer`. This has been around since rails 4.2, which is probably a
lesson in refreshing your knowledge and questioning your assumptions from time
to time. The only reason I noticed that this was a thing was that I was reading
through [Action Mailer Basics
guide](https://guides.rubyonrails.org/action_mailer_basics.html) and noticed
that they're using `params[:user]` instead of `params[:id]`.

I learned a few new rails conventions for email translations: using
`default_i18n_subject` and adding the locale to the view filename.

I ran into a limitation when using database defaults and had to work around it
by adding a `after_create :reload` workaround. I usually have rails handle the
default value generation, and I guess this is a good reason to keep doing that.
Fixing this limitation may be a good candidate for a code contribution.

I'm using this application to experiment with a "back to basics" approach.
After many years of working with API only microservices and javascript
applications, relearning the basics of an html serving rails application feels
kind of new.
