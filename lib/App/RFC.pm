package App::RFC;

use 5.010;
use strict;
use warnings;

our $VERSION = "0.06";

sub get_config ($;$) {
	my ( $io, $default ) = @_;
	my $body;

	$default = $default || "__main__";

	if (ref $io eq "GLOB" or ref $io eq "IO::File") {
		$body = do { local $/; <$io> };
	}
	elsif (ref $io eq "SCALAR") {
		$body = $$io;
	}
	else {
		open F, $io or return;
		$body = do { local $/; <F> };
		close F;
	}

	$body =~ s/#.*\n//gm;		# delete comments
	$body =~ s#\n(:?\s+)#\n#gs;	# delete unnecessary  spaces
	$body =~ s#\\\s*##gs;		# join \\-strings

	my ( %hash ) = ( $default , split "\\[(.+?)\\]", $body );
	while (my ( $a, $b ) = each %hash) {
		$hash{ $a } = { map { split "\\s*=\\s*", $_, 2 } grep !/^\s*$/, split "\n", $b };
	}

	foreach my $k1 ( grep { $_ ne $default } keys %hash ) {
		foreach my $k2 ( keys %{ $hash{ $k1 } } ) {
			$hash{ $k1 }->{ $k2 } =~ s#\$(\w+)#$hash{ $default }->{ $1 }#ge;
		}
	}

	return \%hash;
}

1;

__END__

=head1 NAME

App::RFC - Perl script for get and display rfc by number.

=head1 SYNOPSIS

See L<RFC>.

=head1 DESCRIPTION

This script intended for retirving and displaying RFC documents by number, cache
these locally.

Also implemented retieving new version iof rfc-index.txt from main site (http://tools.ietf.org)
and display difference between old and new version ot it.

=head2 EXPORT

None by default.



=head1 SEE ALSO

L<http://tools.ietf.org>

=head1 AUTHOR

Artur Penttinen, E<lt>arto@cpan.org<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2015 by Artur Penttinen

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.18.4 or,
at your option, any later version of Perl 5 you may have available.

=cut

### That's all, folks!
