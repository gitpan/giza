#!/usr/bin/perl 

#%include <config.pimpx>

#%ifdef PREFIX
#%  define INCLUDE "%{PREFIX}/include"
#%endif

#%print use lib '%{INCLUDE}';

use strict;
use CGI;
use Giza;
use POSIX;
chdir $Giza::PREFIX;

my $query = new CGI;
my $location = $query->param('location');
my $oid		 = $query->param('oid');

if(defined $location) {
	# Send the user to the new page first, so she don't have to wait.
	print $query->header(-location => $location);
	print STDOUT "HTTP/1.1 200 OK\n";
	print STDOUT "Transfer-Encoding: chunked\n";
	print STDOUT "Location: $location\n\n";
	my $pid = fork;
	exit if $pid;
	POSIX::setsid();
	my $giza = new Giza;
	my $handler = $giza->config->{forwarder}{forwardhandler};
	if(defined $handler) {
		eval "use $handler; ${handler}::handler(\$giza, \$oid, \$location)";
		print STDERR $@ if $@;
	}
	exit;
} else {
	#print STDOUT "HTTP/1.1 200 OK\n";
	#print STDOUT "Transfer-Encoding: chunked\n";
	#print STDOUT "Content-Type: text/html; charset=ISO-8859-1\n\n";
	print $query->header;
	print STDOUT qq{
<html>
	<head><title>missing location</title></head>
	<body>
		<h1>Missing location</h1>
	</body>
</html>
	};
}



