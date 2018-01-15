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

* Perl5 with [`cpanm`](https://github.com/miyagawa/cpanminus)
* by default [SQLite](https://www.sqlite.org/)
  with [`DBD::SQLite`](https://metacpan.org/pod/DBD::SQLite)
  or some other RDBMS

Get source code:

    git clone https://github.com/dboehmer/coocook.git

Install dependencies:

    perl Makefile.PL
    cpanm --installdeps .

Install database into local SQLite and start development server:

    script/coocook_deploy.pl install
    script/coocook_server.pl

## Mailing list

* coocook@lists.coocook.org
* subscribe at http://lists.coocook.org/mailman/listinfo/coocook
* or send e-mail with subject `subscribe` to coocook-request@lists.coocook.org

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

This software is copyright (c) 2015-2018 by Daniel Böhmer.
This is free software, licensed under the GNU General Public License, Version 3, June 2007.
