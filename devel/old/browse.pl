#!/usr/bin/perl 

use strict;
use lib './include';
use Giza qw(:all);
use Giza::Object;
use Giza::ObjView;
use Giza::DB;
use Giza::Template;
use Time::HiRes qw(gettimeofday tv_interval);
use CGI qw(:standard EscapeHTML);

my $t0 = [gettimeofday];

my $g	= Giza->new();
my $db	= $g->Giza::DB::new();
my $v	= new Giza::ObjView(giza=>$g, db=>$db);

$g->config->{debug} = 1;

$db->connect() or die $g->error();

print header;

print qq{
<html>
<head> <title>giza2 test</title> </head>
<body>
	<h1>Giza2</h1>
};

my $parent = param("parent");
$parent ||= G_CAT_TOP;
my $objs = $v->fetch_where_parent($parent);


unless($parent == G_CAT_TOP) {
	my $tree = $v->fetch_html_tree($parent);
	print "<b>$tree</b><br/>&nbsp;<br/>";
}

foreach my $obj (@$objs) {
	next unless $obj->type eq G_OBJ_CAT;
	printf('<A href="%s?parent=%d">%s/</a><br/>',
		$ENV{SCRIPT_NAME},
		$obj->id,
		$obj->name
	);	
	print "\n";
}

print "<hr>\n";

foreach my $obj (@$objs) {
	next if $obj->type == G_OBJ_CAT;
	printf('<A href="%s">%s</a><br/>%s<br/>&nbsp;<br/>',
		$obj->data,
		$obj->name,
		$obj->description,
	);
	print "\n";
}

my $elapsed = tv_interval($t0, [gettimeofday]);

print qq{
	<small><b>Time elapsed: $elapsed second(s)</b></small>
</body>
</html>
};

END {
	$db->disconnect();
}
