#!/usr/bin/perl 

use strict;

sub sidxtract {
	my($f, $s);
	my @X = split //, shift;
	for(my $c = 0; $c <= $#X; $c++) {
		$c % 2 ? $s.=$X[$c] : ($f.=$X[$c]);
	} [$f, $s];
}

sub sidmerge {
	my $s;
	my @X = split //, shift;
	my @Y = split //, shift;
	my $l = ($#X > $#Y) ? $#X : $#Y;
	for(my $c = 0; $c <= $l; $c++) {
		defined $X[$c] ? $s.=$X[$c] : ($s.='#');
		defined $Y[$c] ? $s.=$Y[$c] : ($s.='#');
	} $s;	
}
			

my $arr = sidxtract($ARGV[0]);
print "$arr->[0] : $arr->[1]\n";
print sidmerge($ARGV[0], $ARGV[1]), "\n";
			


