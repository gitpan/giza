#!/usr/bin/perl

package Giza::Template::Function::TestClass;
use strict;

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
	$self->funcLoader->register_class('test', $self);
	$self->funcLoader->register_function('dumpdata');
}

sub dumpdata
{
	my($self) = @_;
	$self->funcLoader->dump;
}

1;
