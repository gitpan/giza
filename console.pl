#!/usr/bin/perl 

#%include <config.pimpx>

#%ifdef PREFIX
#%  define INCLUDE "%{PREFIX}/include"
#%endif

#%print use lib '%{INCLUDE}';
use strict;
use Giza;
use Term::ReadLine;
use vars qw(%wordcache $shellmode);

my $term = new Term::ReadLine 'giza verbose console';
my $prompt = 'giza> ';

# ### redirect errors to /dev/null
if(open NULL, ">/dev/null") {
	*STDERR = *NULL;
}

for(;;) {
	$_ = $term->readline($prompt);
	chomp;
	next unless length;
	next if /^\s+$/;
	system("${Giza::PREFIX}cgi/browse.pl '$_' 2>/dev/null");
	$term->addhistory($_) if /\S/;
	next;
}
