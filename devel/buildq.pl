#!/usr/bin/perl -w

use strict;

sub build_select_q {
	my($self, $table, %match) = @_;

	my $query = "SELECT * FROM $table WHERE ";
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

	return $query;
}

print buildq(undef, 'catalog', id=>'13,14,15,16,17', type=>2), "\n";
		
		
	
