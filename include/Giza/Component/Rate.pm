#!/usr/bin/perl
# -+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
# Giza::Component::Rate - Giza Rating System
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


package Giza::Component::Rate;

use strict;
use Giza;
use Giza::Component;
use Class::Struct;

# ----------------------------------------------------------------- #

struct(
	giza	=> '$',
	db		=> '$'
);

sub fetch {
	my($self, %argv) = @_;
	my $g = $self->giza;
	my $db = $self->db;

	# ### The struct returned
	my $ret = {
		rate		=> 0,
		showrate	=> 0,
		total_votes	=> 0,
		status		=> COMP_SUCCESS
	};
	
	unless(defined $argv{oid}) {
		$g->error("Missing required argument: oid");
		$ret->{status} = COMP_ARG_MISSING;
		return $ret;
	}

	my $query = qq{
		SELECT rate, total_votes FROM rate WHERE id=$argv{oid}
	};
	
	my $res = undef;
	unless($res = $db->fetchonerow_hash($query)) {
		$ret->{status} = COMP_FIELD_MISSING;
		return $ret; # object has no rate, so we return 0;
	}

	if($res->{rate} and $res->{total_votes}) {
		$ret->{showrate} = sprintf("%0.1f", $res->{rate} / $res->{total_votes});
	} else {
		$ret->{showrate} = "0.0";
	}
	
	$ret->{rate}		= $res->{rate};
	$ret->{total_votes} = $res->{total_votes};

	return $ret;
}

sub store {
	my($self, %argv) = @_;
	my $g  = $self->giza;
	my $db = $self->db;
	
	# ### The struct returned
	my $ret = {
		status	=> COMP_SUCCESS
	};
	
	unless(defined $argv{oid}) {
		$g->error("Missing required argument: oid");
		$ret->{status} = COMP_ARG_MISSING;
		return $ret;
	}
	unless(defined $argv{rate}) {
		$argv{rate} = 0;
	}

	my $current_values = $self->fetch(%argv);
	if($current_values->{status} == COMP_FIELD_MISSING) {
		my $query = qq{
			INSERT INTO rate (id, rate, total_votes) VALUES(
				$argv{oid}, $argv{rate}, 1
			)
		};
		unless($db->exec_query($query)) {
			$ret->{status} = COMP_ERROR;
		}
	}
	else {
		return $self->update(%argv);
	}
		
	return $ret;
	
}

sub delete {
	my($self, %argv) = @_;
	my $g  = $self->giza;
	my $db = $self->db;
	
	# ### The struct returned
	my $ret = {
		status	=> COMP_SUCCESS
	};
	
	unless(defined $argv{oid}) {
		$g->error("Missing required argument: oid");
		$ret->{status} = COMP_ARG_MISSING;
		return $ret;
	}

	my $current_values = $self->fetch(%argv);
	if($current_values->{status} == COMP_SUCCESS) {
		my $query = qq{
			DELETE FROM rate WHERE id=$argv{oid}
		};
		unless($db->exec_query($query)) {
			$ret->{status} = COMP_ERROR;
			return $ret;
		}
	}
	else {
		$g->error("No field in rate with id $argv{oid}");
		$ret->{status} = COMP_FIELD_MISSING;
		return $ret;
	}

	return $ret;
}

sub update {
	my($self, %argv) = @_;
	my $g  = $self->giza;
	my $db = $self->db;
	
	# ### The struct returned
	my $ret = {
		status	=> COMP_SUCCESS
	};
	
	unless(defined $argv{oid}) {
		$g->error("Missing required argument: oid");
		$ret->{status} = COMP_ARG_MISSING;
		return $ret;
	}
	unless(defined $argv{rate}) {
		$g->error("Missing required argument: rate");
		$ret->{status} = COMP_ARG_MISSING;
		return $ret;
	}

	my $current_values = $self->fetch(%argv);
	if($current_values->{status} != COMP_SUCCESS) {
		$g->error("No field in rate with id $argv{oid}");
		$ret->{status} = COMP_FIELD_MISSING;
		return $ret;
	}

	my $total_rate  = $current_values->{rate} + $argv{rate};
	my $total_votes = $current_values->{total_votes} + 1;

	my $query = qq{
		UPDATE rate SET rate=$total_rate, total_votes=$total_votes
		WHERE id=$argv{oid}
	};

	unless($db->exec_query($query)) {
		$ret->{status} = COMP_ERROR;
		return $ret;
	}

	return $ret;
}

sub template_handler {
	my($self, %argv) = @_;
	my $oid = $argv{oid};
	my $template = $argv{template};

	my $result = $self->fetch(oid => $oid);
	$result->{rate} 		||= "0.0";
	$result->{total_votes}	||= "0";
	$template->setvar("obj", "rate", $result->{rate});
	$template->setvar("obj", "showrate", $result->{showrate});
	$template->setvar("obj", "total_votes", $result->{total_votes});

	return $result;
}
	
1
__END__
