#!/usr/bin/perl

#%include <config.pimpx>

#%ifdef PREFIX
#%  define INCLUDE "%{PREFIX}/include"
#%endif

#%print use lib '%{INCLUDE}';


package Giza::Search::OpenFTS;
use strict;
use Giza;
use Search::OpenFTS;
use Search::OpenFTS::Index;
use vars qw($PREFIX %opts);


$PREFIX = 'obj';

sub new
{
	my($pkg, %argv) = @_;
	$pkg = ref $pkg || $pkg;
	my $self = bless {}, $pkg;
	$self->giza($argv{giza}) if $argv{giza};
	$self->user($argv{user}) if $argv{user};
	$self->db($argv{db}) if $argv{db};
	%opts = (
		dbi				=> $self->db->dbh,
		txttid			=> 'catalog.id',
		use_index_table => 1,
		use_index_array	=> 'fts_index',
		numbergroup		=> 10,
		dict => [
			#%ifdef OPENFTS_STEMMER
			#%print '%{OPENFTS_STEMMER}'
			#%else
			'Search::OpenFTS::Dict::PorterEng'
			#%endif
		]
	);
	return $self;
}

sub giza
{
	my($self, $giza) = @_;
	if(ref $giza) {
		$self->{_GIZA} = $giza;
	}
	return $self->{_GIZA};
}

sub user
{
	my($self, $user) = @_;
	if(ref $user) {
		$self->{_USER} = $user;
	}
	return $self->{_USER};
}

sub db
{
	my($self, $db) = @_;
	if(ref $db) {
		$self->{_DB} = $db;
	}
	return $self->{_DB};
}
	

sub update
{
	my($self, $obj) = @_;
	print STDERR "UPDATE INDEX FOR ". $obj->id. "\n";
	$self->delete($obj);
	$self->index($obj);
}

sub delete
{
	my($self, $obj) = @_;
	my $idx = Search::OpenFTS::Index->new($self->db->dbh)
		or $self->giza->error("Couldn't create index object: $!")
		and return undef;
	return $idx->delete($obj->id);
}
		

sub index
{
	my($self, $obj) = @_;
	my $idx = Search::OpenFTS::Index->new($self->db->dbh)
		or $self->giza->error("Couldn't create index object: $!")
		and return undef;
	$idx->index($obj->id, sprintf("%s\t%s\t%s\t%s", 
		delsep($obj->name),
		delsep($obj->keywords),
		delsep($obj->description),
		delsep($obj->data)
	));
}

sub search
{
	my($self, $object, $pattern) = @_;
	my $s = Search::OpenFTS->new($self->db->dbh)
		or $self->giza->error("Couldn't create search object: $!")
		and return undef;
	my $result = $s->search($pattern);
	if($result) {
		my $ids = join(",", @$result);
		my $objects = $object->fetch(Id => $ids);
		if(ref $objects eq 'ARRAY') {
			return $objects;
		} else {
			return [$objects];
		}
	} else {
		return [];
	}
}

	
sub init
{
	my($self) = @_;
	$self->db->exec_query(qq{
		ALTER TABLE catalog ADD fts_index INT[];
	});
	my $idx = Search::OpenFTS::Index->init(%opts);
	return TRUE if $idx;
}

sub clear
{
	my($self) = @_;
	foreach(1..10) {
		$self->db->exec_query("DELETE FROM index$_");
	}
}

sub delsep
{
	my($var) = @_;
	$var =~ tr/\t/ /;
	return $var;
}
	
