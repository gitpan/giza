#!/usr/bin/perl 

use strict;
use lib './include';
use Giza;
use Giza::DB;
use Giza::User;
use Giza::Object;
use Giza::ObjView;
use Giza::Template;
use Giza::Component;
use Crypt::PasswdMD5;

select STDERR;
print "Testing Giza... \n";
my $g	= Giza->new() or die;
print "  Giza version is.................... $Giza::VERSION\n";
		print "  Giza's prefix path is.............. $Giza::PREFIX\n";
print "  Giza's configuration file is at.... $Giza::CONFIGFILE\n";
print "Loading modules... \n";
print "  Giza::DB........................... ";
my $d	= $g->Giza::DB::new() or die;
print "OK\n";
print "  Giza::User......................... ";
my $u	= Giza::User::new(giza=>$g, db=>$d) or die;
print "OK\n";
print "  Giza::Template..................... ";
my $t	= new Giza::Template(giza=>$g, db=>$d) or die;
print "OK\n";
print "  Giza::Object....................... ";
my $o	= Giza::Object::new(giza=>$g, db=>$d, user=>$u) or die;
print "OK\n";
print "  Giza::ObjView...................... ";
my $v	= Giza::ObjView::new(giza=>$g, db=>$d) or die;
print "OK\n";
print "  Giza::Component.................... ";
my $c	= Giza::Component::new(giza=>$g, db=>$d) or die;
print "OK\n";
print "\nChecks successful.\n";

my $args = join("   ", @ARGV);
print join(":", $t->parseline($args)), "\n";

=comment
my $pw = shift @ARGV;
my $salt = Giza::mkpasswd(8);

my $cryptpw = $salt. unix_md5_crypt($pw, $salt);

print $cryptpw, "\n";
=cut
