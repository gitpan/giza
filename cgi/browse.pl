#!/usr/bin/perl 

#%include <config.pimpx>

#%ifdef PREFIX
#%  define INCLUDE "%{PREFIX}/include"
#%endif

#%print use lib '%{INCLUDE}';

BEGIN {
	$ENV{REMOTE_ADDR} ||= '127.0.0.1';
	$ENV{QUERY_STRING}||= $ARGV[0];
}

use strict;
use CGI;
use Giza;
use Giza::Modules;

#%ifdef DEBUG
use CGI::Carp qw(fatalsToBrowser);
#%endif

chdir $Giza::PREFIX;
my $query = new CGI;

my($giza, $db, $user, $template)
	= giza_session(qw(db user template));

my $page	= $query->param("page");
my $parent	= $query->param("parent") || G_CAT_TOP;

if($ENV{GIZA_TEMPLATE}) {
	$giza->config->{global}{template_dir} = $ENV{GIZA_TEMPLATE};
}

$page	||= $giza->config->{template}{"index"};

$template->cgi($query);
$template->parent($parent);

$db->connect() or die $giza->error();

print $template->do($page);

END {
	$db->disconnect() if $db->connected();
}
