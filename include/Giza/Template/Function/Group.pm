#!/usr/bin/perl

package Giza::Template::Function::Group;
use strict;

my @functions = qw(
	list
);

sub new
{
	my($pkg, $funcLoader) = @_;
	my $self = {};
	bless $self, $pkg;
	$self->funcLoader($funcLoader);
	return $self;
}

sub funcLoader
{
	my($self, $funcLoader) = @_;
	my($class, $function, $line, $sub) = caller;
	$self->{FUNCLOADER} = $funcLoader
		if defined $funcLoader;
	return $self->{FUNCLOADER};
}

sub register
{
	my($self) = @_;
	$self->funcLoader->register_class('group', $self);

	foreach my $func (@functions) {	
		$self->funcLoader->register_function($func);
	}
}

sub list
{
	my($self, $pat) = @_;
	my $t  = $self->funcLoader->Template;
	my $g  = $t->giza;
	my $u  = $t->user;
	my $db = $t->db;

	$pat ||= "a";
	$pat = lc $pat;
	my $query = "SELECT id,name,password FROM groups WHERE name LIKE '$pat%'";
	my $sth = $db->query($query);
	my $data;
	while(my $entry = $db->fetchrow_hash($sth)) {
		$t->setvar("group", "name", $entry->{name});
		$t->setvar("group", "id", $entry->{id});
		$t->setvar("group", "password", $entry->{password});
		$data .= $t->include($g->config->{template}->{groupentry});
	}
	$db->query_end($sth);
	return $data;
}

1;
