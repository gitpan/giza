#!/usr/bin/perl -w

#%include <config.pimpx>

#%ifdef PREFIX
#%  define INCLUDE "%{PREFIX}/include"
#%endif

#%print use lib '%{INCLUDE}';

use strict;
use CGI;
use Version;
use Giza;
use Giza::User;
use Giza::Object;
use Giza::ObjView;
use Giza::DB;
use Giza::Template;
use Giza::Component;
use Giza::Component::Rate;
use CGI::Carp qw(fatalsToBrowser);
use CGI::Cookie;
use vars qw($page $parent);


print "Content-type: text/html\n\n";

my $giza = new Giza;
my $v = new Version ($Giza::VERSION);
my $exversion = $v->extended;
my $c = $giza->config;

print qq[
<html>
	<head>
		<title>Perl Environment</title>
		<style type="text/css">
		<!--
			BODY {
				background-color: #5e2f72;
			}
			TABLE {
				background-color: #54435b;
			}
			TD {
				background-color: #54435b;
			}
			TR {
				background-color: #29262b;
				text-align: left;
				color: #b4acb7;
			}
			
		-->
		</style>
	</head><body>
		<table><tr><th><h1>Giza</h1></th><td><h1>Environment</h1></td></tr></table>
		<table border=0>
];

print qq[<tr><th>&nbsp;</th><th>&nbsp;</th></tr>];

foreach my $key (sort keys %ENV) {
	print qq[
		<tr><th>$key</th><td>$ENV{$key}</td></tr>
	];
}
print qq[<tr><th>&nbsp;</th><th>&nbsp;</th></tr>];
print qq[<tr><th>Giza prefix</th><td>$Giza::PREFIX</td></tr>];
print qq[<tr><th>Giza version</th><td>$Giza::VERSION</td></tr>];
print qq[<tr><th>Giza ext. version</th><td>$exversion</td></tr>];

foreach my $key (sort keys %$c) {
	print qq[
		<tr><th>$key</th><th>&nbsp;</th></tr>
	];
	foreach my $ckey (sort keys %{$c->{$key}}) {
		print qq[
			<tr><th>$ckey</th><td>$c->{$key}->{$ckey}</td></tr>
		];
	}

}

print qq[<tr><th>&nbsp;</th><th>&nbsp;</th></tr>];

print qq[
	</table>
	</body>
</html>
];



