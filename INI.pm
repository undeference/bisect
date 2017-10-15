# This program is free software. You can redistribute it and/or modify it under
# the same terms as perl itself.
# Copyright © M. Kristall
package INI;
use strict;
use parent qw(Line);

sub _ungetline ($$) {
	push (@{$_[0]{__lines}}, $_[1]);
	$_[0]{line}--;
}

sub _getline ($) {
	my $self = $_[0];
	unless ($self->{_fh}) {
		die ("open '$self->{_file}': $!\n")
			unless (open ($self->{_fh}, '<', $self->{_file}));
	}
	my $l = @{$_[0]{__lines} || []} ?
		pop (@{$_[0]{__lines}}) :
		readline ($self->{_fh});
	$self->{line}++ if ($l);
	$l;
}

sub getitem ($) {
	my $self = $_[0];
	my $val = '';
	my $ln;
	while (my $line = $self->_getline) {
		if ($line =~ /^\[.+\]$/) {
			if ($val) {
				$self->_ungetline ($line);
				last;
			}
			$ln = $self->{line};
			$val = $line;
		} elsif ($val) {
			# handle # and ; comments
			$line =~ s/\s*[#;].*$// if ($self->{comments});
			next unless ($line =~ /\S/);
			$val .= $line;
		}
	}
	$val ? INI::Item->new ($ln, $val) : undef;
}

package INI::Item;
use strict;
use parent qw(-norequire Line::Item);

1;
