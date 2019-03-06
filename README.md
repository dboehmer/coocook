# Links for German Perl Workshop 2019

| Component | Implementation in Coocook |
| --- | --- |
| `MySchema::Result::User->has_role()` | [`Coocook::Schema::Result::User`](lib/Coocook/Schema/Result/User.pm#L88) |
| `MySchema::Result::User->has_project_role()` | [`Coocook::Schema::Result::User`](lib/Coocook/Schema/Result/User.pm#L102) |
| `MyApp::ActionRole::RequiresCapability` | [`Coocook::ActionRole::RequiresCapability`](lib/Coocook/ActionRole/RequiresCapability.pm) |
| `MyApp->has_capability()` | [`Coocook::Helpers`](lib/Coocook/Helpers.pm#L56) |
| `MyApp::Controller` | [`Cooocook::Controller`](lib/Coocook/Controller.pm#L12) |
| `MyApp::Model::Authorization` | [`Coocook::Model::Authorization`](lib/Coocook/Model/Authorization.pm) <br> [`t/model_Authorization.t`](t/model_Authorization.t) |

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

Prerequisites:

* [Perl5](https://www.perl.org/get.html)
  with [`cpanm`](https://metacpan.org/pod/App::cpanminus#INSTALLATION)

* by default [SQLite](https://www.sqlite.org/)
  with [`DBD::SQLite`](https://metacpan.org/pod/DBD::SQLite)
  or some other RDBMS

With Ubuntu or Debian Linux:

    $ sudo apt-get install cpanminus libdbd-sqlite3-perl sqlite3

Get source code:

    $ git clone https://github.com/dboehmer/coocook.git

Install Perl5 dependencies:

    $ cd coocook/
    $ cpanm --installdeps .

Install database into a local SQLite file and start development server in development mode:

    $ script/coocook_deploy.pl install
    $ script/coocook_server.pl --debug
    ...
    HTTP::Server::PSGI: Accepting connections at http://0:3000/

## Mailing list

* <coocook@lists.coocook.org>
* subscribe at [lists.coocook.org/mailman/listinfo/coocook](https://lists.coocook.org/mailman/listinfo/coocook)
* or send e-mail with subject `subscribe` to
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

* Christina Sixtus

## Copyright and License

This software is copyright (c) 2015-2019 by Daniel Böhmer.
This web application is free software, licensed under the GNU Affero General Public License, Version 3, 19 November 2007.
