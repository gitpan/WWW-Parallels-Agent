
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  "build_requires" => {
    "File::Find" => 0,
    "File::Temp" => 0,
    "Module::Build" => "0.3601",
    "Test::More" => 0,
    "Test::Requires" => 0
  },
  "configure_requires" => {
    "Module::Build" => "0.3601"
  },
  "dist_abstract" => "Client implementation of the Parallels Virtual Automation Agent API",
  "dist_author" => [
    "Richard Sim\303\265es <rsimoes AT cpan DOT org>"
  ],
  "dist_name" => "WWW-Parallels-Agent",
  "dist_version" => "v0.0.3",
  "license" => "lgpl",
  "module_name" => "WWW::Parallels::Agent",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "File::ShareDir" => 0,
    "Hash::FieldHash" => 0,
    "IO::Socket::INET" => 0,
    "Socket" => "1.97",
    "XML::Compile::Cache" => 0,
    "namespace::clean" => 0,
    "perl" => "v5.10"
  },
  "script_files" => [],
  "share_dir" => {
    "dist" => "xsd"
  }
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
