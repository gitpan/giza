#!/usr/bin/perl
# -+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
# Giza/User/SDB.pm - SessionDB Interface
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


package Giza::User::SDB;
# ------------------------------------------------------------------ #

use strict;
use Carp;
use Giza;
use DB_File;
use Exporter;
use FileHandle;
use Giza::User;
use Class::Struct;
use Fcntl qw(:flock);

struct(
	giza	=> '$',
	db		=> '$',
	user	=> '$',
	content	=> '$',
	fh		=> '$',
	locked	=> '$',
);
	
sub lock {
	my($self, $method) = @_;
	my $g = $self->giza;
	my $c = $g->config;
	my $sdb = $c->{global}{sessiondb};

	if(-f $sdb) {
		$self->fh(new FileHandle $sdb);
		unless(flock $self->fh, $method) {
			$g->error("Couldn't get lock ($method) for sessiondb: $!");
			return FALSE;
		}
		$self->locked(1);
	}
	return TRUE;
}

sub unlock {
	my($self) = @_;
	if($self->fh) {
		flock $self->fh, LOCK_UN;
		close $self->fh;
		$self->locked(0);
	}
	return TRUE;
}


sub open {
	my($self) = @_;
	my $g = $self->giza;
	my $c = $g->config;

	$self->lock(LOCK_EX);
	tie my %sdb, 'DB_File', $c->{global}{sessiondb}, O_CREAT|O_RDWR, 0640, $DB_HASH
		or $g->error("Couldn't create sessiondb: $! ".$c->{global}{sessiondb}), return FALSE;
	$self->content(\%sdb);

	return TRUE;
}

sub close {
	my($self) = @_;
	my $g = $self->giza;
	my $content = $self->content;
	untie %$content if $content;
	$self->unlock if $self->locked;
	return TRUE;
}

1
__END__
