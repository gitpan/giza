#!/usr/bin/perl
# -+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
# Giza::Template - An interface to the Giza templates
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

package Giza::Template;
use strict;
use Giza;
use Fcntl;
use Giza::User;
use Class::Struct;
use CGI::Cookie;
use CGI;
use HTML::Entities ();
use Exporter;
use Carp;
use Religion;
use vars qw(
	%cache_scheme %cache_memshare $TIME_START
); 

my $NEVER_SEND_HEADER = 0;

#%ifdef HAVE_TIME__HIRES
#%print use Time::HiRes qw(gettimeofday tv_interval);
#%endif

%cache_scheme = (
	memshare => [ \&cache_save_memshare, \&cache_restore_memshare ],
);

# ----------------------------------------------------------------- #

# ###
# These are the variables that are accessible
# from the templates trough getvar.
my %templatevars = ();
my @cookies = ();

my %BuiltIn = (
	include				=> 'Giza::Template',
	getvar				=> 'Giza::Template',
	function			=> 'Giza::Template',
	"exit"				=> 'Giza::Template',

	storeproperties		=> 'Giza::Template::BuiltIn',
	joinproperties		=> 'Giza::Template::BuiltIn',
	evar				=> 'Giza::Template::BuiltIn', 
	noescapevar			=> 'Giza::Template::BuiltIn', 
	usevar				=> 'Giza::Template::BuiltIn', 
	usevars				=> 'Giza::Template::BuiltIn',
	requirevar			=> 'Giza::Template::BuiltIn', 
	useobject			=> 'Giza::Template::BuiltIn', 
	defaultvalue		=> 'Giza::Template::BuiltIn', 
	cut					=> 'Giza::Template::BuiltIn', 
	time_elapsed		=> 'Giza::Template::BuiltIn', 
	Print				=> 'Giza::Template::BuiltIn', 
	redirect			=> 'Giza::Template::BuiltIn', 
	login				=> 'Giza::Template::BuiltIn', 
	logout				=> 'Giza::Template::BuiltIn', 
	expr_to_path		=> 'Giza::Template::BuiltIn', 
	set					=> 'Giza::Template::BuiltIn', 
	unset				=> 'Giza::Template::BuiltIn', 
	clearvalue			=> 'Giza::Template::BuiltIn',
);

my %Alias = (
	"exec"		=> 'function',
	'if'		=> 'If',
	comment		=> 'cut',
	rem			=> 'cut',
	uv			=> 'usevar',
	nev			=> 'noescapevar',
	ev			=> 'evar',
	escapevar	=> 'evar',
	sp			=> 'storeproperties',
	pstore		=> 'storeproperties',
	jv			=> 'joinproperties',
	pjoin		=> 'joinproperties',
	rv			=> 'requirevar',
	'uc'		=> 'usecookie',
	sc			=> 'setcookie',
	dv			=> 'defaultvalue',
	cv			=> 'clearvalue',
);
	

# ----------------------------------------------------------------- #

struct(
	giza	=> '$', # the giza object.
	user	=> '$',	# giza user object.
	db		=> '$', # the database object.
	cgi		=> '$',	# CGI object.
	parent	=> '$', # parent id.
	page	=> '$',	# current page.
	funcloader => '$'
);

# ### string do(Giza::Template template, string filename)
# Execute a template file and return the translated
# file.
#
sub do($$)
{ 	
	my($self, $file) = @_;
	#%ifdef HAVE_TIME__HIRES
	#%print $TIME_START = [gettimeofday];
	#%endif
	$self->initvars();

	my $funcloader = Giza::Template::FuncLoader->new($self);
	my $modules = $self->giza->config->{template}{functions}{module};
	foreach my $module (@$modules) {
		my $m = $funcloader->load($module);
		if(ref $m eq $module) {
			$m->register();
		} else {
			$self->giza->error($@) if $@;
		}
	}
	$self->funcloader($funcloader);
	my $ret = $self->include($file);
	destroy_vars();
	return $ret;
}

# ### string include(Giza::Template template, string filename)
# Search a file for <? ?> html tags and execute it contents,
# if it's valid Giza::Template syntax and replace the tags
# with the return value of the given function.
# 
# But these are identified and executed by parse(), so keep on reading,
# this is simple, you'll probably get it soon :-)
# 
#
sub include($$)
{
	my($self, $file) = @_;
	my $g  = $self->giza;
	my $db = $self->db;
	my $config = $g->config;

	confess "missing argument to include(): string filename"
		unless $file;

	# add the prefix if this is a relative pathname.
	unless(substr($file, 0, 1) eq '/') {
		$file = $config->{global}{template_dir}. '/'. $file;
	}

	###
	# try to fetch a cached version of the template.
	# if there is none, slurp the file into $template and
	# store a cache key.
	my $template = cache_restore_memshare($file);
	unless($template) {
		my $fh = $g->safeopen($file, O_RDONLY);
		unless($fh) {
			# woops. we couldn't open the file for some reason.
			# the error of the sysopen call is in $g->error, so return a web page.
			print STDOUT $self->header, sprintf('<div class="error">'.$g->error.'</div>');
			$self->exit;
		}

		{ # slurp the file into $template.
			local $/ = undef; # $/ == $INPUT_RECORD_SEPARATOR
			$template = <$fh>;
		}
		close $fh;

		cache_save_memshare($file, $template);
	}

	# ###
	# get the text between <? ?> lines and 
	# replace it with the return value of parse(text).
	#
	$template =~ s/\<\?(.+?)\s*\?>\s*/$self->parse($1)/gsex;

	return $template;
}

# ### string parse(Giza::Template template, string expression);
# OK: Now we've got the contents of a <? ?> tag.
#     In the "giza template language" the tag should consist
#	  of a function-name and an argument separated by whitespace.
#
#	  So what we do is just pass the argument to the equalivent
#	  function. Not by eval() ofcourse but "manually" since
#	  we want to restrict what functions are availible.
#
#	  This is the mini-language type of a template,
#	  and should be much faster than inline perl code.
#	  Actually it's faster than mini-language, since
#	  this templating system doesn't have any control-flow
#	  like if/for/while etc, so we don't need to build a
#	  parse tree.
#
sub parse
{
	my($self, $expression) = @_;
	
	#%ifdef DEBUG
	confess "missing argument to parse(): string expression"
		unless $expression;
	#%endif

	# get the arguments.
	my @argv = $self->parseline($expression);
	my $cmd = shift @argv; # first argument is the command.

	# ### 
	# find the command in the list of BuiltIn commands,
	# if it's not there, try to find it in the Alias list.
	#
	unless($BuiltIn{$cmd}) {
		if($Alias{$cmd}) {
			$cmd = $Alias{$cmd};
		}
	}

	# ###
	# Check if this method exists in our class,
	# if so execute it with the given arguments.
	#
	if($self->can($cmd)) {
		$self->$cmd(@argv);
	} else {
		print STDERR "Couldn't execute $cmd\n";
		# just leave the tag intact if the command doesn't exist.
		return "<?$expression ?>";
	}
}

# ### array parseline(Giza::Template template, string line)
# Shell-like argument parser.
#
sub parseline
{
	my($self, $line) = @_;
	
	#### +++ <Pre Formatting> +++ ####

	# ###
	# Expand all occurrences of ${namespace:variable} into
	# the content of $templatevars{$namespace}{$variable}.
	# 
	$line = $self->expand_vars($line);

	# ###
	# Decode HTML Entities.
	#
	$line = HTML::Entities::decode_entities($line);

	# ###
	# Replace unwanted \tabs and \newlines with a single space.
	#
	$line =~ tr/\t/ /;
	$line =~ tr/\n/ /;


	#### +++ <Variable Declarations> +++ ####

	my $iwq = 0;	# (in weak quote)
	my $ipq = 0;	# (in power quote)
	my $ibq = 0;	# (in back quote)
	my $ib  = 0;	# (in evalution block)
	my $lcw = 0;	# (last character was white space)
	
	my @argv = ();	# final set of arguments
	my $argc = 0;	# current number of arguments

	#### +++ <Main Stream Parser> +++ ####

	foreach my $chr (split //, $line) {
		if($chr eq '"') { # this is a weak quote.
			unless($ibq||$ib||$ipq) {
				# ###
				# if we're neither in a back quote, block nor power quote
				# we're either starting or ending a weak quote.
				$iwq = $iwq ? 0 : 1; next;
			}
		}
		elsif($chr eq "'") { # this is a power quote.
			unless($ibq||$ib||$iwq) {
				# ###
				# if we're neither in a backquote, block nor weak quote
				# we're either starting or ending a power quote.
				$ipq = $ipq ? 0 : 1; next;
			}
		}
		elsif($chr eq '\\') { # this is a back quote.
				# ###
				# Unless we're in a powerquote or already in a backquote,
				# the next character in the stream should be quoted.
			$ibq=1, next unless $ipq||$ibq;
		}
		elsif($chr eq '{') {
			unless($ibq||$ib||$iwq||$ipq) {
				# ###
				# Unless we're in a back quote, block, power or weak quote
				# We're now in an evaluation block.
				$ib=1, next;
			}
		}
		elsif($chr eq '}') {
			if($ib==1) {
				# ###
				# if we're in an evalution block, the block is now ending,
				# and we should eval the current contents of the block and
				# store it in the current argument element.
				$argv[$argc] = eval($argv[$argc]);
				$ib=0, next;
			}
		}
		elsif($chr eq ' ') { 
			# ###
			# we hit a white space actually.
			# this is usually our argument separator...
			unless($ibq||$ib||$iwq||$ipq) {
				# ###
				# ... unless we're in a backquote, block, weak quote
				# or power quote.

				# ###
				# Two white space characters in a row, does not mean
				# we have two arguments. If the last character we saw was
				# also a whitespace, we skip this. Else we store this as
				# the final argument and update the argument count.
				#
				unless($lcw) {
					$argc++, $lcw=1, next;
				} else {
					next;
				}
			}
		} else {
			$lcw=0;
		}
	
		# ###
		# if we were in a back quote, this character was
		# saved as it is.
		$ib=0 if $ibq;
	
		$argv[$argc] .= $chr;
	}
	return @argv;
}


# ### void *function(Giza::Template template, @arguments)
# Execute an outside-function using the Giza::Template::FuncLoader
# interface. See the documentation for Giza::Template::FuncLoader for
# more details.
#
sub function
{
	my($self, @argv) = @_;
	my $g = $self->giza;
	my $u = $self->user;
	my $db = $self->db;
	my($namespace, $function) = split ':', shift @argv, 2;

	$self->funcloader->exec($namespace, $function, @argv);
}

# ### void never_send_header(void)
# Sets the NEVER_SEND_HEADER option.
# If this option is set, the header() function won't send
# HTTP headers. Might be useful when rendering static pages :-)
#
sub never_send_header
{
	$NEVER_SEND_HEADER = 1;
}

# ----------------------------------------------------------------- #

# ### int setvar(Giza::Template template, string namespace, string value)
# Set a variable in the templatevar hash.
#
sub setvar
{
	my($self, $namespace, $key, $value) = @_;
	if(defined $namespace and defined $key) {
		$templatevars{$namespace}{$key} = $value;
	}
	return TRUE;
}

# ### string getvar(Giza::Template template, string 'namespace:var')
# Get a variable in the templatevars hash.
#
sub getvar {
	my($self, $argument) = @_;
	my($namespace, $key) = split ':', $argument;

	#%ifdef DEBUG
	confess "missing argument to getvar(): string argument"
		unless $argument;

	unless(defined $templatevars{$namespace}) {
		$self->giza->warning("getvar($argument): No such namespace: $namespace");
		return undef;
	}
	unless(defined $templatevars{$namespace}{$key}) {
		$self->giza->warning("getvar($argument): No such var '$key' in namespace '$namespace')");
		return undef;
	}
	#%endif


	return $templatevars{$namespace}{$key}; 
}

# ### void reset_namespace(Giza::Template template, string namespace)
# Clear an entire namespace. Delete all keys/values.
#
sub reset_namespace
{
	my($self, $namespace) = @_;
	if($templatevars{$namespace}) {
		# ### Hmm. Which one of these are the fastest? :)
		# $templatevars{$namespace} = {};
		# delete $templatevars{$namespace};
		undef $templatevars{$namespace};
	} 
	undef;
}

# ### void destory_vars(void)
# Destroys and re-initializes all templatevars.
# (%templatevars, @cookies)
#
sub destroy_vars
{
	undef %templatevars;
	undef @cookies;
	%templatevars = ();
	@cookies = ();
	return undef;
}

# ### string expand_vars(Giza::Template template, string string)
# Expand all occurences of ${namespace:variable} to the 
# content of $templatevars{namespace}{variable}
#
sub expand_vars
{
	my($self, $string) = @_;
	if(index($string, "\$" != -1)) {
		$string =~ s/\$\{([\w\d]+):([\w\d]+)\}/$templatevars{$1}{$2}/sg;
	}
	return $string;
}


# ### int initvars(Giza::Template template)
# Initialize some variables at the start.
# This functions also re-initializes the template variable hash and cookie
# array by calling destroy_vars().
#
sub initvars
{
	my($self) = @_;
	my $g = $self->giza;
	my $db = $self->db;
	my $user = $self->user;
	my $config = $g->config;

	# Delete templates variables, so we're sure to have a fresh start.
	destroy_vars();

	# ### Set the page and parent if they're predefined.
	$self->setvar('giza', 'parent', $self->parent) if $self->parent;
	$self->setvar('giza', 'page', $self->page)	if $self->page;

	# ###
	# Fetch some properties from this objects parent,
	# into the parent:* namespace.
	if(defined $self->parent) {
		my $parent = new Giza::Object(giza=>$g, db=>$db, user=>$user);
		$parent = $parent->fetch(Id => $self->parent);
		$self->setvar('parent', 'id', $parent->id);
		$self->setvar('parent', 'name', $parent->name);
		$self->setvar('parent', 'data', $parent->data);
		$self->setvar('parent', 'parent', $parent->parent);
		$self->setvar('parent', 'keywords', $parent->keywords);
		$self->setvar('parent', 'description', $parent->description);
		undef $parent;
	}

	# ###
	# Save all the global configuration keys/values,
	# into the config:* namespace.
	foreach my $key (keys %{$config->{global}}) {
		$self->setvar('config', $key, $config->{global}{$key});
	}

	# ###
	# Save all the environment keys/values into the
	# cgi:* namespace.
	#
	foreach my $key (keys %ENV) {
		$self->setvar('cgi', lc($key), $ENV{$key});
	}

	return TRUE;
}

# ----------------------------------------------------------------- #

# ### [HASH ref|SCALAR] get_obj_flags(string object->data)
# Get information from the data field of a object.
# If the object has several properties, it returns a reference
# to an hash, else it just returns the same data field.
#
sub get_obj_flags {
	my($self, $data) = @_;
	my @argv = $self->parseline($data);

	if(scalar @argv >= 2) {
		my %flags = @argv;
		return \%flags;
	} else {
		return $data;
	}
}

# ### void set_obj_vars(Giza::Template template, Giza::Object obj)
# Store all object properties in the obj:* name space.
# This functions also sets some other nifty variables, if some options
# in the opt:* namespace is set.
#
sub set_obj_vars
{
	my($self, $obj) = @_;
	my $u  = $self->user;
	my $db = $self->db;

	# ### ...we only touch real Giza::Object objects!
	if(ref $obj eq 'Giza::Object') {

		# Store each object attribute into the obj:* namespace.
		foreach my $attribute (keys %Giza::Object::objstruct) {
			eval "\$self->setvar('obj', \$attribute, \$obj->$attribute);";
		}

		# Set some HTML checkbox and SELECT flags.
		if($self->getvar('opt:set_object_checkbox_flags')) {
			# ### Set flags for checkboxes...
			my %p = ();
			my $checked 	= '"1" checked="checked"';
			my $not_checked	= '"0"';
			$p{active}= $obj->active ? $checked : $not_checked;
			$p{'link'}  = (($obj->type eq 'link') ? '"link" selected="selected"' : '"link"');
			$p{cat}  = (($obj->type eq 'catalog')  ? '"catalog"  selected="selected"' : '"catalog"');
			$p{'ref'}  = (($obj->type eq 'reference')  ? '"reference"  selected="selected"' : '"reference"');
			$p{'image'} = (($obj->type eq 'image') ? '"image" selected="selected"' : '"image"');
			$p{'guide'} = (($obj->type eq 'guide') ? '"guide" selected="selected"' : '"guide"');
			$p{'ftp'} = (($obj->type eq 'ftp') ? '"ftp" selected="selected"' : '"ftp"');
			$p{'mp3'} = (($obj->type eq 'mp3') ? '"mp3" selected="selected"' : '"mp3"');
			$p{'ogg'} = (($obj->type eq 'ogg') ? '"ogg" selected="selected"' : '"ogg"');
			$p{irusr} = (oct $obj->mode & GZ_IRUSR) ? $checked : $not_checked;
			$p{iwusr} = (oct $obj->mode & GZ_IWUSR) ? $checked : $not_checked;
			$p{ixusr} = (oct $obj->mode & GZ_IXUSR) ? $checked : $not_checked;
			$p{irgrp} = (oct $obj->mode & GZ_IRGRP) ? $checked : $not_checked;
			$p{iwgrp} = (oct $obj->mode & GZ_IWGRP) ? $checked : $not_checked;
			$p{ixgrp} = (oct $obj->mode & GZ_IXGRP) ? $checked : $not_checked;
			$p{iroth} = (oct $obj->mode & GZ_IROTH) ? $checked : $not_checked;
			$p{iwoth} = (oct $obj->mode & GZ_IWOTH) ? $checked : $not_checked;
			$p{ixoth} = (oct $obj->mode & GZ_IXOTH) ? $checked : $not_checked;
			foreach(keys %p) {
				$self->setvar("flags", $_, $p{$_});
			}
		}

		# Convert obj:owner and obj:groupo from (u|g)id to name.
		if($self->getvar('opt:convert_ugid_to_name')) {
			my $namebyuid  = $u->namebyuid($self->getvar("obj:owner"));
			my $groupbygid = $u->groupbygid($self->getvar("obj:groupo"));
			$namebyuid  = 'Not attached to valid user' if $namebyuid  == ENOENT;
			$groupbygid = 'Not attached to valid group'if $groupbygid == ENOENT;
			$self->setvar("obj", "owner",  $namebyuid);
			$self->setvar("obj", "groupo", $groupbygid);
		}

		# Fetch the objects path. (XXX: probably expensive, use where needed.)
		if($self->getvar('opt:get_object_pathname')) {
			$self->setvar("obj", "pathname", $db->expr_by_id($obj->parent));
		}	

		#### 
		# Get attributes stored in components.
		# (XXX: Probably expensive. use where needed.)
		#
		if($self->getvar('opt:get_component_values')) {	
			my $comp = new Giza::Component(giza=>$self->giza, db=>$self->db);
				foreach my $component (@{$self->giza->config->{components}->{module}}) {
				next unless $component;
				$comp->template_handler($component, oid => $obj->id, template => $self);
			}
		}
	}
}

# ----------------------------------------------------------------- #
# <---> TEMPLATE CACHE FUNCTIONS

# ### void cache_save_memshare(string template_filename, string template_contents)
# Cache the contents of a template file.
#
sub cache_save_memshare
{
	my($filename, $data) = @_;
	{
		lock(%cache_memshare);
		$cache_memshare{$filename} = [time(), $data];
	}
}

# ### string cache_restore_memshare(string template_filename)
# Restore the contents of a cached template.
#
sub cache_restore_memshare
{
	my($filename) = @_;
	return undef unless $cache_memshare{$filename};
	{
		lock(%cache_memshare);
		return $cache_memshare{$filename}->[1];
	}
}

# ----------------------------------------------------------------- #
# <---> TEMPLATE CONTROL/FLOW

# ### void exit(void)
# Exit the script.
# TODO: This really is *not* the proper way of doing this :)
# 		Must find another way, but _how_?
#
sub exit
{
	$Die::Handler = new DieHandler sub {
		my($msg,$fmsg,$level,$eval) = @_;
		if($eval) {
			# if we are in an eval, skip to the next handler
			next;
		} else {
			# show a message box describing the error.
			print "$fmsg";
			# force the program to exit
			exit 0;
			next;
   		}
	};
	die "\n";
}

# ----------------------------------------------------------------- #

#%require <include/Giza/Template/BuiltIn.pm>

1
