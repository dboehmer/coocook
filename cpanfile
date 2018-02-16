requires "App::DH" => "0";
requires "Carp" => "0";
requires "Catalyst" => "0";
requires "Catalyst::Action::RenderView" => "0";
requires "Catalyst::ActionRole::RequireSSL" => "0";
requires "Catalyst::Authentication::Store::DBIx::Class" => "0";
requires "Catalyst::Controller" => "0";
requires "Catalyst::Model" => "0";
requires "Catalyst::Model::DBIC::Schema" => "0";
requires "Catalyst::Plugin::Authentication" => "0";
requires "Catalyst::Plugin::ConfigLoader" => "0";
requires "Catalyst::Plugin::Session::State::Cookie" => "0";
requires "Catalyst::Plugin::Session::Store::DBIC" => "0";
requires "Catalyst::Plugin::Session::Store::FastMmap" => "0";
requires "Catalyst::Plugin::Static::Simple" => "0";
requires "Catalyst::Runtime" => "5.80";
requires "Catalyst::View::Email::Template" => "0";
requires "Catalyst::View::TT" => "0";
requires "Config::General" => "0";
requires "Crypt::Argon2" => "0";
requires "DBIx::Class::Core" => "0";
requires "DBIx::Class::FilterColumn" => "0";
requires "DBIx::Class::Helpers" => "0";
requires "DBIx::Class::InflateColumn::DateTime" => "0";
requires "DBIx::Class::ResultSet" => "0";
requires "DBIx::Class::Schema::Config" => "0";
requires "Data::Validate::Email" => "0";
requires "DateTime" => "0";
requires "HTML::Entities" => "0";
requires "JSON::MaybeXS" => "0";
requires "MIME::Base64::URLSafe" => "0";
requires "Moose" => "0";
requires "Moose::Role" => "0";
requires "Moose::Util::TypeConstraints" => "0";
requires "MooseX::MarkAsMethods" => "0";
requires "MooseX::NonMoose" => "0";
requires "Net::SSLeay" => "0";
requires "Scalar::Util" => "0";
requires "Template::Plugin::Filter" => "0";
requires "Template::Plugin::Markdown" => "0";
requires "feature" => "0";
requires "lib" => "0";
requires "parent" => "0";
requires "perl" => "v5.16.0";
requires "strict" => "0";
requires "utf8" => "0";
requires "warnings" => "0";
suggests "Sys::Hostname::FQDN" => "0";

on 'test' => sub {
  requires "Catalyst::Test" => "0";
  requires "DBICx::TestDatabase" => "0";
  requires "DBIx::Class::Schema::Loader" => "0";
  requires "DateTime::Format::SQLite" => "0";
  requires "Email::Sender::Simple" => "0";
  requires "ExtUtils::MakeMaker" => "0";
  requires "File::Spec" => "0";
  requires "FindBin" => "0";
  requires "Test::Compile" => "0";
  requires "Test::Deep" => "0";
  requires "Test::Memory::Cycle" => "0";
  requires "Test::MockObject" => "0";
  requires "Test::More" => "0";
  requires "Test::Most" => "0";
  requires "Test::WWW::Mechanize::Catalyst" => "0";
};

on 'test' => sub {
  recommends "CPAN::Meta" => "2.120900";
};

on 'configure' => sub {
  requires "ExtUtils::MakeMaker::CPANfile" => "0";
};

on 'develop' => sub {
  recommends "Catalyst::Plugin::StackTrace" => "0";
  recommends "CatalystX::LeakChecker" => "0";
};
