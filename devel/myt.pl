#!/usr/bin/perl

use strict;

my $scalar = 'hei';
my $scalar2 = 'hallo';
my $refto  = \$scalar;
my $refto2 = \$scalar2;

my %CACHE = map { $_ => $refto } qw(
	1 26 80 63 95 27 38 129 43 85
	2 196 34 27 67
);

my %DB = map {$_ => $refto2} qw(
	1 89 34 127 180
);
	

my @fetchIds = qw(1 89 34 127 128 180);
my @result = @fetchIds;

for(my $qno = 0; $qno <= $#result; $qno++) {
	if($CACHE{ $result[$qno] }) {
		print "IN CACHE: $result[$qno]\n";
		$result[$qno] = $CACHE{ $result[$qno] };
	}
}
my $rest = join(',', grep {not ref} @result);

foreach my $id (split /\s*,\s*/, $rest) {
	my $qno = get_next_place(\@result);
	if($DB{$id}) {
		$result[$qno] = $DB{$id};
	};
}

@result = grep {ref} @result;

print join(" ", @result);

sub get_next_place {
	my($arrayref) = @_;
	for(my $qno = 0; $qno <= $#$arrayref; $qno++) {
		return $qno unless ref $arrayref->[$qno];
	}
	return $#$arrayref + 1;
}

	

