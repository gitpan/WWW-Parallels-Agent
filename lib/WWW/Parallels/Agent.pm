package WWW::Parallels::Agent;

use v5.10;
use strict;
use warnings FATAL => "all";
use utf8;
use Carp;
use File::ShareDir qw(dist_dir);
use File::Spec::Functions qw(catdir catfile);
use Hash::FieldHash qw(fieldhash);
use IO::Socket;
use Params::Check "check";
use POSIX "floor";
use Socket qw(:addrinfo inet_aton SOCK_RAW);
use XML::Compile::Cache;
use WWW::Parallels::Agent::Response;

use constant {
	Document => "XML::LibXML::Document",
	Element  => "XML::LibXML::Element",
	Response => "WWW::Parallels::Agent::Response" };

use namespace::clean;

our $VERSION = 'v0.0.1'; # VERSION
# ABSTRACT: Client implementation of the Parallels Virtual Automation Agent API

fieldhash my %client => "_client";
fieldhash my %schema => "_schema";
my $schema = XML::Compile::Cache->new(
	allow_undeclared => 1,
	opts_rw          => {
		elements_qualified => 0,
		validation         => 1 } );
do {
	my $dist_dir  = dist_dir("WWW-Parallels-Agent");
	my $xsd_dir   = catdir $dist_dir, "v4";
	my @xsd_files = glob catfile $xsd_dir, "*.xsd";
	$schema->importDefinitions($_) for @xsd_files; };

sub new {
	my ( $class, %params ) = @_;

	# Check params:
	my %tmpl = (
		xsd_version => {
			required => 1,
			allow    => [4] }, # Only version supported for now
		use_ssl => {
			default => 1,
			allow   => [ 0, 1 ] },
		hostname => {
			required => 1,
			allow    => sub { $_[0] && inet_aton($_[0]) } } );
	check( \%tmpl, \%params, 1 ) or croak "Parameter check failed";

	# Resolve IP address for client attribute:
	my ($ip_error, $ip_address) = do {
		my ($error, @result) = getaddrinfo(
			$params{hostname}, "", { socktype => SOCK_RAW } );
		croak "Unable to resolve hostname: $error" if $error;
		map {
			getnameinfo(
				$_->{addr}, NI_NUMERICHOST, NIx_NOSERV ) } @result; };
	croak $ip_error if $ip_error;

	# Create self and client attribute:
	my $self = bless { }, $class;
	$schema{$self} = $schema; # Schema accessor exists only for unit tests
	say $ip_address;
	$client{$self} = $self->_client( IO::Socket::INET->new(
		PeerAddr => $ip_address,
		PeerPort => 4433,
		Proto    => "tcp",
		Timeout  => 10 ) or croak "Unable to connect to server" );

	return $self; }

no namespace::clean;

my $packet_id = 1;
my $doc       = Document->new("1.0", "UTF-8");
sub _write_packet {
	my ($self, $namespace, $function, %params) = @_;
	XML::Compile::Util->import(qw(pack_type));
	my $protocol_ns = $namespace =~ s/\w+$/protocol/rx;
	my $packet_type =  pack_type($protocol_ns, "packet");
	my $op_type = pack_type($namespace, $function);
	my ($short_ns) = $namespace =~ /(\w+)$/x;
	my $operator = Element->new($short_ns);

	$operator->addChild(
		%params
		? $self->_schema->writer($op_type)->($doc, \%params)
		: Element->new($function) );
	my $packet = $self->_schema->writer($packet_type)->(
		$doc, {
			id => $packet_id++,
			version => "4.0.0",
			data => { cho_operator => [ { $short_ns => $operator } ] } } );
	return $packet->toString; }

use namespace::clean;

# Generate API methods:

foreach my $namespace ( $schema->namespaces->list ) {
	my ($ns_short) = $namespace =~ /(\w+)$/x;
	no strict "refs";
	*{__PACKAGE__ . "::" . $ns_short} = sub {
		use strict "refs";
		my ($self, $function, %params) = @_;
		local $/ = "\0";
		my $operation = $self->_write_packet($namespace, $function, %params);
		$operation =~ s/(\w+?>.+?==)\n/$1/gx;
		say $operation;
		$self->_client->print($operation . "\0");
		say $self->_client->readline; } }
#		return Response->new(
#			$client->reader($namespace)->( $self->_client->readline ) ); } }

1;
