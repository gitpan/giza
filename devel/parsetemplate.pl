#!/usr/bin/perl

use strict;

my $test = shift @ARGV;

my $argv = parse(qq[print 'he"i"' "hvordan 'gaar' det?" cgi:updates {$test}]);

print join(': ', @$argv), "\n";

sub parse {
	my($line) = @_;

	my($iwq, $ipq, $ibq, $ib) = (0, 0, 0, 0);
	my @argv = ();
	my $argc = 0;
	
	foreach my $chr (split //, $line) {
		if($chr eq '"') {
			unless($ibq||$ib||$ipq) {
				$iwq = $iwq ? 0 : 1; next;
			}
		}
		elsif($chr eq "'") {
			unless($ibq||$ib||$iwq) {
				$ipq = $ipq ? 0 : 1; next;
			}
		}
		elsif($chr eq '\\') {
			$ibq=1, next unless($ipq||$ibq);
		}
		elsif($chr eq '{') {
			unless($ibq||$ib||$iwq) {
				$ib=1, next;
			}
		}
		elsif($chr eq '}') {
			if($ib==1) {
				$argv[$argc] = eval($argv[$argc]);
				$ib=0, next;
			}
		}
		elsif($chr eq ' ') {
			$argc++, next unless($ibq||$ib||$iwq||$ipq);
		}

		$ib=0 if $ibq;
		$argv[$argc] .= $chr;
	} \@argv;
}	
	
