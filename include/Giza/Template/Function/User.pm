#!/usr/bin/perl

package Giza::Template::Function::User;
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
	$self->funcLoader->register_class('user', $self);

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
	my $query = "SELECT id,username,real_name FROM users WHERE username LIKE '$pat%'";
	my $sth = $db->query($query);
	my $data;
	while(my $entry = $db->fetchrow_hash($sth)) {
		$t->setvar("user", "username", $entry->{username});
		$t->setvar("user", "id", $entry->{id});
		$t->setvar("user", "real_name", $entry->{real_name});
		$data .= $t->include($g->config->{template}->{userentry});
	}
	$db->query_end($sth);
	return $data;
}

1;
