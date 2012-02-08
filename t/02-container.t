#!/usr/bin/env perl

use v5.10;
use strict;
use warnings FATAL => "all";
use Test::More;
use Module::Load;
use WWW::Parallels::Agent;
use constant Agent => "WWW::Parallels::Agent";

plan +( my $hostname = $ENV{PARALLELS_AGENT_HOSTNAME} )
	? ( tests => 18 )
	: ( skip_all => "Environment variable PARALLELS_AGENT_HOSTNAME not set." );

my $agent = Agent->new(
	xsd_version => 4,
	use_ssl     => 0,
	hostname    => $hostname );
isa_ok($agent, Agent);
can_ok($agent, qw(envm));

SKIP: {
	eval { load XML::Compile::Tester };
	skip "XML::Compile::Tester not installed." if $@;
	XML::Compile::Tester->import;
	my @operations = (
		{ create  => { config => { } } },
		{ suspend => { eid => "..." } },
		{ resume  => { eid => "..."  } },
		{ destroy => { eid => "..." } } );
	foreach (@operations) {
		my ($function, $params) = %{$_};
		my $writer = writer_create(
			$agent->_schema,
			"env-$function writer",
			"{http://www.swsoft.com/webservices/vzl/4.0.0/envm}$function" );
		writer_test($writer, $params); } }
