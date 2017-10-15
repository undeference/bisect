# This program is free software. You can redistribute it and/or modify it under
# the same terms as perl itself.
# Copyright © M. Kristall
package Line;
use strict;

sub new ($$@) {
	bless ({
		@_[2 .. $#_],
		_file => $_[1],
		_fh => undef,
		line => 0
	}, $_[0]);
}

sub file ($) {
	$_[0]{_file};
}

sub _getline ($) {
	my $self = $_[0];
	unless ($self->{_fh}) {
		die ("open '$self->{_file}': $!\n")
			unless (open ($self->{_fh}, '<', $self->{_file}));
	}
	my $l = readline ($self->{_fh});
	$self->{line}++ if ($l);
	$l;
}

sub close ($) {
	close ($_[0]{_fh});
}

sub _rename ($$) {
	die ("rename \"$_[0]\" to \"$_[1]\": $!\n")
		unless (rename ($_[0], $_[1]));
}

sub backup ($) {
	&close;
	_rename ($_[0]{_file}, $_[0]{_bak} = "$_[0]{_file}.bak");
}

sub restore ($) {
	_rename ($_[0]{_bak}, $_[0]{_file});
	delete ($_[0]{_bak});
}

sub getitem ($) {
	my $self = $_[0];
	my $multi;
	my $spaces = '';
	my $val = '';
	my $ln;
	while (my $line = $self->_getline) {
		chomp ($line);
		my $i = 0;
		multi:
		if ($multi) {
			if (($i = index ($line, '*/', $i)) > -1) {
				$i += 2;
				$multi = 0;
			} else {
				next;
			}
		} else {
			$ln = $self->{line};
		}
		# this should not trigger a warning when it's at the end
		for (; defined (my $c = substr ($line, $i, 1)); $i++) {
			if ($c =~ /\s/) {
				$spaces .= $c;
			} elsif ($self->{'sh-comments'} && $c eq '#') {
				return Line::Item->new ($ln, $val)
					if ($val);
				last;
			} elsif ($self->{'cpp-comments'} && $c eq '/' &&
				substr ($line, $i + 1, 1) eq '/') {
				return Line::Item->new ($ln, $val)
					if ($val);
				last;
			} elsif ($self->{'c-comments'} && $c eq '/' &&
				substr ($line, $i + 1, 1) eq '*') {
				$multi = 1;
				$i += 2;
				goto multi;
			} else {
				if ($spaces) {
					$val .= $spaces if ($val);
					$spaces = '';
				}
				$val .= $c;
			}
		}
		next if ($multi);
		return Line::Item->new ($ln, $val) if ($val);
	}
	undef;
}

package Line::Item;
use strict;
use overload '""' => 'value';

sub new ($$;$) {
	bless ([@_[1, 2]], $_[0]);
}

sub line ($) : lvalue {
	$_[0][0];
}

sub value ($) : lvalue {
	$_[0][1] . "\n";
}

1;
