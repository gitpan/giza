# ####
# -+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
# Giza::Template::BuiltIn - BuiltIn functions for the Giza template system.
# This file is included from Giza::Template with PiMPx.
#
# (c) 1996-2002 ABC Startsiden AS, see the file AUTHORS.
#
# See the file LICENSE in the Giza top source distribution tree for
# licensing information. If this file is not present you are *not*
# allowed to view, run, copy or change this software or it's sourcecode.
# -+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
#####

sub storeproperties
{
	my($self, $namespace) = @_;

	my $properties = $self->get_obj_flags($self->getvar('obj:data'));
	if(ref $properties eq 'HASH') {
		while(my($property, $value) = each(%$properties)) {
			print STDERR "STOREPROPERTIES $property: $value\n";
			$self->setvar($namespace, $property, $value);
		}
	}
	return undef;
}

sub joinproperties
{
	my($self, $namespace, $intoTemplate, $intoVar) = @_;

	my $var;	
	while(my($property, $value) = each(%{$templatevars{$namespace}})) {
		$value =~ s/\\/\\\\/g;
		$value =~ s/"/\"/g;
		$value =~ s/'/\'/g;
		$var .= "$property \"$value\" ";
	}

	$self->setvar($intoTemplate, $intoVar, $var);

	print STDERR "JOINPROPERTIES: $intoTemplate:$intoVar $var\n";
	
	return undef;
}

sub evar
{
	my($self, $argument) = @_;
	my($namespace, $key) = split ':', $argument;
	return HTML::Entities::encode($templatevars{$namespace}{$key});
}

sub noescapevar
{
	my($self, $argument) = @_;
	my($namespace, $key) = split ':', $argument;
	return $templatevars{$namespace}{$key};
}

sub usevars
{
	my($self, $namespace, @vars) = @_;

	foreach my $var (@vars) {
		$self->usevar("$namespace:$var");
	}
	return undef;
}

sub clearvalue
{
	my($self, $argument) = @_;
	my($namespace, $key) = split ':', $argument;
	undef $templatevars{$namespace}{$key};
}

sub usevar
{
	my($self, $argument) = @_;
	my $cgi = $self->cgi;
	my($namespace, $key) = split ':', $argument;

	#%ifdef DEBUG
	confess "missing argument to usevar(): string argument"
		unless $argument;
	#%endif
	
	if(defined $cgi) {
		if($cgi->param($key)) {
			$self->setvar($namespace, $key, $cgi->param($key));
		}
	}
	return undef;
}

sub requirevar
{
	my($self, $argument) = @_;
	my $g = $self->giza;
	$self->usevar($argument);

	#%ifdef DEBUG
	confess "missing argument to requirevar(): string argument"
		unless $argument;
	#%endif

	unless($self->getvar($argument)) {
		$self->setvar("giza", "error", "Missing required argument: $argument");
		if(defined $g->config->{template}{error}) {
			print STDOUT $self->include($g->config->{template}{error});
			Giza::Template::exit();
		}
	}
	return undef;
}

sub useobject 
{
	my($self, $argument) = @_;
	my $u = $self->user;

	my $o = new Giza::Object(giza=>$self->giza, db=>$self->db, user=>$u);
	if($self->getvar('opt:dont_recurse_refs')) {
		$o->dont_recurse_refs;
	}
	my $owner  = $u->uidbyname($self->getvar('obj:owner'));
	my $groupo = $u->gidbygroup($self->getvar('obj:groupo'));
	$o->type($self->getvar('obj:type'));
	$o->name($self->getvar('obj:name'));
	$o->keywords($self->getvar('obj:keywords'));
	$o->description($self->getvar('obj:description'));
	$o->data($self->getvar('obj:data'));
	$o->parent($self->getvar('obj:parent'));
	$o->owner($owner);
	$o->groupo($groupo);
	$o->sort($self->getvar('obj:sort'));
	$o->template($self->getvar('obj:template'));
	$o->active($self->getvar('obj:active'));
	if($argument) {
		$o->no_cache if $self->getvar('opt:no_object_cache');
		my $new_o = $o->fetch(Id => $argument);
		$self->set_obj_vars($new_o);
		return undef;
	} else {
		$o->set_defaults();
		$o->active($self->getvar('obj:active'));
		unless($self->getvar('obj:owner')) {
			my $session = $u->session_open($self->getvar('cgi:sid'));
			$self->setvar('obj', 'owner', $session->{uname});
			$owner  = $u->uidbyname($self->getvar('obj:owner'));
			$o->owner($owner);
		}
		$self->set_obj_vars($o);
		undef $o;
		return undef;
	}
}	

sub defaultvalue
{
	my($self, @argv) = @_;
	my($expression, $value) = @argv;
	my($namespace, $var) = split ':', $expression, 2;


	unless(defined $self->getvar($expression)) {
		$self->setvar($namespace, $var, $value);
	}

	return undef;
}

sub cut
{
	undef;
}

sub time_elapsed
{
	my($self) = @_;
	#%ifdef HAVE_TIME__HIRES
	#%  print return tv_interval($TIME_START, [gettimeofday]);
	#%else
	return undef
	#%endif
}

sub print
{
	my($self, @argv) = @_;
	return join(" ", @argv);
}


sub header
{
	my($self, $header) = @_;
	my $cgi = $self->cgi;
	$header ||= $cgi->header(-cookie=>[@cookies]);
	return undef if $NEVER_SEND_HEADER;
	return("$header\n\n") 
}

sub setcookie
{
	my($self, $key, $value) = @_;
	unless($value) {
		if(index($key, " ") != -1) {
			($key, $value) =~ split /\s+/, $key, 2;
		}
	}

	#%ifdef DEBUG
	$self->giza->log("SETTING COOKIE: key:'$key', value:'$value'\n");
	#%endif

	push(@cookies, new CGI::Cookie(-name=>$key, -value=>$value));
	return undef;
}

sub usecookie
{
	my($self, $key) = @_;
	my %cookies = fetch CGI::Cookie;
	if(defined $cookies{$key}) {
		$self->setvar('cgi', $key, $cookies{$key}->value);
	}
	undef %cookies;
	return undef;
}

sub getsession
{
	my($self) = @_;

	$self->usevar("cgi:uname");
	$self->usevar("cgi:pw");
	$self->usevar("cgi:sid");
	
	unless($self->getvar("cgi:sid")) {
		$self->usecookie("sid");
	}
	unless($self->getvar("cgi:pw")) {
		$self->usecookie("pw");
	}
	return undef;
}

sub If
{
	my($self, @argv) = @_;
	my $expr = shift @argv;
	my $status = 1 if $expr;
	if($status) {
		return $self->Print(@argv);
	} else {
		return undef
	}
}

sub ifInclude
{
	my($self, @argv) = @_;
	my($expr, $include) = @argv;
	my $status = 1 if $expr;
	if($status) {
		return $self->include($include);
	} else {
		return undef;
	}
}

sub Print
{
	my($self, @argv) = @_;
	return join " ", @argv;
}

sub redirect
{
	my($self, $page) = @_;
	return("Location: $page\n\n");
}

sub logout {
	my($self) = @_;
	my $sid = $self->getvar("cgi:sid");
	$self->user->session_delete($sid);
	return undef;
}

sub login
{
	my($self) = @_;
	my $g  = $self->giza;
	my $db = $self->db;
	my $u  = $self->user;
	my $c  = $g->config;

	# ### Print the login screen if access is denied.
	sub loginpage {
		$self->setcookie('sid', '');
		print STDOUT $self->include($c->{template}{login});
		Giza::Template::exit();
	}

	# ### get http vars.
	my $sid		= $self->getvar("cgi:sid");
	my $uname 	= $self->getvar("cgi:uname");
	my $pw		= $self->getvar("cgi:pw");

	# ### does she have what it takes?
	unless($uname or $sid) {
		$self->setvar("cgi", "status", "Missing username");
		loginpage();
	}
	unless($pw) {
		$self->setvar("cgi", "status", "Missing password");
		loginpage();
	}

	# ### get existing session if any
	if($sid) {
		my $session = $u->session_open($sid);
		$uname = $session->{uname};
		$self->setvar('cgi', 'uname', $uname);
		$pw = $u->session_decrypt($sid, $pw);
		unless($u->session_update($sid)) {
			$self->setvar("cgi", "status", "Non-existing or expired session. Please relogin");
			loginpage();
		}
	}

	# ### compare passwords
	unless($u->login($uname, $pw)) {
		$self->setvar("cgi", "status", "Login incorrect");
		loginpage()
	}

	# ### unless no session, save a new.	
	unless($sid) {
		unless($sid = $u->session_save($uname, $ENV{REMOTE_ADDR})) {
			$self->setvar("cgi", "status", "Couldn't save session");
			loginpage();
		}
		$self->setvar("cgi", "sid", $sid);
		$self->setvar("cgi", "pw",  $u->session_encrypt($sid, $pw));
	}

	$u->uname($uname);
	$self->setcookie('sid', $self->getvar("cgi:sid"));
	$self->setcookie('pw',  $self->getvar("cgi:pw"));
	return undef;
}

sub expr_to_path
{
	my($expr) = @_;
	$expr =~ tr/ /_/;
	$expr = lc $expr;
	$expr = join('/', split('::', $expr));
	return $expr;
}

sub set
{
	my($self, $arg) = @_;
	my($namespace, $key) = split(':', $arg, 2);
	$self->setvar($namespace, $key, 1);
	return undef;
}

sub unset
{
	my($self, $arg) = @_;
	my($namespace, $key) = split(':', $arg, 2);
	$self->setvar($namespace, $key, 0);
	return undef;
}
