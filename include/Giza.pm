#!/usr/bin/perl
# -+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
# Giza.pm - The main Giza interface.
# (c) 1996-2002 ABC Startsiden AS, see the file AUTHORS.
#
# See the file LICENSE in the Giza top source distribution tree for
# licensing information. If this file is not present you are *not*
# allowed to view, run, copy or change this software or it's sourcecode.
# -+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
#####

=comment
My eyes say their prayers to her
Sailors ring her bell
Like a moth mistakes a light bulb
For the moon and goes to hell

She's my Black Market Baby
She's a diamond that
Wants to stay coal
=cut

#%include <config.pimpx>

package Giza;
# ------------------------------------------------------------------ #

use strict;
use Socket;
use FileHandle;
use Fcntl;
use Exporter;
use XML::Simple;
use vars qw(
	@ISA @EXPORT @EXPORT_OK $VERSION $CONFIGFILE
	%EXPORT_TAGS $PREFIX $CONFIG_CACHE_TYPE
	$LOGSOCKET
);

# Export variables and constants to parent namespace.
# ------------------------------------------------------------------ #

#%ifdef SELFLOADER
#%print require SelfLoader;
#%print @ISA = qw(Exporter SelfLoader);
#%else
@ISA = qw(Exporter);
#%endif

@EXPORT = qw(
	&TRUE 			&FALSE 
	&G_CAT_TOP		&MAX_REFERENCE_REC_DEPTH
	$LOGSOCKET 		&strcmp &strstr
);

%EXPORT_TAGS = (
    all  => [ @EXPORT ],
);

#%ifdef PREFIX
#%  print $PREFIX = "%{PREFIX}";
#%else
$PREFIX = '/';
#%endif

$VERSION = "1.9.22";
$CONFIGFILE = $PREFIX. '/etc/gizaconfig.xml';
$LOGSOCKET = $PREFIX. '/var/run/giza-logd.sock';

# id of the first catalog
sub G_CAT_TOP {1};

# Max iterations of the get_rec_reference() function.
sub MAX_REFERENCE_REC_DEPTH {50};

sub TRUE			{1}		;
sub FALSE			{undef}	;

# ### prototypes
sub parseconfig();

# ###
# Configuration cache can be of the types: 
# storable, memshare or memcopy
# see the XML::Simple manpage for more info.
#% ifdef CONFIG_CACHE_TYPE
#%   print $CONFIG_CACHE_TYPE = "%{CONFIG_CACHE_TYPE}";
#% else
$CONFIG_CACHE_TYPE = "storable";
#% endif

#%ifdef SELFLOADER
#%print 1
#%print __DATA__
#%endif

# Constructor
# ------------------------------------------------------------------ #

# ### Giza new(void)
# Create a new Giza object. Will parse
# and save configuration in $obj->config.
#
sub new
{
	my($self) = @_;
	my $obj = {};
	bless $obj, $self;
	$obj->config(Giza::parseconfig);
	$obj->debug($obj->config->{general}{debug});
	return $obj;
}

# Methods
# ------------------------------------------------------------------ #

# ### int debug(Giza giza, string debug)
# Get/Set the debugging option.
#
sub debug
{
	my($self, $debug) = @_;
	$debug = 1
		if $self->config->{global}{debug};
	if(defined $debug) {
		$self->{DEBUG} = 1;
	}
	return $self->{DEBUG};
}

# ### string config(Giza giza, hashref config)
# Get/Set the configuration hashref.
#
sub config
{
	my($self, $config) = @_;
	if(defined $config) {
		$self->{CONFIG} = $config;
	}
	return $self->{CONFIG};
}

# ### void log(Giza giza, string message)
# Log a message to the giza logdaemon.
#
sub log 
{
	my($self, $message) = @_;
	$message ||= 'Unexpected event';
	unless(-S $Giza::LOGSOCKET) {
		return undef;
	}
	socket(CLIENT, PF_UNIX, SOCK_DGRAM , 0);
	if(connect(CLIENT, sockaddr_un($Giza::LOGSOCKET))) {
		CLIENT->autoflush(1);
		$|++;
		printf CLIENT ('name=%s pid=%d message=%s',
			'giza', $$, $message
		);
	}
	return undef;
}	

# ### string error(Giza giza, string errormessage)
# Save or get the last error message and print 
# it if the debug option is set.
#
sub error
{
	my($self, $error) = @_;
	if(defined $error) {
		my $msg = undef;
		if($self->debug()) {
			my($package, $filename, $line) = caller();
			$msg = sprintf("[%s: %s: %d]: Error: %s\n",
				$package, $filename, $line, $error
			);
			print STDERR $msg;
		} else {
			$msg = sprintf("Error: %s\n", $error);
		}
		$self->log($msg);
		$self->{ERROR} = $msg;
	}
	return $self->{ERROR};
}

# ### string warning(Giza giza, string warning)
# Save or get the last warning message and print 
# it if the warning option is set.
#
sub warning
{
	my($self, $warning) = @_;
	if(defined $warning) {
		my $msg = undef;
		if($self->debug()) {
			my($package, $filename, $line) = caller();
			$msg = sprintf("[%s: %s: %d]: Warning: %s\n",
				$package, $filename, $line, $warning
			);
			print STDERR $msg;
		} else {
			$msg = sprintf("Warning: %s\n", $warning);
		}
		$self->log($msg);
		$self->{WARNING} = $msg;
	}
	return $self->{WARNING};
}


# ### XML::Simple hashref parseconfig(void)
# Uses XML::Simple to parse the configuration
# file in $Giza::CONFIGFILE.
# See perldoc XML::Simple for more information
# on how it works, use utils/g_dumpconfig to
# see the result.
#
# XXX: This will exit the program if any error
# occurs, # such as malformed xml, or 
# missing/incomplete configuration sections!
#


sub parseconfig()
{
	unless($Giza::CONFIGFILE =~ /^\//) {
		$Giza::CONFIGFILE = $Giza::PREFIX. '/'. $Giza::CONFIGFILE;
	}
	unless(-f $Giza::CONFIGFILE) {
        print STDERR "Fatal error: Couldn't open configfile '$Giza::CONFIGFILE': $!\n";
        exit 1;
	}
	return XMLin($Giza::CONFIGFILE, cache => $Giza::CONFIG_CACHE_TYPE);
}		

# ### string mkpasswd(int length)
# Create a strong, good random password with lower/uppercase chars and numbers.
#
sub mkpasswd
{
	my($len) = @_;
	my $passwd = undef;
	$len ||= 8;

	OUTER:
	until(0) { # until we have a valid password
		my($uppercase, $lowercase, $digit) = (0,0,0);
		my($left_side, $right_side) = (0,0);
		my(%seen) = ();

		my %rl_left = map {$_ => 1} qw(
			q Q w W e E r R t T
			y Y a A s S d D f F
			g G z Z x X c C v V
			1 2 3 4 5 6
		);

		my %rl_right = map {$_ => 1} qw(
			u U i O o O p P h H
			j J k K l L b B n N
			m M 7 8 9 0
		);

		until(length $passwd == $len) {
			$passwd .= (0..9, 'A'..'Z', 'a'..'z')[rand 64];
		}

		INNER:	
		foreach my $chr (split '', $passwd) {
			goto NEW if $seen{$chr}++;

			if($rl_left{$chr}) {
				$left_side++;
			}
			elsif($rl_right{$chr}) {
				$right_side++;
			}
			
			if($chr =~ /^[A-Z]$/) {
				$uppercase++;
			}
			elsif($chr =~ /^[a-z]$/) {
				$lowercase++;
			}
			elsif($chr =~ /^[0-9]$/) {
				$digit++;
			}
		}

		goto NEW unless $left_side >= 1;
		goto NEW unless $uppercase >= 2;
		goto NEW unless $lowercase >= 2;
		goto NEW unless $digit;

		if($left_side and $right_side) {
			goto NEW if $left_side / $right_side <= 0.7;
			goto NEW if $left_side / $right_side >= 1.4;
		}
		last;

		NEW: {undef $passwd, next OUTER}	
	}
	return $passwd;
}

# ### int strcmp(string str1, string str2)
# Check if two strings are equal
#
sub strcmp
{
	return (shift eq shift) ? TRUE : FALSE
}

# ### int strstr(string haystack, string needle)
# Check if haystack contains needle.
#
sub strstr
{
	return (index(shift, shift) >= 0) ? TRUE : FALSE
}

sub safeopen
{
	my($self, $filename, $flags) = @_;
	my $fh = new FileHandle;
	my($fdev, $fino, $hdev, $hino);

 	# Clean up bogus bits.
	$flags &= (
		O_RDONLY|O_WRONLY|O_RDWR|O_CREAT|O_APPEND|O_TRUNC
	);

	if($filename =~ /(\.\.|\||;)/) {
		$self->error("ALERT: User tries to shell escape or get parent directory!");
		$self->error("Yeah sure! Attempt logged.");
		return undef;
	}

	if(-f $filename) {
		unless(($fdev, $fino) = stat($filename)) {
			$self->error("Couldn't stat $filename: $!");
			return undef;
		}
	}

	unless(sysopen($fh, $filename, $flags)) {
		$self->error("$! ($filename)");
		return undef;
	}

	if(-f $filename and $hdev and $hino) {
		unless(($hdev, $hino) = stat($fh)) {
			$self->error("Couldn't stat filehandle for $filename: $!");
			return undef;
		}

		unless(($fdev == $hdev) || ($fino == $hino)) {
			$self->log("ALERT: Possible race attempt, stat doesn't match for file $filename: ($fdev|$hdev, $fino|$hino)");
			$self->error("Access denied");
			return undef;
		}
	}

	return $fh;
}
		

1 # gabba gabba hey! hey!
__END__
