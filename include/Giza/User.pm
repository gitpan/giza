#!/usr/bin/perl
# -+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
# Giza/User.pm - Giza user interface
# (c) 1996-2002 ABC Startsiden AS, see the file AUTHORS.
#
# See the file LICENSE in the Giza top source distribution tree for
# licensing information. If this file is not present you are *not*
# allowed to view, run, copy or change this software or it's sourcecode.
# -+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
#####

#%include <config.pimpx>

#%ifdef PREFIX
#%  define INCLUDE "%{PREFIX}/include"
#%endif

#%print use lib '%{INCLUDE}';


package Giza::User;
# ------------------------------------------------------------------ #

use strict;
use Giza;
use Giza::User::SDB;
use Carp;
use DB_File;
use Fcntl qw(:flock);
use Crypt::PasswdMD5;
use Crypt::CBCeasy;
use FileHandle;
use Exporter;
use vars qw(
	@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $SESSION_EXPIRE
);

=comment
Confusion will be my epitaph.
As I crawl a cracked and broken path.
If we make it we can all sit back
and laugh.
But I fear tomorrow I'll be crying.
Yes I fear tomorrow I'll be crying.
=cut

# Export variables and constants to parent namespace.
# ------------------------------------------------------------------ #

@ISA = qw(Exporter);

@EXPORT = qw(
	GZ_IREAD GZ_IWRITE GZ_IEXEC GZ_IRUSR GZ_IWUSR GZ_IXUSR
	GZ_IRWXU GZ_IRGRP GZ_IWGRP GZ_IXGRP GZ_IRWXG GZ_IROTH
	GZ_IWOTH GZ_IXOTH GZ_IRWXO R_OK W_OK X_OK ENOENT
	$SESSION_EXPIRE
);

# ## permissions
sub GZ_IREAD	{0400}
sub GZ_IWRITE	{0200}
sub GZ_IEXEC	{0100}

# ### User permissions
sub GZ_IRUSR	{GZ_IREAD}
sub GZ_IWUSR	{GZ_IWRITE}
sub GZ_IXUSR	{GZ_IEXEC}
sub GZ_IRWXU	{GZ_IREAD|GZ_IWRITE|GZ_IEXEC}

# ### Group permissions
sub GZ_IRGRP	{GZ_IRUSR >> 3}
sub GZ_IWGRP	{GZ_IWUSR >> 3}
sub GZ_IXGRP	{GZ_IXUSR >> 3}
sub GZ_IRWXG	{GZ_IRWXU >> 3}

# ### Other permissions
sub GZ_IROTH	{GZ_IRGRP >> 3}
sub GZ_IWOTH	{GZ_IWGRP >> 3}
sub GZ_IXOTH	{GZ_IXGRP >> 3}
sub GZ_IRWXO	{GZ_IRWXG >> 3}

sub ENOENT		{-100}

$SESSION_EXPIRE = 1800;

sub R_OK {4};
sub W_OK {2};
sub X_OK {1};

# Constructor
# ------------------------------------------------------------------ #

# ### Giza new(void)
# Create a new Giza object. Will parse
# and save configuration in $obj->config.
#
sub new
{
	my($self, %argv) = @_;
	my $obj = {};
	bless $obj, 'Giza::User';
	$obj->giza($argv{giza});
	$obj->db($argv{db});
	return $obj;
}

# Methods
# ------------------------------------------------------------------ #

sub giza
{
	my($self, $giza) = @_;
	$self->{GIZA} = $giza if defined $giza;
	return $self->{GIZA};
}

sub db
{
	my($self, $db) = @_;
	$self->{DB} = $db if defined $db;
	return $self->{DB};
}

sub uname
{
	my($self, $uname) = @_;
	$self->{UNAME} = $uname if defined $uname;
	return $self->{UNAME};
}

sub getobjmode
{
	my($self, $oid) = @_;
	my $db = $self->db;

	#%ifdef DEBUG
	confess "don't have db object: $db" unless ref $db;
	#%endif

	my $query = qq{SELECT owner,groupo,mode FROM catalog WHERE id=$oid};
	my $objmode = $db->fetchonerow_hash($query);
	return $objmode;
}

sub access
{
	my($self, $oid, $mode) = @_;
	my $granted = 0;

	return TRUE;

	return FALSE unless $self->uname;
	my $uid = $self->uidbyname($self->uname);

	my $objmode = $self->getobjmode($oid);
	my $xmode   = $objmode->{mode};
	my $xowner	= $objmode->{owner};

	$mode &= (X_OK|W_OK|R_OK); # Clean up bogus bits.

	# ### Superuser has access to everything.
	if($uid == 0 && (($mode & X_OK) == 0 || ($xmode & (GZ_IXUSR|GZ_IXGRP|GZ_IXOTH)))) {
		return TRUE;
	}

	if($uid == $xowner) {
		$granted = ($xmode & ($xmode << 6)) >> 6;
	}
	elsif($self->user_is_in_group($self->uname, $objmode->{group})) {
		$granted = ($xmode & ($xmode << 3)) >> 3;
	}
	else {
		$granted = ($xmode & $mode);
	}

	if($granted == $mode) {
		return TRUE;
	}
	return FALSE;
}
	
sub user_is_in_group
{
	my($self, $user, $group) = @_;
	return FALSE;
}	

sub uidbyname
{
	my($self, $user) = @_;
	my $g  = $self->giza;
	my $db = $self->db;

	my $uid = $db->fetch_singlevar("SELECT id FROM users WHERE username='$user' LIMIT 1");
	return ($uid >= 0 ? $uid : ENOENT);
}

sub gidbygroup
{
	my($self, $group) = @_;
	my $g  = $self->giza;
	my $db = $self->db;

	my $gid = $db->fetch_singlevar("SELECT id FROM groups WHERE name='$group' LIMIT 1");
	return ($gid >= 0 ? $gid : ENOENT);
}
 

sub namebyuid
{
	my($self, $uid) = @_;
	my $g  = $self->giza;
	my $db = $self->db;

	my $uname = $db->fetch_singlevar("SELECT username FROM users WHERE id=$uid LIMIT 1");
	return ($uname ? $uname : ENOENT);
}

sub groupbygid
{
	my($self, $gid) = @_;
	my $g  = $self->giza;
	my $db = $self->db;

	my $group = $db->fetch_singlevar("SELECT name FROM groups WHERE id=$gid LIMIT 1");
 	return ($group ? $group : ENOENT);
}

sub getuid_groups
{
	my($self, $uid) = @_;
	my $g  = $self->giza;
	my $db = $self->db;

	my $groupent = $db->fetch_singlevar("SELECT groups FROM users WHERE id=$uid");
	my $groups = $self->parse_groupent($groupent);
	return $groups;
}

sub getuser_groups
{
	my($self, $user) = @_;
	my $uid = $self->uidbyname($user);
	return $self->getuid_groups($uid);
}

sub parse_groupent
{
	my($self, $groupent) = @_;
	my @groups = split(':', $groupent);
	return \@groups;
}

sub getuser_primary_group
{
	my($self, $username) = @_;
	my $groups = $self->getuser_groups($username);
	return shift @$groups;
}

sub getuid_primary_group
{
	my($self, $uid) = @_;
	my $groups = $self->getuid_groups($uid);
	return shift @$groups;
}

sub session_open
{
	my($self, $id) = @_;
	my $g = $self->giza;
	my $c = $g->config;

	my $sdb = new Giza::User::SDB(giza=>$g);
	$sdb->open or return FALSE;
	
	unless(defined $sdb->content->{$id}) {
		$g->error("No such session id: $id");
		$sdb->close();
		return FALSE;
	}

	my($uname, $salt, $addr, $time_start, $time_expire)
		= split /:/, $sdb->content->{$id};

	$sdb->close;
	
	if(time > $time_expire) {
		$g->error("Session has expired: $id");
		$self->session_delete($id);
		return FALSE;
	}

	return {
		uname 	=> $uname,
		salt  	=> $salt,
		addr	=> $addr,
		start	=> $time_start,
		expire	=> $time_expire
	};
}

sub session_update 
{
	my($self, $id) = @_;
	my $g = $self->giza;
	my $c = $g->config;

	my $sdb = new Giza::User::SDB(giza=>$g);
	$sdb->open or return FALSE;

	unless(defined $sdb->content->{$id}) {
		$g->error("No such session id: $id");
		$sdb->close();
		return FALSE;
	}

	my($uname, $salt, $addr, $time_start, $time_expire)
		= split /:/, $sdb->content->{$id};
	$time_expire = time + $SESSION_EXPIRE;
	$sdb->content->{$id} = join(':', $uname, $salt, $addr, $time_start, $time_expire);

	$sdb->close;
	
	return TRUE;
}

sub session_save
{
	my($self, $uname, $addr) = @_;
	my $g = $self->giza;
	my $c = $g->config;

	my $sdb = new Giza::User::SDB(giza=>$g);
	$sdb->open or return FALSE;

	my $id = 1;
	while(exists $sdb->content->{$id}) {
		$id++;
	}

	my $time_start	= time;
	my $time_expire	= time + $SESSION_EXPIRE;
	my $salt		= Giza::mkpasswd(8);
	$sdb->content->{$id} = join(':', $uname, $salt, $addr, $time_start, $time_expire);

	$sdb->close;
	
	return $id;
}

sub session_delete
{
	my($self, $id) = @_;
	my $g = $self->giza;
	my $c = $g->config;

	my $sdb = new Giza::User::SDB(giza=>$g);
	$sdb->open or return FALSE;

	unless(exists $sdb->content->{$id}) {
		$g->error("No such session id: $id");
		$sdb->close;
		return FALSE;
	}
	
	delete $sdb->content->{$id};

	$sdb->close;

	return TRUE;
}

sub session_encrypt
{
	my($self, $sid, $text) = @_;
	my $session = $self->session_open($sid) or return FALSE;
	my $cryptpw = unpack("H*", Blowfish::encipher($session->{salt}, $text));
	return $cryptpw;
}

sub session_decrypt
{
	my($self, $sid, $text) = @_;
	my $session = $self->session_open($sid) or return FALSE;
	my $plaintext = Blowfish::decipher($session->{salt}, pack("H*", $text));
	return $plaintext;
}

sub encrypt
{
	my($self, $password) = @_;
	my $salt 	= Giza::mkpasswd(8);
	my $cryptpw	= $salt. unix_md5_crypt($password, $salt);
	return $cryptpw;
}

sub passwdcmp
{
	my($self, $passwd, $cryptpw) = @_;
	my $salt = substr($cryptpw, 0, 8);
	$cryptpw = substr($cryptpw, 8, length $cryptpw);

	$passwd = unix_md5_crypt($passwd, $salt);

	if(strcmp($passwd, $cryptpw)) {
		return TRUE;
	} else {
		return FALSE;
	}
}	

sub login
{
	my($self, $username, $password) = @_;
	my $g	= $self->giza;
	my $db	= $self->db;

	my $cryptpw = $db->fetch_singlevar("SELECT password FROM users WHERE username='$username'");
	unless($cryptpw) {
		$g->error("No such username or no password set for user: $username");
		return FALSE;
	}

	if($self->passwdcmp($password, $cryptpw)) {
		return TRUE;
	} else {
		return FALSE;
	}
}
	
1
__END__
