#!/usr/bin/perl
# -+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
# Giza::DB - The Giza database interface
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

package Giza::DB;
# ------------------------------------------------------------------ #
use strict;
use Giza;
use Carp;
use DBI;
use vars qw(%dsn);

# Constructor
# ------------------------------------------------------------------ #

# ### Giza::DB new(Giza giza)
# Create a new Giza::DB object. Takes the parent Giza object as argument.
# Also creates the list of DSN's to the database from the Giza configuration.
#
sub new
{
	my($self, $giza) = @_;
	my $obj = {};
	bless $obj, 'Giza::DB';
	$obj->giza($giza);
	$obj->init_dsn();
	return $obj;
}

# Methods
# ------------------------------------------------------------------ #

# ### Giza giza(Giza::DB db, Giza giza)
# Set or get the giza object reference.
#
sub giza
{
	my($self, $giza) = @_;
	if(defined $giza) {
		$self->{GIZA} = $giza;
	}
	return $self->{GIZA};
}

sub connected
{
	my($self, $connected) = @_;
	if($connected == 0) {
		$self->{CONNECTED} = 0;
	}
	if($connected == 1) {
		$self->{CONNECTED} = 1;
	}
	return $self->{CONNECTED};
}
		

# ### DBI::dbh dbh(Giza::DB db, DBI::dbh dbh)
# Set or get the current database handler.
# Usually set by Giza::DB::connect();
#
sub dbh
{
	my($self, $dbh) = @_;
	if(defined $dbh) {
		$self->{DBH} = $dbh;
	}
	return $self->{DBH};
}

# ### void init_dsn(Giza::DB db)
# Initialize the database connection strings from the Giza config.
# Usually done when createing a new Giza::DB object with Giza::DB::new()
sub init_dsn
{
	my($self) = @_;
	my $c = $self->giza->config;

	%Giza::DB::dsn = (
		postgres	=> "dbi:Pg:dbname=$c->{database}{db}",
		mysql		=> "dbi:mSQL:database=$c->{database}{db}:host=$c->{database}{host}",
		db2			=> "dbi:DB2:$c->{database}{db}",
		msql		=> "dbi:mSQL:database=$c->{database}{type}:host=$c->{database}{host}",
	);
}

# ### int connect(Giza::DB db)
# Connect to the database defined in the Giza config.
# Sets the Giza::DB::{dbh} as a reference to the database driver handle.
#
# It is not doing a persistent connect here, for that use Apache::DBI.
#
sub connect
{
	my($self) = @_;
	my $g = $self->giza();
	my $config = $g->config();
	my $dsn = undef;

	# ### We _need_ a DSN!
	unless(defined $dsn{$config->{database}{type}}) {
		$g->error("Unknown database type: $config->{database}{type}");
		return undef;
	}

	# ok... try to connect to the database with DBI...	
	my $dbh = DBI->connect(	$dsn{$config->{database}{type}},
							$config->{database}{username},
							$config->{database}{password},
							{
								RaiseError => 0,
								PrintError => 1
							}
	) 	or $g->error("Couldn't connect to database: $DBI::errstr")
		and return FALSE;

	# ###
	# XXX: 	should always check the return value of this function,
	# 		so you don't continue without a database handle :-)
	$self->dbh($dbh);
	$self->connected(1);
	return TRUE;
}

# ### int disconnect(Giza::DB db)
# Disconnect the session in the current database driver handle.
#
sub disconnect
{
	my($self) = @_;
	$self->connected(0);
	return $self->dbh->disconnect();
}

# ### DBI::sth query(Giza::DB db, string query)
# Execute a SQL query and return the query handler.
# 
# XXX: Remember to use $db->query_end($sth) when finished using
# the sth.
#
sub query
{
	my($self, $query) = @_;
	my $g = $self->giza;
	my $dbh = $self->dbh;

	#%ifdef DEBUG
	defined $query or $g->error("Missing query") and return FALSE;
	print STDERR ("$query\n");
	#%endif

	my $sth = $dbh->prepare($query)
		or $g->error("Couldn't prepare query $query: $DBI::errstr")
		and return FALSE;

	$sth->execute()
		or $g->error("Couldn't execute query $query: $DBI::errstr")
		and return FALSE;

	return $sth;
}

# ### int query_end(Giza::DB db, DBI::sth sth)
# End a query started by Giza::DB::query.
# XXX: Always remember to end a query "session"!
#
sub query_end
{
	my($self, $sth) = @_;
	return undef unless $sth;
	return $sth->finish();
}

# ### arrayref fetchrow_array(Giza::DB db, DBI::sth sth)
# Get fetchrow_arrayref on the current sth.
#
sub fetchrow_array
{
	my($self, $sth) = @_;
	#%ifdef DEBUG
	confess "did not get query handler: $sth" unless $sth;
	#%endif
	return $sth->fetchrow_arrayref();
}

sub fetchonerow_array
{
	my($self, $query) = @_;
	my $sth = $self->query($query) or return FALSE;
	my $ret = $self->fetchrow_array($sth);
	$self->query_end($sth) if defined $sth;
	return $ret;
}

# ### hashref fetchrow_hash(Giza::DB db, DBI::sth sth)
# Get fetchrow_hashref on the current sth.
#
sub fetchrow_hash
{
	my($self, $sth) = @_;
	return $sth->fetchrow_hashref();
}

sub fetchonerow_hash
{
	my($self, $query) = @_;
	#%ifdef DEBUG
	my($package, $filename, $line) = caller();
	print(STDERR "fetchrow_onehash: $package: $filename: $line: $query\n");
	#%endif
	my $sth = $self->query($query) or return FALSE;
	my $ret = $self->fetchrow_hash($sth);
	$self->query_end($sth);
	return $ret;
}

# ### string fetch_singlevar(Giza::DB db, string query)
# Return the first element from a query.
# 
sub fetch_singlevar
{
	my($self, $query) = @_;
	my $sth = $self->query($query) or return FALSE;
	my $result = $self->fetchrow_array($sth);
	$self->query_end($sth);
	return $result->[0];
}

# ### void string exec_query(Giza::DB db, string query)
# Just execute a query, don't fetch anything.
# This function returns nothing.
#
sub exec_query
{
	my($self, $query) = @_;
	my $sth = $self->query($query);
	$self->query_end($sth);
	return undef;
}

# ### sql_timestamp current_timestamp(Giza::DB db)
# Get the CURRENT_TIMESTAMP from the database.
#
sub current_timestamp
{
	my($self) = @_;
	return $self->fetch_singlevar('SELECT CURRENT_TIMESTAMP');
};

# ### int fetch_next_id(Giza::DB db, string table)
# Return the next availible id from a table.
# XXX: Always uses 'id' as the attribute for the id.
#
sub fetch_next_id
{
	my($self, $table) = @_;
	
	#%ifdef SQL_SEQUENCES
	#%print return $self->fetch_singlevar("SELECT nextval('${table}_seq')");
	#%else
	return $self->fetch_singlevar("SELECT MAX(id) + 1 FROM $table");
	#%endif
}


sub build_insert_query
{
	my($self, $o, $table, %objstruct) = @_;
	my $count = 0; # current attribute 
	my $no_elements = scalar keys %objstruct;
	my $query  = "INSERT INTO $table(". join(', ', sort keys %objstruct);
	$query .= ')VALUES(';
	my $count = 0; # current attribute
	foreach my $attribute (sort keys %objstruct) {
		my $keyvalue = undef;
		eval "\$keyvalue = sqlescape(\$o->$attribute);";
		$query .= sprintf("$objstruct{$attribute}", $keyvalue);
		$query .= ', ' unless ++$count >= $no_elements;
	}
	$query .= ")\n";
	return $query;
}

sub build_update_query
{
	my($self, $o, $table, %objstruct) = @_;
	my $count = 0; # current attribute 
	my $no_elements = scalar keys %objstruct;
	my $query = "UPDATE $table SET ";
	while(my($attribute, $type) = each %objstruct) {
		$count++;
		next if $attribute eq 'id';
		my $keyvalue = undef;
		eval "\$keyvalue = \$o->$attribute();";
		my $pat = "$attribute=$type";
		$query .= sprintf($pat, $keyvalue);
		$query .= ', ' unless $count >= $no_elements;
	}
	$query .= sprintf(" WHERE id=%d", $o->id);
	print STDERR "$query\n";
	return $query;
}

# ### id parent_by_expr(Giza::DB db, string expression)
# Find the last id of the objects given in an expression.
# See comments in function.
#
sub parent_by_expr
{
	my($self, $expr) = @_;
	my $g = $self->giza;

	# ###
	# The expression syntax goes like this: attribute:element_to_find
	# This means you can fetch the last id by traversing their parents
	# in a way like this:
	#
	# name:Frontpage:News::Newspaper::United Kingdom::The Sun
	# 
	# And it will traverse the tree finding the id for that element.
	# When using the attribute id: it will just return the id given.
	#
	my($attribute, $find) = split(/:/, $expr, 2);

	# ### hmmm.. what should we do with this attribute?
	if($attribute eq 'id') {
		return $find;
	}
	elsif($attribute eq 'name') {
		my @parents = split('::', $find);
		
		# get the first parent;
		my $first_parent_name = shift @parents;
		my $parent = $self->fetch_singlevar("SELECT id FROM catalog WHERE name='$first_parent_name'");
		return $parent unless @parents; # if we only got one.
	
		foreach	my $name (@parents) {
			$parent = $self->fetch_singlevar("SELECT id FROM catalog WHERE name='$name' AND parent='$parent'");
		}

		unless($parent) {
			$g->error("Couldn't fetch parent for pattern $expr");
			return FALSE;
		}

		return $parent;
	}
}

sub id_by_expr
{
	my($self, $expr) = @_;
	my $g = $self->giza;
	my($attribute, $find) = split(/:/, $expr, 2);
	if($attribute eq 'id') {
		return $find;
	}
	elsif($attribute eq 'name') {
		my @parents = split('::', $find);
		
		# get the first parent;
		my $first_parent_name = shift @parents;
		my $parent = $self->fetch_singlevar("SELECT id FROM catalog WHERE name='$first_parent_name'");
		return $parent unless @parents; # if we only got one.
	
		foreach	my $name (@parents) {
			$parent = $self->fetch_singlevar("SELECT id FROM catalog WHERE name='$name' AND parent='$parent'");
		}

		unless($parent) {
			$g->error("Couldn't find parent for pattern $expr");
			return FALSE;
		}

		return $parent;
	}
}

sub expr_by_id
{
	my($self, $oid) = @_;
	my $g 		= $self->giza;
	my @expr 	= ();

	return undef unless $oid;

	my $user = new Giza::User (giza=>$g, db=>$self);
	my $obj  = new Giza::Object (giza=>$g, db=>$self, user=>$user);
	while(TRUE) {
		$obj = $obj->fetch(Id => $oid) or last;
		$oid = $obj->parent;
		next unless $obj->type eq 'catalog';
		push @expr, $obj->name;
		last unless $obj->parent;
	};
	return join("::", reverse @expr);
}

# ### void inc_refs_to(Giza::DB db, int object_id)
# Increase the number of references pointing to a object by 1.
#
sub inc_refs_to
{
	my($self, $oid) = @_;
	my $query = qq{
		UPDATE catalog SET refs_to_us=(
			SELECT refs_to_us FROM catalog WHERE id=$oid
		)+1 WHERE id=$oid;
	};
	$self->exec_query($query);
	return TRUE;
}

# ### void doc_refs_to(Giza::DB db, int object_id)
# Decrease the number of references pointing to a object by 1.
#
sub dec_refs_to
{
	my($self, $oid) = @_;
	my $query = qq{
		UPDATE catalog SET refs_to_us=(
			SELECT refs_to_us FROM catalog WHERE id=$oid
		)-1 WHERE id=$oid;
	};
	$self->exec_query($query);
}

sub build_select_q {
	my($self, $table, %match) = @_;

	my $query = "SELECT * FROM $table";
	if(%match) {
		$query .= ' WHERE ';
		my $num_pats = scalar keys %match;
		my $count = 1;
		while(my($attribute, $pat) = each %match) {
			$pat =~ tr/ //d;
			my $operator = '=';	
			$query .= '(';
			if($pat =~ s/^do\%(.+?)\%op//) {
				$operator = $1;
			}
			my $subpat_count = 0;
			my @subpats = split(',', $pat);
			foreach my $subpat (@subpats) {
				$query .= "$attribute=$subpat";
				$query .= " OR " if $subpat_count++ < $#subpats;
			}
			$query .= ')';
			$query .= ' AND ' if ++$count <= $num_pats;
		}
	}
	return $query;
}

sub sqlescape
{
	my($data) = @_;
	$data =~ s/'/\\'/g;
	return $data;
}
	


1
__END__
