#!/usr/bin/perl
# -+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
# Giza::ObjView - An interface to view the catalog structure
# (c) 1996-2002 ABC Startsiden AS, see the file AUTHORS.
#
# See the file LICENSE in the Giza top source distribution tree for
# licensing information. If this file is not present you are *not*
# allowed to view, run, copy or change this software or it's sourcecode.
# -+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
#####

#%include <config.pimpx>

#%ifdef PREFIX
#%  define INCLUDE "%{PREFIX}/include"
#%endif

#%print use lib '%{INCLUDE}';

package Giza::ObjView;
use strict;
use Giza;
use Giza::User;
use Giza::Object;
use Class::Struct;
use Exporter;
use Carp;

my $DONT_RECURSE_REFS = 0;

# ----------------------------------------------------------------- #

struct(
	giza	=> '$', # the giza object
	db		=> '$', # the database object
	user	=> '$', # the giza user object.
);

sub fetch
{
	my($self, %match) = @_;
	my $db = $self->db;

	my($order, $limit);
	if($match{ORDER}) {
		$order = " ORDER BY $match{ORDER}";
		delete $match{ORDER};
	} else {
		$order = " ORDER BY sort,changed,created ASC";
	}

	if($match{LIMIT}) {
		$limit = " LIMIT $match{LIMIT}";
		delete $match{LIMIT};
	}

	my @ids = (); # Ids to fetch
	my $query = $db->build_select_q('catalog', %match);
	$query .= $order;
	$query .= $limit;

	my $sth = $db->query($query) or return FALSE;
	while(my $id = $db->fetchrow_hash($sth)) {
		push @ids, $id->{id};
	}
	$db->query_end($sth);

	my $ids = join(',', @ids);
	my $obj = new Giza::Object(giza=>$self->giza, db=>$db, user=>$self->user);
	$obj->dont_recurse_refs unless $self->recurse_refs;
	my $objects = $obj->fetch(Id => $ids);
	if(ref $objects eq 'ARRAY') {
		return $objects;
	} else {
		my @objects = ();
		push @objects, $objects;
		return \@objects;
	}
}

sub fetch_tree
{
	my($self, $parent) = @_;
	my $g  = $self->giza;
	my $db = $self->db;

	my @names;
	my $obj = new Giza::Object (giza=>$g, db=>$db, user=>$self->user);
	while($parent) {
	 	$obj = $obj->fetch(Id=>$parent);
		$parent = $obj->parent;
		# Object has itself as parent? Break out of loop.
		undef $parent if $obj->parent == $obj->id;
		push(@names, [$obj->id, $obj->name]);
	};
	undef $obj;
	return \@names;
}	

sub dont_recurse_refs
{
	$DONT_RECURSE_REFS = 1;
}

sub do_recurse_refs
{
	$DONT_RECURSE_REFS = 0;
}

sub recurse_refs
{
	return ($DONT_RECURSE_REFS ? undef : 1);
}


1
__END__
