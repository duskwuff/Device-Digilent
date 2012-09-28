use strict;
package Device::Digilent::Data;

require Device::Digilent;

=head1 NAME

Device::Digilent::Data - Communicate with Digilent device registers

=head1 DESCRIPTION

Allows access to data registers on Digilent devices.

All bytes are treated as unsigned throughout.

=head1 FUNCTIONS

=over 4

=item Data->new($name)

Opens a new connection to the parallel interface on the specified device.

=item $Conn->Close()

Closes the connection, making it invalid for further use.

The connection is automatically closed on C<DESTROY>, so you shouldn't usually
need to call this explicitly.

=item $Conn->GetByte($reg)

Reads a byte from the specified register and returns its value.

=item $Conn->PutByte($reg, $val)

Writes a byte to the specified register.

=item $Conn->GetWord($reg)

Reads a little-endian word (16 bits) from the specified register and the one
following it, and returns the result.

=item $Conn->PutWord($reg, $val)

Writes a little-endian word (16 bits) to the specified register and the one
following it.

=item $Conn->GetLong($reg)

Reads a little-endian long (32 bits) from the specified register and the three
following it.

=item $Conn->PutLong($reg, $val)

Writes a little-endian long (32 bits) to the specified register and the three
following it.

=item $Conn->GetRepeat($reg, $buf, $len)

Sequentially reads C<$len> bytes from the specified register and writes them
into a buffer, I<a la> C<read()>.

=item $Conn->PutRepeat($reg, $buf)

Sequentially writes each byte from C<$buf> to the specified register.

=item $Conn->GetMulti($buf, @regs)

Reads bytes from each of the specified registers into C<$buf>, which is
expanded to make room for as many addresses as necessary.

=item $Conn->PutMulti($buf, @regs)

Writes bytes from C<$buf> into each of the specified registers. C<$buf> must be
at least as long as C<@regs>.

=back

=cut

sub GetWord {
    my ($self, $reg) = @_;
    $self->GetMulti(my $buf, $reg, $reg + 1);
    return unpack("v", $buf);
}

sub GetLong {
    my ($self, $reg) = @_;
    $self->GetMulti(my $buf, $reg, $reg + 1, $reg + 2, $reg + 3);
    return unpack("V", $buf);
}

sub PutWord {
    my ($self, $reg, $val) = @_;
    $self->PutMulti(pack("v", $val), $reg, $reg + 1);
}

sub PutLong {
    my ($self, $reg, $val) = @_;
    $self->PutMulti(pack("V", $val), $reg, $reg + 1, $reg + 2, $reg + 3);
}

"Beyond Theory";
