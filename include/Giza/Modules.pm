#!/usr/bin/perl

use strict;
package main;

use Giza;
use Giza::User;
use Giza::Template;
use Giza::Object;
use Giza::Component;
use Giza::ObjView;
use Giza::Template::FuncLoader;
use Giza::DB;

package Giza::Modules;

use Exporter;
use vars qw(@ISA @EXPORT);

@ISA = qw(Exporter);
@EXPORT = qw(&giza_session);

sub giza_session(@)
{
	my(%use) = map {$_ => 1} @_;
	my($giza, $db, $user, $template, $object, $component, $objview);

	$giza = new Giza;
	
	if(!%use or $use{db}) {
		$db		= new Giza::DB $giza;
	}
	if(!%use or $use{user}) {
		$user	= new Giza::User(giza => $giza, db => $db);
	}
	if(!%use or $use{template}) {
		$template= new Giza::Template(giza => $giza, db => $db, user => $user);
	}
	if(!%use or $use{object}) {
		$object	= new Giza::Object(giza => $giza, db => $db, user => $user);
	}
	if(!%use or $use{component}) {
		$component = new Giza::Component(giza => $giza, db => $db, user => $user);
	}
	if(!%use or $use{objview}) {
		$objview = new Giza::ObjView(giza => $giza, db => $db, user => $user);
	}

	return(
		$giza, $db, $user, $template, $object, $component, $objview
	);
}

1;
