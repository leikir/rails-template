# leikir/rails-template

## Requirements

This template currently works with:

* Rails 6.0.x
* PostgreSQL
* Yarn

## Usage

This template assumes you will store your project in a remote git repository (e.g. Bitbucket or GitHub) and that you will deploy to a production environment. It will prompt you for this information in order to pre-configure your app, so be ready to provide:

1. The git URL of your (freshly created and empty) Bitbucket/GitHub repository
2. The hostname of your production server

To generate a Rails application using this template, pass the `-m` option to `rails new`, like this:

# For a standalone Rails app
```
rails new blog \
  -d postgresql \
  --skip-webpack-install \
  -m https://raw.githubusercontent.com/leikir/rails-template/master/template.rb
```

# For a Rails API (with/without React)
```
rails new blog \
  -d postgresql \
  --api \
  -m https://raw.githubusercontent.com/leikir/rails-template/master/template.rb
```

*Remember that options must go after the name of the application.* The only database supported by this template is `postgresql`.

## What does it do?

The template will perform the following steps:

1. Generate your application files and directories
2. Ensure bundler is installed
3. Create the development and test databases
4. Install a bunch of extensions

## What is included?

#### These gems are added to the standard Rails stack

* Core
    * [sidekiq][] – Redis-based job queue implementation for Active Job
    * [Rollbar][] – Error monitoring
* Utilities
    * [annotate][] – auto-generates schema documentation
    * [awesome_print][] – try `ap` instead of `puts`
    * [better_errors][] – useful error pages with interactive stack traces
    * [rubocop][] – enforces Ruby code style
* Security
    * [brakeman][] and [bundler-audit][] – detect security vulnerabilities
* Testing
    * [simplecov][] – code coverage reports
    * [rspec][] – Framework for tests

## How does it work?

This project works by hooking into the standard Rails [application templates][] system, with some caveats. The entry point is the [template.rb][] file in the root of this repository.

Normally, Rails only allows a single file to be specified as an application template (i.e. using the `-m <URL>` option). To work around this limitation, the first step this template performs is a `git clone` of the `mattbrictson/rails-template` repository to a local temporary directory.

This temporary directory is then added to the `source_paths` of the Rails generator system, allowing all of its ERb templates and files to be referenced when the application template script is evaluated.

Rails generators are very lightly documented; what you’ll find is that most of the heavy lifting is done by [Thor][]. The most common methods used by this template are Thor’s `copy_file`, `template`, and `gsub_file`. You can dig into the well-organized and well-documented [Thor source code][thor] to learn more.

[active_type]:https://github.com/makandra/active_type
[sidekiq]:http://sidekiq.org
[dotenv]:https://github.com/bkeepers/dotenv
[annotate]:https://github.com/ctran/annotate_models
[autoprefixer-rails]:https://github.com/ai/autoprefixer-rails
[awesome_print]:https://github.com/michaeldv/awesome_print
[better_errors]:https://github.com/charliesome/better_errors
[guard]:https://github.com/guard/guard
[livereload]:https://github.com/guard/guard-livereload
[rubocop]:https://github.com/bbatsov/rubocop
[xray-rails]:https://github.com/brentd/xray-rails
[Postmark]:http://postmarkapp.com
[postmark-rails]:http://www.rubydoc.info/gems/postmark-rails/0.12.0
[brakeman]:https://github.com/presidentbeef/brakeman
[bundler-audit]:https://github.com/rubysec/bundler-audit
[shoulda]:https://github.com/thoughtbot/shoulda
[simplecov]:https://github.com/colszowka/simplecov
[Bootstrap]:http://getbootstrap.com
[application templates]:http://guides.rubyonrails.org/generators.html#application-templates
[template.rb]: template.rb
[thor]: https://github.com/erikhuda/thor
