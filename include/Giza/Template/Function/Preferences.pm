#!/usr/bin/perl -w

package Giza::Template::Function::Preferences;
use strict;

my @functions = qw(
	fetch save
);

sub new
{
	my($pkg, $funcLoader) = @_;
	my $self = {};
	bless $self, $pkg;
	$self->funcLoader($funcLoader);
	return $self;
}

sub funcLoader
{
	my($self, $funcLoader) = @_;
	$self->{FUNCLOADER} = $funcLoader 
		if defined $funcLoader;
	return $self->{FUNCLOADER};
}

sub register
{
	my($self) = @_;
	$self->funcLoader->register_class('preferences', $self);
	foreach my $function (@functions) {
		$self->funcLoader->register_function($function);
	}
}

sub fetch
{
	my($self, $uname) = @_;	
	my $t  = $self->funcLoader->Template;
	my $g  = $t->giza;
	my $u  = $t->user;
	my $db = $t->db;

	my $uid = $u->uidbyname($uname);

	my $query = qq{
		SELECT * FROM preferences WHERE id=$uid
	};

	my $hres = $db->fetchonerow_hash($query);

	
	unless(ref $hres eq 'HASH') {
		$hres->{cat_view}			= 'detailed';
		$hres->{cat_sort}			= 'name';
		$hres->{userlevel}			= 'novice';
		$hres->{cat_active}			= 'on';
		$hres->{cat_recommended}	= 'off';
		$hres->{notepad}			= undef;
		$t->setvar('prefs', 'have_prefs', 'no');
	} else {
		$t->setvar('prefs', 'have_prefs', 'yes');
	}
	
	while(my($setting, $value) = each(%$hres)) {
		$t->setvar('prefs', $setting, $value);
	}

	if($hres->{cat_view} eq 'normal') {
		$t->setvar('prefs', 'flag_cat_view_normal', '"normal" selected="selected"');
		$t->setvar('prefs', 'flag_cat_view_list', '"list"');
		$t->setvar('prefs', 'flag_cat_view_detailed', '"detailed"');
	}
	elsif($hres->{cat_view} eq 'list') {
		$t->setvar('prefs', 'flag_cat_view_normal', '"normal"');
		$t->setvar('prefs', 'flag_cat_view_list', '"list" selected="selected"');
		$t->setvar('prefs', 'flag_cat_view_detailed', '"detailed"');
	}
	elsif($hres->{cat_view} eq 'detailed') {
		$t->setvar('prefs', 'flag_cat_view_normal', '"normal"');
		$t->setvar('prefs', 'flag_cat_view_list', '"list"');
		$t->setvar('prefs', 'flag_cat_view_detailed', '"detailed" selected="selected"');
	}

	if($hres->{cat_sort} eq 'name') {
		$t->setvar('prefs', 'flag_cat_sort_name', '"name" selected="selected"');
		$t->setvar('prefs', 'flag_cat_sort_changed', '"changed"');
		$t->setvar('prefs', 'flag_cat_sort_type', '"type"');
		$t->setvar('prefs', 'flag_cat_sort_id', '"id"');
	}
	elsif($hres->{cat_sort} eq 'changed') {
		$t->setvar('prefs', 'flag_cat_sort_name', '"name"');
		$t->setvar('prefs', 'flag_cat_sort_changed', '"changed" selected="selected"');
		$t->setvar('prefs', 'flag_cat_sort_type', '"type"');
		$t->setvar('prefs', 'flag_cat_sort_id', '"id"');
	}
	elsif($hres->{cat_sort} eq 'type') {
		$t->setvar('prefs', 'flag_cat_sort_name', '"name"');
		$t->setvar('prefs', 'flag_cat_sort_changed', '"changed"');
		$t->setvar('prefs', 'flag_cat_sort_type', '"type" selected="selected"');
		$t->setvar('prefs', 'flag_cat_sort_id', '"id"');
	}
	elsif($hres->{cat_sort} eq 'id') {
		$t->setvar('prefs', 'flag_cat_sort_name', '"name"');
		$t->setvar('prefs', 'flag_cat_sort_changed', '"changed"');
		$t->setvar('prefs', 'flag_cat_sort_type', '"type"');
		$t->setvar('prefs', 'flag_cat_sort_id', '"id" selected="selected"');
	}

	if($hres->{cat_active} eq 'on') {
		$t->defaultvalue('obj:active', 1);
		$t->setvar('prefs', 'flag_active_on', '"on" selected="selected"');
		$t->setvar('prefs', 'flag_active_off', '"off"');
	}
	elsif($hres->{cat_active} eq 'off') {
		$t->defaultvalue('obj:active', 0);
		$t->setvar('prefs', 'flag_active_on', '"on"');
		$t->setvar('prefs', 'flag_active_off', '"off" selected="selected"');
	}
	
	if($hres->{cat_recommended} eq 'on') {
		$t->defaultvalue('obj:recommended', 1);
		$t->setvar('prefs', 'flag_recommended_on', '"on" selected="selected"');
		$t->setvar('prefs', 'flag_recommended_off', '"off"');
	}
	elsif($hres->{cat_recommended} eq 'off') {
		$t->defaultvalue('obj:recommended', 0);
		$t->setvar('prefs', 'flag_recommended_on', '"on"');
		$t->setvar('prefs', 'flag_recommended_off', '"off" selected="selected"');
	}

	if($hres->{userlevel} eq 'novice') {
		$t->setvar('prefs', 'flag_userlevel_novice', '"novice" selected="selected"');
		$t->setvar('prefs', 'flag_userlevel_intermediate', '"intermediate"');
		$t->setvar('prefs', 'flag_userlevel_expert', '"expert"');
	}
	elsif($hres->{userlevel} eq 'intermediate') {
		$t->setvar('prefs', 'flag_userlevel_novice', '"novice"');
		$t->setvar('prefs', 'flag_userlevel_intermediate', '"intermediate" selected="selected"');
		$t->setvar('prefs', 'flag_userlevel_expert', '"expert"');
	}
	elsif($hres->{userlevel} eq 'expert') {
		$t->setvar('prefs', 'flag_userlevel_novice', '"novice"');
		$t->setvar('prefs', 'flag_userlevel_intermediate', '"intermediate"');
		$t->setvar('prefs', 'flag_userlevel_expert', '"expert" selected="selected"');
	}

	$t->setvar('prefs', 'notepad', $hres->{notepad});


	return undef;
	
}

sub save
{
	my($self, $uname) = @_;	
	my $t  = $self->funcLoader->Template;
	my $g  = $t->giza;
	my $u  = $t->user;
	my $db = $t->db;

	return undef unless $t->getvar('cgi:do') eq 'yes';

	my $uid = $u->uidbyname($uname);

	my $cat_view		= $t->getvar("prefs:cat_view");
	my $cat_sort		= $t->getvar("prefs:cat_sort");
	my $userlevel		= $t->getvar("prefs:userlevel");
	my $cat_active		= $t->getvar("prefs:cat_active");
	my $cat_recommended	= $t->getvar("prefs:cat_recommended");
	my $notepad			= $t->getvar("prefs:notepad");

	my $query;
	if($db->fetchonerow_hash(qq{SELECT id FROM preferences WHERE id=$uid})) {
		$query = qq{
			UPDATE preferences SET
				cat_view='$cat_view',
				cat_sort='$cat_sort',
				userlevel='$userlevel',
				cat_active='$cat_active',
				cat_recommended='$cat_recommended',
				notepad='$notepad'
			WHERE id=$uid
		};
	} else {
		$query = qq{
			INSERT INTO preferences VALUES(
				$uid, '$cat_view', '$cat_sort',
				'$userlevel', '$cat_active', '$cat_recommended',
				'$notepad'
			);
		};
	}

	$db->exec_query($query);
	return undef;
}		

=comment
	CREATE TABLE preferences (
	id			BIGINT			NOT NULL,
	cat_view	VARCHAR(255),
	cat_sort	VARCHAR(255),
	userlevel	VARCHAR(255)	DEFAULT 'novice',
	cat_active  INT				NOT NULL DEFAULT 1,
	cat_recommended INT			NOT NULL DEFAULT 0,
	notepad		TEXT
=cut

1;
	
