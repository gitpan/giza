#!/usr/bin/perl
# -+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
# Giza::Component - The Giza component Interface.
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

package Giza::Component;
# ----------------------------------------------------------------- #

use strict;
use Giza;
use Exporter;
use Carp;
use vars qw(@ISA @EXPORT @EXPORT_OK);

# ----------------------------------------------------------------- #
# export variables and functions.

@ISA = qw(Exporter);
@EXPORT = qw(
	&COMP_ERROR &COMP_SUCCESS &COMP_REJECT
	&COMP_FATAL &COMP_ARG_MISSING
	&COMP_FIELD_MISSING
);

# ### Return codes for components.
sub COMP_SUCCESS		{11009}; # The component returned success.
sub COMP_ERROR			{11010}; # The component got an error. (check Giza::Error)
sub COMP_REJECT			{11011}; # The component rejected to return anything.
sub COMP_FATAL			{11012}; # The component got an fatal error. (check Giza::Error)
sub COMP_ARG_MISSING	{11013}; # The component is missing an argument.
sub COMP_FIELD_MISSING	{11014}; # The component did not find a database field.

# ----------------------------------------------------------------- #
# constructor

# ### Giza::Component new(hash arguments)
# Create a new Giza::Component object.
# Needs:
#	giza 	=> Giza object
#	db 		=> Giza::DB object
#
sub new
{
	my($self, %argv) = @_;
	my $obj = {};
	bless $obj, 'Giza::Component';

	#%ifdef DEBUG
	# check for lazy programming.
	 confess "Giza::Component construct did not get a Giza object"
		unless ref $argv{giza};
	confess "Giza::Component construct did not get a database object"
		unless ref $argv{db};
	#%endif

	$obj->giza($argv{giza});
	$obj->db($argv{db});

	return $obj;
}

# ----------------------------------------------------------------- #
# methods

sub giza
{
	my($self, $giza) = @_;
	$self->{GIZA} = $giza if $giza;
	return $self->{GIZA};
}

sub db
{
	my($self, $db) = @_;
	$self->{DB} = $db if $db;
	return $self->{DB};
}

sub do
{
	my($self, $action, $module, @args) = @_;
	my $giza 	= $self->giza;
	my $db		= $self->db;
	my $ret 	= {status=>COMP_SUCCESS};

	#### do we have a valid action?
    #%ifdef DEBUG
	my %valid_action = map{$_ => 1}
		qw(fetch store delete update template_handler);
	unless($valid_action{$action}) {
		confess "unknown action: $action, allowed actions are: ",
			join ", ", keys %valid_action;
	}
	#%endif

	# ###
	# use Giza::Component::Rate;
	# my $obj = new Giza::Component::Rate(giza => $giza, db => $db);
	# $ret = $obj->fetch(@args);
	eval("	use $module;
			my \$obj = new $module(giza => \$giza, db => \$db);
			\$ret = \$obj->$action(\@args);
	");
	if($@) {
		$giza->error("Component $module couldn't load: $@");
		$ret->{status} = COMP_FATAL;
	}
	return $ret;
}

# ----------------------------------------------------------------- #
# Shortcuts to do()

sub fetch
{
	my($self, $module, @args) = @_;
	return $self->do("fetch", $module, @args);
}

sub store {
	my($self, $module, @args) = @_;
	return $self->do("store", $module, @args);
}

sub delete {
	my($self, $module, @args) = @_;
	return $self->do("delete", $module, @args);
}

sub update {
	my($self, $module, @args) = @_;
	return $self->do("update", $module, @args);
}

sub template_handler {
	my($self, $module, @args) = @_;
	return $self->do("template_handler", $module, @args);
}
		
1
__END__
