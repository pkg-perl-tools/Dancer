package Dancer::Deprecation;
# ABSTRACT: deprecation handler for Dancer core
use strict;
use warnings;
use Carp qw/croak carp/;

=method deprecated

List of possible parameters:

=over 4

=item B<feature> name of the feature to deprecate

=item B<version> from which version the feature is deprecated

=item B<message> message to display

=item B<fatal> if set to true, croak instead of carp

=item B<reason> why is the feature deprecated

=back

You can call the method with no arguments, and a default message using informations from C<caller> will be build for you.

=cut

sub deprecated {
    my ($class, %args) = @_;

    my ( $package, undef, undef, $sub ) = caller(1);

    unless ( defined $args{feature} ) {
        $args{feature} = $sub;
    }

    my $deprecated_at = defined $args{version} ? $args{version} : undef;

    my $msg;
    if ( defined $args{message} ) {
        $msg = $args{message};
    }
    else {
        $msg = "$args{feature} has been deprecated";
    }
    $msg .= " since version $deprecated_at" if defined $deprecated_at;
    $msg .= ". " . $args{reason} if defined $args{reason};

    croak($msg) if $args{fatal};
    carp($msg);
}

1;

__END__

=head1 SYNOPSIS

  Dancer::Deprecation->deprecated(
    feature => 'sub_name',
    version => '1.3000',
    reason  => '...',
  );

=cut


