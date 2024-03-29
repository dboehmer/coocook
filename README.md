# Coocook

[![build status](https://travis-ci.org/dboehmer/coocook.svg?branch=master)](https://travis-ci.org/dboehmer/coocook)
[![dishes served](https://coocook.org/badge/dishes_served.svg)](https://coocook.org/statistics)
[![license](https://img.shields.io/github/license/dboehmer/coocook.svg)](https://github.com/dboehmer/coocook/blob/master/LICENSE)

Web application for collecting recipes and making food plans

## Main features

* collect recipes
* create food plans
    * simply import dishes from your recipes
* gather purchase lists
    * convert units to summarize list items
* print views for whole project and each day
    * including ingredients, cooking instructions
* special features
    * define maximum shelf life or limit for need to preorder of articles
    * select some ingredients and part of cooking instructions to be done at an earlier meals

## Quick start

Get source code:

    $ git clone https://github.com/dboehmer/coocook.git
    $ cd coocook/

### Configure database

Copy the config template [`share/examples/dbic.yaml`](share/examples/dbic.yaml) to the working directory:

    $ cp share/examples/dbic.yaml dbic.yaml

A database from the YAML file other than `development` or a literal DSN can be configured in `coocook_local.yaml`.
For other possible settings see the default values defined in [`lib/Coocook.pm`](lib/Coocook.pm).

### Run with native Perl (works best on Unix-like Operating Systems)

Prerequisites:

* [Perl5](https://www.perl.org/get.html)
  with [`cpanm`](https://metacpan.org/pod/App::cpanminus#INSTALLATION)

* database

  * by default [SQLite](https://www.sqlite.org/)
    with [`DBD::SQLite`](https://metacpan.org/pod/DBD::SQLite)
  
  * or [PostgreSQL](https://www.postgresql.org/)
    with [`DBD::Pg`](https://metacpan.org/pod/DBD::Pg)

With Ubuntu or Debian Linux:

    $ sudo apt-get install cpanminus sqlite3

To install Perl distributions that include C code you’ll probably need a C toolchain and some libraries:

```console
$ sudo apt-get install build-essential
$ sudo apt-get install libssl-dev zlib1g-dev             # for Net::SSLeay
$ sudo apt-get install libexpat1-dev                     # for XML::Parser
$ sudo apt-get install libncurses-dev libreadline-dev    # for Term::ReadLine::Gnu for development mode
$ sudo apt-get install libsqlite3-dev                    # for DBD::SQLite
$ sudo apt-get install libpq-dev                         # for DBD::Pg
```

Install Perl5 dependencies required for running the application:

    $ cpanm --installdeps .

There are a few additional dependencies for *development* as well *recommended* and *suggested* dependencies. To install these as well run:

    $ cpanm --installdeps --with-develop --with-recommends --with-suggests .

Install database schema into configured database (see above) and start development server in debug mode:

    $ script/coocook_deploy.pl install
    $ script/coocook_server.pl --debug
    ...
    HTTP::Server::PSGI: Accepting connections at http://0:3000/

Hint: With the `--restart` option the development server restarts automatically when files in `lib/` are changed.
This requires [`Catalyst::Restarter`](https://metacpan.org/pod/Catalyst::Restarter).

### Run with Docker

Follow the instructions at [hub.docker.com/r/coocook/coocook-dev](https://hub.docker.com/r/coocook/coocook-dev) to use the Docker image for development.

## Mailing list

* <coocook@lists.coocook.org>
* subscribe at [lists.coocook.org/mailman/listinfo/coocook](https://lists.coocook.org/mailman/listinfo/coocook)
* or send an email with subject `subscribe` to
[coocook-request@lists.coocook.org](mailto:coocook-request@lists.coocook.org?subject=subscribe)

## Terminology

| Name | Description | Example |
| --- | --- | --- |
| Project | self-contained collection of Coocook data | Paris vacation |
| Meal | an occasion for food on a particular date | lunch at August 15th |
| Dish | an actual food planned for a certain meal | apple pie for lunch on August 15th |
| Recipe | a scalable template for a dish | apple pie |
| Ingredient | an amount of some article for a dish/recipe | 1kg of apples |
| Article | a single sort of food that can be purchased | apples |
| Unit | a type of measurement | kilograms
| Quantity | a collection of physical units that can be converted | masses

## Author

Daniel Böhmer <post@daniel-boehmer.de>

## Contributors

* [@ChristinaSi](https://github.com/ChristinaSi) Christina Sixtus
* [@moseschmiedel](https://github.com/moseschmiedel) Mose Schmiedel
* [@rico-hengst](https://github.com/rico-hengst) Rico Hengst

## Copyright and License

This software is copyright (c) 2015-2022 by Daniel Böhmer.
This web application is free software, licensed under the
[GNU Affero General Public License, Version 3, 19 November 2007](LICENSE).
