use strict;
package Device::Digilent::Config;

require Device::Digilent;

use constant {
    DVCT_ETHERNET => 0,
    DVCT_USB      => 1,
    DVCT_SERIAL   => 2,
};

=head1 NAME

Device::Digilent::Config - Get Digilent configuration information

=head1 DESCRIPTION

Implements a variety of functions related to Digilent target device
configuration -- basically, all functions whose underlying DPCUTIL
implementations start with C<Dvmg>.

As long as you've got a copy of Adept open, the only function you're likely to
B<really> need in here is C<DefaultName()>. Most of the rest is only useful if
you're trying to implement something really crazy.

=head1 FUNCTIONS

=over 4

=item RunPanel()

Launches the Digilent configuration panel.

=item Count()

Returns the number of available devices.

=item Default()

Returns the index of the default device, or -1 if none is available.

=item GetName($idx)

Returns the name of the device at the specified index.

=item GetType($idx)

Returns the type of the device at the specified index.

The result should be among the values given by the constants C<DVCT_ETHERNET>,
C<DVCT_USB>, and C<DVCT_SERIAL>.

=item DefaultName()

Returns the name of the default device, or throws an error if none is
available. Useful as a shortcut, since the name is what
L<Device::Digilent::Data::new> will want...

=back

=cut

sub DefaultName {
    my $id = Device::Digilent::Config::Default();
    die "No devices available" if $id < 0;
    return GetName($id);
}

"Beyond Theory";
