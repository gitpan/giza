#!/usr/bin/perl

package Giza::Handler::Forward::ClickDB;

use strict;
use DB_File;
use Fcntl qw(:flock);

sub handler
{
	my($giza, $oid, $location) = @_;
	my $db = $giza->config->{forwarder}{handlerconfig}{db};
	if(-f $db) {
		open(DB, $db) or $giza->error("Couldn't open $db: $!"), return 1;
		flock(DB, LOCK_EX);
	}
	tie my %db, 'DB_File', $db, O_CREAT|O_RDWR, 0640, $DB_HASH
		or $giza->error("Couldn't create sessiondb $db: $!"), return 1;
	if($db{$oid}) {
		$db{$oid} = 1;
	} else {
		$db{$oid}++;
	}
	untie %db;
	flock(DB, LOCK_UN);
	close DB;
	return 0;
}
	
1;
	
