#!/usr/bin/perl

#%include <config.pimpx>

#%ifdef PREFIX
#%  define INCLUDE "%{PREFIX}/include"
#%endif

#%print use lib '%{INCLUDE}';


package Giza::Template::Function::Catalog;
use strict;
use Giza::Template;

my $objs = [];

my @functions = qw(
	search get 
	directories links images guides
	references ftps mp3s oggs
	catalogByOwner last10
	storerate saveobject
	treeview reset
);

sub new
{
	my($pkg, $funcLoader) = @_;
	my $self = {};
	bless $self, $pkg;
	$self->funcLoader($funcLoader);
	# Flush the object array.
	@$objs = ();
	return $self;
}

sub funcLoader
{
	my($self, $funcLoader) = @_;
	my($class, $function, $line, $sub) = caller;
	$self->{FUNCLOADER} = $funcLoader
		if defined $funcLoader;
	return $self->{FUNCLOADER};
}

sub register
{
	my($self) = @_;
	$self->funcLoader->register_class('catalog', $self);

	foreach my $func (@functions) {	
		$self->funcLoader->register_function($func);
	}
	return undef;
}

sub search
{
	my($self, $pat) = @_;
	my $fl = $self->funcLoader;
	my $t  = $fl->Template;
	my $g  = $t->giza;
	my $u  = $t->user;
	my $db = $t->db;

	my $objview = new Giza::ObjView(giza=>$g, db=>$db, user=>$u);

	my $searchmod = $g->config->{search}{module};
	my $search; eval "
		use $searchmod;
		\$search = ${searchmod}->new(giza=>\$g, user=>\$u, db=>\$db);
	";
	my $object = new Giza::Object(giza=>$g, user=>$u, db=>$db);	
	if(ref $search) {
		$objs = $search->search($object, $pat);
	}
	return undef;
}

sub get
{
	my($self, $fetch) = @_;
	my $t  = $self->funcLoader->Template;
	my $g  = $t->giza;
	my $u  = $t->user;
	my $db = $t->db;
	
	my $objview = new Giza::ObjView(giza=>$g, db=>$db, user=>$u);
	my %fetch; eval "\%fetch = ($fetch)";
	if($t->getvar('opt:dont_recurse_refs')) {
		$objview->dont_recurse_refs;
	}
	$objs = $objview->fetch(%fetch);
	return undef;
}

sub catalogByOwner
{
	my($self, $owner, $template) = @_;
	my $t  = $self->funcLoader->Template;
	my $g  = $t->giza;
	my $u  = $t->user;
	my $db = $t->db;

	$owner = $u->uidbyname($owner);

	my $objview = new Giza::ObjView(giza=>$g, db=>$db, user=>$u);
	my $objects = $objview->fetch(owner => $owner, type => "'catalog'");

	my $html;
	foreach my $object (@$objects) {
		$t->set_obj_vars($object);
		$html .= $t->include($template);
	}
	return $html;
}

sub last10
{
	my($self, $template) = @_;
	my $t  = $self->funcLoader->Template;
	my $g  = $t->giza;
	my $u  = $t->user;
	my $db = $t->db;

	my $objview = new Giza::ObjView(giza=>$g, db=>$db, user=>$u);
	my $objects = $objview->fetch(LIMIT => 10, ORDER => 'changed DESC');

	my $html;
	foreach my $object (reverse @$objects) {
		$t->set_obj_vars($object);
		$html .= $t->include($template);
	}
	return $html;
}

sub treeview
{
	my($self) = @_;
	my $t  = $self->funcLoader->Template;
	my $g  = $t->giza;
	my $u  = $t->user;
	my $db = $t->db;
	my $objview = new Giza::ObjView(giza=>$g, db=>$db, user=>$u);

	my $treeview_template = $t->getvar('objdefaults:treeview');
	$treeview_template ||= $g->config->{template}{treeview};

	unless($t->getvar('giza:parent')) {
		$t->setvar('giza', 'parent', $t->getvar('cgi:parent'));
	}

	my $names = $objview->fetch_tree($t->getvar('giza:parent'));
	my $tree = undef;
	foreach my $aref (reverse @$names) {
		my($id, $name) = @$aref;
		my $expr = $db->expr_by_id($id);
		$expr =~ s/(.+?)(::|$)//;
		$t->setvar("tree", "id", $id);
		$t->setvar("tree", "webpath", Giza::Template::expr_to_path($expr));
		$t->setvar("tree", "name", $name);
		$tree .= $t->include($treeview_template);
	}
	return $tree;
}
	

sub directories
{
	my($self) = @_;
	my $t  = $self->funcLoader->Template;
	my $g  = $t->giza;
	my $u  = $t->user;
	my $db = $t->db;
	my $directories = undef;

	foreach my $obj (@$objs) {
		next unless $obj->type eq 'catalog';
		my $template = $self->get_template('directory', $obj);
		if($t->getvar("objdefaults:directory")) {
			$template = $t->getvar("objdefaults:directory");
		}
		$t->set_obj_vars($obj);
		$directories .= $t->include($template);
	}
	return $directories;
}

sub links
{
	my($self) = @_;
	my $t  = $self->funcLoader->Template;
	my $g  = $t->giza;
	my $u  = $t->user;
	my $db = $t->db;

	my $links = undef;
	foreach my $obj (@$objs) {
		next if $obj->type ne 'link';
		my $template = $self->get_template('link', $obj);
		$t->set_obj_vars($obj);
		$links .= $t->include($template);
	}
	return $links;
}

sub guides
{	
	my($self) = @_;
	my $t  = $self->funcLoader->Template;
	my $g  = $t->giza;
	my $u  = $t->user;
	my $db = $t->db;

	my $guide = undef;
	foreach my $obj (@$objs) {
		next if $obj->type ne 'guide';
		my $flags = $t->get_obj_flags($obj->data);
		print STDERR "I GOT A GUIDE :)\n";
		$t->setvar('guide', 'mail', $flags->{mail});
		$t->setvar('guide', 'homepage', $flags->{homepage});
		$t->setvar('guide', 'image', $flags->{image});
		$t->set_obj_vars($obj);
		my $template = $self->get_template('guide', $obj);
		$guide .= $t->include($template);
	}
	return $guide;
}


sub images
{
	my($self) = @_;
	my $t  = $self->funcLoader->Template;
	my $g  = $t->giza;
	my $u  = $t->user;
	my $db = $t->db;

	my $images = undef;
	foreach my $obj (@$objs) {
		next if $obj->type ne 'image';
		my $flags = $t->get_obj_flags($obj->data);
		$t->setvar('image', 'image', $flags->{image});
		$t->setvar('image', 'thumbnail', $flags->{thumbnail});
		$t->set_obj_vars($obj);
		my $template = $self->get_template('image', $obj);
		$images .= $t->include($template);
	}
	return $images;
}

sub ftps
{
	my($self) = @_;
	my $t  = $self->funcLoader->Template;
	my $g  = $t->giza;
	my $u  = $t->user;
	my $db = $t->db;

	my $ftps = undef;
	foreach my $obj (@$objs) {
		next if $obj->type ne 'ftp';
		my $flags = $t->get_obj_flags($obj->data);
		$t->setvar('ftp', 'host', $flags->{host});
		$t->setvar('ftp', 'port', $flags->{port});
		$t->setvar('ftp', 'username', $flags->{username});
		$t->setvar('ftp', 'password', $flags->{password});
		$t->setvar('ftp', 'directory', $flags->{directory});
		$t->set_obj_vars($obj);
		my $template = $self->get_template('ftp', $obj);
		$ftps .= $t->include($template);
	}
	return $ftps;
}

sub mp3s
{
	my($self) = @_;
	my $t  = $self->funcLoader->Template;
	my $g  = $t->giza;
	my $u  = $t->user;
	my $db = $t->db;

	my $music = undef;
	foreach my $obj (@$objs) {
		next if $obj->type ne 'mp3';
		my $flags = $t->get_obj_flags($obj->data);
		$t->setvar('music', 'url', $flags->{url});
		$t->setvar('music', 'title', $flags->{title});
		$t->setvar('music', 'artist', $flags->{artist});
		$t->setvar('music', 'album', $flags->{album});
		$t->setvar('music', 'comment', $flags->{comment});
		$t->setvar('music', 'year', $flags->{year});
		$t->setvar('music', 'track_no', $flags->{track_no});
		$t->setvar('music', 'genre', $flags->{genre});
		$t->set_obj_vars($obj);
		my $template = $self->get_template('mp3', $obj);
		$music .= $t->include($template);
	}
	return $music;
}
sub oggs
{
	my($self) = @_;
	my $t  = $self->funcLoader->Template;
	my $g  = $t->giza;
	my $u  = $t->user;
	my $db = $t->db;

	my $music = undef;
	foreach my $obj (@$objs) {
		next if $obj->type ne 'ogg';
		my $flags = $t->get_obj_flags($obj->data);
		$t->setvar('music', 'url', $flags->{url});
		$t->setvar('music', 'title', $flags->{title});
		$t->setvar('music', 'artist', $flags->{artist});
		$t->setvar('music', 'album', $flags->{album});
		$t->setvar('music', 'comment', $flags->{comment});
		$t->setvar('music', 'year', $flags->{year});
		$t->setvar('music', 'track_no', $flags->{track_no});
		$t->setvar('music', 'genre', $flags->{genre});
		$t->set_obj_vars($obj);
		my $template = $self->get_template('ogg', $obj);
		$music .= $t->include($template);
	}
	return $music;
}

sub references
{
	my($self) = @_;
	my $t  = $self->funcLoader->Template;
	my $g  = $t->giza;
	my $u  = $t->user;
	my $db = $t->db;

	my $refs = undef;
	foreach my $obj (@$objs) {
		next if $obj->type ne 'reference';
		my $template = $self->get_template('reference', $obj);
		$t->set_obj_vars($obj);
		$refs .= $t->include($refs);
	}
	return $refs;
}

sub get_template
{
	my($self, $type, $obj) = @_;
	my $t  = $self->funcLoader->Template;
	my $g  = $t->giza;
	my $u  = $t->user;
	my $db = $t->db;
	my $template = $g->config->{template}->{object_defaults}->{$type};
	if($obj->template && $t->getvar('opt:use_custom_templates')) {
		if(not -f $g->config->{global}{template_dir}. '/'. $obj->template) {
			$g->error(sprintf("No such template for objid: %d, objname: %s. template: %s",
				$obj->id, $obj->name, $obj->template
			));
		} else {
			$template = $obj->template;
		}
	}
	return $template;
}

sub storerate
{
	my($self) = @_;
	my $t  = $self->funcLoader->Template;
	my $g  = $t->giza;
	my $u  = $t->user;
	my $db = $t->db;

	if(defined $t->getvar("cgi:rate")) {
		my $c = new Giza::Component(giza=>$g, db=>$db);
		$c->store('Giza::Component::Rate',
			oid 	=> $t->getvar("cgi:oid"),
			rate	=> $t->getvar("cgi:rate")
		);
		return "<h3>Your vote has been saved</h3>";
	}
	return undef;
}

sub saveobject
{
	my($self) = @_;
	my $t  = $self->funcLoader->Template;
	my $g  = $t->giza;
	my $u  = $t->user;
	my $db = $t->db;

	if($t->getvar('cgi:do') eq 'yes') {
		my $o = new Giza::Object(giza=>$g, user=>$u, db=>$db);

		my $owner  = $u->uidbyname($t->getvar('obj:owner'));
		my $groupo = $u->gidbygroup($t->getvar('obj:groupo'));
		
		unless($owner) {	
			$owner = $u->uidbyname($t->getvar('cgi:uname'));
			$owner ||= 1;
		}
		unless($groupo) {
			$groupo = $u->getuid_primary_group($owner);
			$groupo ||= 1;
		}
			
		print STDERR "OWNER: $owner, GROUP: $groupo\n";

		unless($t->getvar('cgi:action') eq 'new') {
			$o->id($t->getvar('cgi:oid'));
		}

		$o->type($t->getvar('obj:type'));
		$o->name($t->getvar('obj:name'));
		$o->keywords($t->getvar('obj:keywords'));
		$o->description($t->getvar('obj:description'));
		$o->data($t->getvar('obj:data'));
		$o->parent($t->getvar('obj:parent'));
		$o->owner($owner);
		$o->groupo($groupo);
		$o->sort($t->getvar('obj:sort'));
		$o->template($t->getvar('obj:template'));
		my $active = $t->getvar('obj:active');
		$active = ($active eq 'on') ? 1 : 0;
		$o->active($active);
		
		my $new_oid;
		if($o->name) {
			$new_oid = $o->save();
		} else {
			if($o->id) {
				$o->delete($o->id);
			}
		}

		if($o->id) {
			my $searchmod = $g->config->{search}{module};
			my $search; eval "
				use $searchmod;
				\$search = ${searchmod}->new(giza=>\$g, user=>\$u, db=>\$db);
			";
			if(ref $search eq $searchmod) {
				$search->update($o);
			}
		}
		undef $o;

		if($g->error) {
			$t->setvar('cgi', 'status', $g->error);
	 	} else {
			if(!$new_oid and defined $o and $o->name) {
				$t->setvar('cgi', 'status', 'Unknown error');
				return undef;
			}
			$t->setvar('cgi', 'status', 'Object saved');
			return undef; #$self->redirect($self->getvar('cgi:referer'));
		}
	}
	return undef;
}

sub reset
{
	my($self) = @_;
	my $t  = $self->funcLoader->Template;
	$t->reset_namespace('obj');
	return undef;
}
	

1;
