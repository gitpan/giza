#!/usr/bin/perl
# -+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
# Giza::Template::FuncLoader - A system to extend the giza template system.
# (c) 1996-2002 ABC Startsiden AS, see the file AUTHORS.
#
# See the file LICENSE in the Giza top source distribution tree for
# licensing information. If this file is not present you are *not*
# allowed to view, run, copy or change this software or it's sourcecode.
# -+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
#####

=comment
I give you my affection and i give you my time
=cut

package Giza::Template::FuncLoader;
use strict;

# ---------- - -  -    -     -        - 
# <=+=> 	Global variables 	<=+=> #

# ### Hash of registred classes.
# KEY: Name of class,
# VALUE: Reference to object.
#
my %classes		= ();

# ### Hash of class aliases.
# KEY: Name of alias
# VALUE: Name of the class the key is an alias to.
#
my %class_alias	= ();

# ### Hash of registered functions.
# KEY: Name of function,
# VALUE: Class funcion resides in.
#
my %functions	= ();


# ---------- - -  -    -     -        -
# <=+=> 	Constructor			<=+=> #

# ### Giza::Template::FuncLoader new(pkg pkg, Giza::Template template)
# Create a new FuncLoader object.
#
sub new
{
	my($pkg, $template) = @_;
	$pkg = ref $pkg || $pkg;
	my $self = {};
	bless $self, $pkg;

	# save template object reference.
	if(ref $template eq 'Giza::Template') {
		$self->Template( $template );
	}

	return $self;
}

# ---------- - -  -    -     -        -
# <=+=> 	Accessors			<=+=> #

# ### Giza::Template Template(Giza::Template::FuncLoader fl, Giza::Template tmpl)
# Get/set giza template object reference.
#
sub Template
{
	my($self, $template) = @_;
	$self->{_TEMPLATE} = $template if $template;
	return $self->{_TEMPLATE};
}

# ---------- - -  -    -     -        -
# <=+=> 	Methods				<=+=> #

# ### {moudule}-ref load(Giza::Template::FuncLoader fl, string module
# 
sub load
{
	my($self, $module) = @_;
	my $obj;
	eval "
		use $module;
		\$obj = ${module}->new(\$self);
	"; return $obj;
}

sub exec
{
	my($self, $namespace, $function, @argv) = @_;

	unless($classes{$namespace}) {
		$namespace = $class_alias{$namespace};
	}
	if($classes{$namespace}) {
		if($functions{$namespace}{$function}) {
			my $obj = $classes{$namespace};
			return $obj->$function(@argv);
		}
	}
}


sub register_class
{
	my($self, $alias, $obj) = @_;
	$class_alias{$alias} = ref $obj;
	$classes{ref $obj} = $obj;
	return 1;
}

sub register_function
{
	my($self, $function, $class) = @_;
	unless(ref $class) {
		my($classname) = caller;
		$class = $classes{$classname};
	}
	if($class->can($function)) {
		$functions{ref $class}{$function} = "${class}::${function}";
	} else {
		$self->Template->giza->error(sprintf(
			'Class %s has no support for method: %s',
			ref($class), $function
		));
	}
}

sub dump
{
	my($self) = @_;
	foreach my $alias (keys %class_alias) {
		print "ALIAS: $alias => $class_alias{$alias}\n";
	}
	foreach my $class (keys %classes) {
		print "CLASS: $class\n";
		foreach my $function (keys %{$functions{$class}}) {
			print "\tFUNCTION: $function ($class)\n";
		}
	}
}

1;
