use strict;
package Device::Digilent;

require DynaLoader;

our @ISA = qw( DynaLoader );
our $VERSION = "1.0";

bootstrap Device::Digilent;

require Device::Digilent::Config;
require Device::Digilent::Data;

Device::Digilent::Init();

=head1 NAME

Device::Digilent - Interface with Digilent FPGA boards

=head1 SYNOPSIS

    use Device::Digilent;

    Device::Digilent::RunPanel();

    my $conn = Device::Digilent::Data->new(
        Device::Digilent::Config::DefaultName()
    );
    $conn->Put(1, 255);
    $conn->GetRepeat(2, my $buf, 1024);

=head1 DESCRIPTION

Device::Digilent implements an interface to the Digilent DPCUTIL library,
allowing communication with a wide variety of Digilent FPGA boards.

Most of the really interesting functions in this library exist in the
submodules L<Device::Digilent::Config> and L<Device::Digilent::Data>, which are
automatically pulled in. See the documentation for those modules for more
details.

=head1 FUNCTIONS

=over 4

=item Init()

Calls the C<DpcInit> function to initialize the library.

This function is automatically called when the module is loaded, so calling it
manually should not generally be necessary.

=item Terminate()

Calls the C<DpcTerm> function to deinitialize the library.

In practice, it seems that simply closing any active connections is sufficient
to clean things up -- the library does not need to be explicitly terminated.
But you can throw a call to this function into an C<END{}> block if it makes
you feel better.

=item Version()

Asks the DPCUTIL library what its version is. (Returns a string.)

Note that this is completely unrelated to the version of L<Device::Digilent>!

=back

=head1 SEE ALSO

L<Device::Digilent::Config>, L<Device::Digilent::Data>.

=cut

"Beyond Theory";
