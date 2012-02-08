#!/usr/bin/env perl

use v5.10;
use strict;
use warnings FATAL => "all";
use Module::Load;
use Test::More;
use WWW::Parallels::Agent;
use constant Agent => "WWW::Parallels::Agent";

plan +( my $hostname = $ENV{PARALLELS_AGENT_HOSTNAME} )
	? ( tests => 6 )
	: ( skip_all => "Environment variable PARALLELS_AGENT_HOSTNAME not set." );

my $agent = Agent->new(
	xsd_version => 4,
	use_ssl     => 0,
	hostname    => $hostname );
isa_ok($agent, Agent);
can_ok($agent, qw(new _client _schema));

SKIP: {
	eval { load XML::Compile::Tester };
	skip "XML::Compile::Tester not insalled." if $@;
	XML::Compile::Tester->import;
	my $writer = writer_create(
		$agent->_schema,
		"vzl_writer",
		"{http://www.swsoft.com/webservices/vzl/4.0.0/system}login" );
	my $xml = writer_test( $writer, {
		name     => "root",
		realm    => "00000000-0000-0000-0000-000000000000",
		password => "mysecret123" } ); }
