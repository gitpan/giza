#!/usr/bin/perl

use lib '/opt/giza2/include';

use Giza;
use Giza::Modules;
use HTML::Entities;
use strict;

my $giza = new Giza;
$giza->config->{database}{user} = 'giza';
$giza->config->{database}{db}   = 'giza';
my $db = new Giza::DB $giza;

$db->connect() or die $giza->error, "\n";

print '<?xml version="1.0" encoding="ISO-8859-1" standalone="yes"?>', "\n";
print "<category_import>\n";
recurse_get_cat($db, -1, 10);
print "</category_import>\n";

#print getparent($db, 2320), "\n";

sub recurse_get_cat
{
	my($db, $parent, $grad, $ident) = @_;
	my $query = qq{
		SELECT * FROM cat_cat WHERE over='$parent'
	};
	my $sth = $db->query($query);
	while(my $hres = $db->fetchrow_hash($sth)) {
		my $meta = fetch_cat_meta($db, $hres->{under});
		my $parent = getparent($db, $hres->{over});
		if($parent) {
			$parent = 'root::' . $parent;
		} else {
			$parent = 'root';
		}
		
		print sprintf('  <object type="cat">'), "\n";
		print sprintf('    <name>%s</name>', toxml($hres->{title})), "\n";
		print sprintf('    <parent>name:%s</parent>', toxml($parent)), "\n";
		print sprintf('    <sort>%d</sort>', toxml($hres->{"sort"})), "\n";
		print sprintf('    <created>%s</created>', toxml($meta->{date_added})), "\n";
		print sprintf('    <changed>%s</changed>', toxml($meta->{date_revised})), "\n";
		print sprintf('    <keywords>%s</keywords>', toxml($meta->{keywords})), "\n";
		print sprintf('    <description>%s</description>', toxml($meta->{description})), "\n";
		print sprintf('    <active>1</active>'), "\n";
		print sprintf('  </object>'), "\n";
		recurse_get_cat($db, $hres->{under}, $grad, $ident);
		$ident--;
	}
}

sub fetch_cat_meta
{
	my($db, $id) = @_;
	my $query = "SELECT * FROM categories WHERE id='$id'";
	return $db->fetchonerow_hash($query);
}

sub getparent
{
	my($db, $parent) = @_;
	my @path = ();
	while($parent) {
		my $query = "SELECT over, under, title FROM cat_cat WHERE under='$parent'";
		my $hres = $db->fetchonerow_hash($query);
		push @path, $hres->{title};
		if($hres->{over} == -1) {
			last;
		} else {
			$parent = $hres->{over};
		}
	}
	return join("::", reverse @path);
}

sub toxml {	
	my($text) = @_;
	$text =~ s/<[^>]*>//gs;
	$text =~ s///g;
	$text =~ s///g;
	$text =~ s/&/&amp;/g;
	$text =~ s/>/&gt;/g;
	$text =~ s/</&lt;/g;
	#$text = HTML::Entities::encode($text);
	return $text;
}
	

END {
	$db->disconnect() if ref $db;
}
	
