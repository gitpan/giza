#!/usr/bin/perl

use strict;
use Fcntl;

my $filename = shift @ARGV;

if(sysopen(TMPL, $filename, O_RDONLY))
{
	my $readlen = 2**4;
	my $in_code_block = 0;
	my $fc; # filecontent
	my $cc; # codecontent
	my $lc; # linecount;
	my($k_st, $k_fi);
	my($p_st, $p_fi);
	while(sysread(TMPL, $_, $readlen))
	{
		sub savecc {
			print $cc, "\n";
			undef $cc;
		}
	
		if($k_st && /^\?/) {
			print "buf continued: $_\n";
			$k_st=0, $p_st=0, $in_code_block=1;
		}
		if($k_fi && /^\>/) {
			$p_fi=0, $in_code_block=0;
			savecc();
		}
		($k_st, $k_fi) = (0, 0);
		/\<$/ and $k_st++;
		/\?$/ and $k_fi++;

		unless($in_code_block) {
			$p_st = index($_, '<?');
			if($p_st != -1) {
				$in_code_block=1;
			}
		}
		if($in_code_block) {
			$p_fi = index($_, '?>', $p_st);
			if($p_fi != -1) {
				$in_code_block=0, savecc();
			}
			$p_st||=0, $p_fi||=length $_;
			$cc .= substr($_, $p_st+2, $p_fi-2);
		}		
		
		$lc += tr/\n/\n/;
	}
	print "Lines: $lc\n";
}
		
