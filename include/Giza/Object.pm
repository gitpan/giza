#!/usr/bin/perl
# -+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
# Giza::Object - An interface to the the catalog database table.
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

package Giza::Object;
use strict;
use Giza;
use Giza::User;
use Giza::Component;
use Class::Struct;
use Data::RefQueue;
use Exporter;
use Carp;
use vars qw(%objstruct %object_cache);

my $USE_CACHE = 1;
my $DONT_RECURSE_REFS = 0;

# ----------------------------------------------------------------- #

# ###
# This will make all our accessors and methods for setting
# their values. See perldoc Class::Struct
struct(
	giza		=> '$', # Giza object.
	db			=> '$', # Giza::DB Object.
	user		=> '$', # Giza::User object.

	id			=> '$', # object id.
	parent		=> '$',	# parent object.
	active		=> '$',	# show on page?.
	created		=> '$', # timestamp.
	changed		=> '$', # timestamp.
	owner		=> '$', # user id.
	groupo		=> '$', # group id.
	revised_by	=> '$', # user id.
	"sort"		=> '$', # sort priority.
	mode		=> '$',	# object permissions
	refs_to_us	=> '$',	# number of references to us.
	template	=> '$',	# template (path).
	type		=> '$',	# object type.
	name		=> '$',	# object name.
	description	=> '$', # object description.
	keywords	=> '$', # object keywords.
	data		=> '$', # object data.
);

# ###
# This will be used in most of our queries to the DB.
# This also defines the layout of the database,
# remember to keep in sync with the struct call above.
# 
# The value is the formatting option. See perldoc -f printf
# for more info on formatting.
%objstruct = (
	id			=> 	qw{%d},
	parent		=>	qw{%d},
	active		=>	qw{%d},
	created		=>	qw{'%s'},
	changed		=>	qw{'%s'},
	owner		=>	qw{%d},
	groupo		=>	qw{%d},
	revised_by	=>	qw{%d},
	"sort"		=>	qw{%d},
	mode		=>	qw{'%s'},
	refs_to_us	=>	qw{%d},
	template	=>	qw{'%s'},
	type		=>	qw{'%s'},
	name		=>	qw{'%s'},
	description	=>	qw{'%s'},
	data		=>	qw{'%s'}
);
	
		
# ### TODO: this is not implemented yet.
sub check_obj_privs
{
	my($self, $object_id, $action) = @_;
	return TRUE;
}

sub set_defaults
{
	my($o)		= @_;
	my $g		= $o->giza;
	my $db		= $o->db;
	my $config	= $g->config;

	if(defined $config->{objects}{inherit} && defined $o->parent) {
		# ### Fetch default values from the object's parent.
		my $query = sprintf(qq{
				SELECT active, owner, groupo, sort, mode, template
				FROM catalog WHERE id=%d
			},
			$o->parent
		);
		my $sth = $db->query($query)
			or $g->error("Couldn't fetch parent: $DBI::errstr")
			or return FALSE;
		my $values = $db->fetchrow_array($sth)
			or $g->error("Couldn't fetch parent")
			and return FALSE;
		$db->query_end($sth);

		$o->active($values->[0]);
		$o->owner($values->[1]);
		$o->groupo($values->[2]);
		$o->sort($values->[3]);
		$o->mode($values->[4]);
		$o->template($values->[7]);
	}
	else {
		$o->parent($config->{defaults}{parent});
		$o->active($config->{defaults}{active});
		$o->owner($config->{defaults}{owner});
		$o->groupo($config->{defaults}{groupo});
		$o->sort($config->{defaults}{"sort"});
		$o->mode($config->{defaults}{mode});
		$o->template($config->{defaults}{template});
	}
	return TRUE;
}

sub get_next_place {
	my($arrayref) = @_;
	for(my $qno = 0; $qno <= $#$arrayref; $qno++) {
		return $qno unless ref $arrayref->[$qno];
	}
	return $#$arrayref + 1;
}

sub fetch {
	my($o, %match) = @_;
	my $g  = $o->giza;
	my $u  = $o->user;
	my $db = $o->db;
	my $cf = $g->config;

	#%ifdef DEBUG
	confess "need to be logged in before you can fetch objects. pass me a user object"
		unless ref $u;
	#%endif

	# Ofcourse we need an ID to fetch.	
	unless(defined $match{Id}) {
		if($o->id) {
			$match{Id} = $o->id;
		} else {
			$g->error("Missing the object id to fetch.");
			return FALSE;
		}
	}

	my $refq = new Data::RefQueue (split /\s*,\s*/, $match{Id});

	foreach my $id (@{$refq->not_filled}) {
		my $new_o = cache_restore_memshare($id);
		if($new_o) {
			$refq->save($new_o);
		} else {
			$refq->next;
		}
	}
	$refq->reset;
	$match{Id} = join(',', @{$refq->not_filled});			
	
	if($match{Id}) {
		my $query = $db->build_select_q('catalog', %match);
		my $sth = $db->query($query)
			or return FALSE;
		while(my $result = $db->fetchrow_hash($sth)) {
			if($result->{type} eq 'reference' and $o->recurse_refs) {
				unless(defined $result->{data} or $result->{data} =~ /^\d+$/) {
					$g->error("A referents data field must be an id to another object");
					return FALSE;
				}
				$result = $o->rec_get_refs($result->{data}, $result->{name}, 0)
					or return FALSE;
			}
			my $new_o = new Giza::Object(giza=>$g, db=>$db, user=>$u);
			# store the values in the object.
			$new_o->id(		$result->{id});
			$new_o->sort(   $result->{sort});
			$new_o->type(	$result->{type});
			$new_o->name(	$result->{name});
			$new_o->data(	$result->{data});
			$new_o->owner(  $result->{owner});
			$new_o->parent( $result->{parent});
			$new_o->active( $result->{active});
			$new_o->groupo( $result->{groupo});
			$new_o->created($result->{created});
			$new_o->changed($result->{changed});
			$new_o->mode($result->{mode});
			$new_o->template($result->{template});
			$new_o->revised_by($result->{revised_by});
			$new_o->refs_to_us($result->{refs_to_us});
			$new_o->description($result->{description});
			$refq->save($new_o);
			cache_save_memshare($result->{id}, $new_o);
		}
		$db->query_end($sth);
	}

	$refq->cleanse;
	my $objects = $refq->queue;

	if(scalar @$objects == 1) {
		return $objects->[0];
	} else {
		return $objects;
	}
}

sub rec_get_refs
{
	my($self, $id, $name, $iterations) = @_;
	my $g  = $self->giza;
	my $u  = $self->user;
	my $db = $self->db;
	my $result = {};
	if($iterations >= MAX_REFERENCE_REC_DEPTH) {
		$g->error("Max references recursions depth hit.");
		return FALSE;
	}
	do {
		my $sth	= $db->query("SELECT * FROM catalog WHERE id=$id")
			or return FALSE;
		$result	= $db->fetchrow_hash($sth);
		$db->query_end($sth);

		unless($result->{id}) {
			$g->error("A reference pointed to a non-existing object");
			return FALSE;
		}

		unless($u->access($result->{id}, R_OK)) {
			$g->error("Permission denied to reference path: $result->{id}");
			return FALSE;
		}
	
		if($result->{type} eq 'reference') {
			unless(defined $result->{data} or $result->{data} =~ /^\d+$/) {
				$g->error(qq{
					A broken reference was found while following a reference to 
					another reference.
				});
				return FALSE;
			}
			$result = $self->rec_get_refs($result->{data}, $name, $iterations++)
				or return FALSE;
		}	
	} until($result->{type} ne 'reference');

	$result->{name} = $name;

	if($result->{type} eq 'catalog') {
		if(exists $g->config->{objects}->{add_at_on_dir_refs}) {
			$result->{name} .= '@' ;
		}
	}

	return $result;
}

sub save
{
	my($o) 	= @_;
	my $g 	= $o->giza;
	my $u	= $o->user;
	my $db	= $o->db;

	#%ifdef DEBUG
	confess "not a giza object $g" unless ref $g;
	#%endif

	# ### These fields are required.
	unless($o->name) {
		unless($o->type eq 'reference') {
			$g->error("Missing one or more required fields: name, description");
			return FALSE;
		}
	}

	# ### fetch and save timestamps.
	$o->created($db->current_timestamp) unless defined $o->created;
	$o->changed($db->current_timestamp);
	
	# Build the query.	
	my $query = undef;
	if($o->id) {
		return FALSE unless $u->access($o->id, W_OK);
		$query = $db->build_update_query($o, 'catalog', %objstruct);
	} else {
		# check access to parent object.
		return FALSE unless $u->access($o->parent, W_OK);
		# We don't have any id, so we're making a new object.
		# get the next available id from the catalog table.
		$o->id($db->fetch_next_id('catalog'));
		$query = $db->build_insert_query($o, 'catalog', %objstruct);
	}

	if($o->parent == $o->id) {
		$g->error("Object parent cannot be itself.");
		return FALSE;
	}

	if($o->type eq 'reference') {
		unless($o->data && $o->data =~ /^\d+$/) {
			$g->error("Data field in a reference must be another objects id.");
			return FALSE;
		}
		$db->inc_refs_to($o->data);
	}

	# run the query (save the object)
	my $sth = $db->query($query)
		or $g->error("Couldn't save a new giza object: $DBI::errstr")
		and return FALSE;
	$db->query_end($sth);

	return $o->id; # yiiiha:)
}

sub delete
{
	my($self, $oid) = @_;
	my $g = $self->giza;
	my $db = $self->db;
	
	my $query = qq{
		DELETE FROM catalog WHERE id=$oid
	};

	$db->exec_query($query) or return FALSE;
	return TRUE;
}

sub cache_save_memshare
{
	my($oid, $oref) = @_;
	{
		lock(%object_cache);
		$object_cache{$oid} = $oref;
	}
}

sub cache_restore_memshare
{
	my($oid) = @_;
	return undef unless $object_cache{$oid};
	{
		lock(%object_cache);
		return $object_cache{$oid};
	}
}

sub no_cache
{
	$USE_CACHE = 0;
}

sub use_cache
{
	$USE_CACHE = 1;
}

sub do_cache
{
	return TRUE
		if $USE_CACHE;
}

sub do_recurse_refs 
{
	$DONT_RECURSE_REFS = 0;
}

sub dont_recurse_refs
{
	$DONT_RECURSE_REFS = 1;
}

sub recurse_refs {
	return ($DONT_RECURSE_REFS ? undef : 1);
}

1
__END__
