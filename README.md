# Coocook [![Build Status](https://travis-ci.org/dboehmer/coocook.svg?branch=master)](https://travis-ci.org/dboehmer/coocook)

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

* Perl5
* SQLite by default

Get source code:

    git clone https://github.com/dboehmer/coocook.git

Install dependencies:

    perl Makefile.PL
    make installdeps

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

## Copyright and License

This software is copyright (c) 2016,2017 by Daniel Böhmer.  No
license is granted to other entities.
