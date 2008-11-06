package Net::Interface;

use strict;
use vars qw($VERSION @ISA %EXPORT_TAGS @EXPORT_OK @__consts);

require Exporter;
require DynaLoader;

@ISA = qw(Exporter DynaLoader);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT_OK	= qw(
		IFF_UP
		IFF_BROADCAST
		IFF_DEBUG
		IFF_LOOPBACK
		IFF_POINTOPOINT
		IFF_NOTRAILERS
		IFF_RUNNING
		IFF_NOARP
		IFF_PROMISC
		IFF_ALLMULTI
		IFF_MASTER
		IFF_SLAVE
		IFF_MULTICAST
		IFF_SOFTHEADERS
        AF_INET
		IFHWADDRLEN
		IFNAMSIZ
		mac_bin2hex
);
%EXPORT_TAGS = (
  constants	=> [@EXPORT_OK],
);

$VERSION = '0.13_01';

bootstrap Net::Interface $VERSION;

# Preloaded methods go here.

sub IFF_UP () {0x1;}
sub IFF_BROADCAST () {0x2;}
sub IFF_DEBUG () {0x4;}
sub IFF_LOOPBACK () {0x8;}
sub IFF_POINTOPOINT () {0x10;}
sub IFF_NOTRAILERS () {0x20;}
sub IFF_RUNNING () {0x40;}
sub IFF_NOARP () {0x80;}
sub IFF_PROMISC () {0x100;}
sub IFF_ALLMULTI () {0x200;}
sub IFF_MASTER () {0x400;}
sub IFF_SLAVE () {0x800;}
sub IFF_MULTICAST () {0x1000;}
sub IFF_SOFTHEADERS () {0x2000;}

sub AF_INET() {2;}

sub IFHWADDRLEN () {6;}
sub IFNAMSIZ () {16;}

sub mac_bin2hex {
  my $binmac = shift;
  return '' unless $binmac;
  sprintf("%s%s:%s%s:%s%s:%s%s:%s%s:%s%s",split('',uc unpack("H12",$binmac)));
}

sub DESTROY () {}

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

Net::Interface - Perl extension to access network interfaces

=head1 SYNOPSIS

  use Net::Interface qw(
	IFF_UP
	IFF_BROADCAST
	IFF_DEBUG
	IFF_LOOPBACK
	IFF_POINTOPOINT
	IFF_NOTRAILERS
	IFF_RUNNING
	IFF_NOARP
	IFF_PROMISC
	IFF_ALLMULTI
	IFF_MASTER
	IFF_SLAVE
	IFF_MULTICAST
	IFF_SOFTHEADERS
	IFHWADDRLEN
	IFNAMSIZ
	mac_bin2hex
  );

    or

  use Net::Interface qw(:constants mac_bin2hex);

    or for methods only

  require Net::Interface;
  
=head2 METHODS

  @all_ifs = Net::Interface->interfaces();

  foreach(@all_ifs) { print $_->name,"\n" };

  $if = Net::Interface->new ('eth0');

  my $name = $if->name;

  Get or Set
  $naddr = $if->address($naddr);
  $naddr = $if->broadcast($naddr);
  $naddr = $if->netmask($naddr);
  $naddr = $if->destination($naddr);
    or
  ($sa_family,$size,$naddr) = $if->address($naddr);
  ($sa_family,$size,$naddr) = $if->broadcast($naddr);
  ($sa_family,$size,$naddr) = $if->netmask($naddr);
  ($sa_family,$size,$naddr) = $if->destination($naddr);

  $mac =$if->hwaddress($hwaddr);
    or
  ($sa_family,$size,$hwaddr) = $if->hwaddress($hwaddr);

  $val = $if->flags($val);
  $val = $if->mtu ($val);
  $val = $if->metric($val);

=head2 FUNCTIONS

  $hexstring = mac_bin2hex(scalar $if->hwaddres);

=head1 DESCRIPTION

Net::Interface is designed to make the use of ifconfig(1) and friends
unnecessary from within Perl.  It provides methods to get at set all
the attributes of an interface, and even create new logical or
physical interfaces (if your O/S supports it).

=head2 Scalar context

The Get methods:

  $naddr = $if->address();
  $naddr = $if->broadcast();
  $naddr = $if->netmask();
  $naddr = $if->destination();

return a network address in binary form.

  $mac = $if->hwaddress();

returns a binary number which can be
converted to the hex MAC address using unpack("H*",$val).

The methods:

  $val = $if->flags();
  $naddr = $if->mtu();
  $naddr = $if->metric();

return numbers or bit patterns.

=head2 Array context

The methods:

  ($sa_family,$size,$naddr) = $if->address
  ($sa_family,$size,$naddr) = $if->broadcast
  ($sa_family,$size,$naddr) = $if->netmask
  ($sa_family,$size,$naddr) = $if->destination

return a three byte array of the form:

	address family		(AF_INET, etc...)
	size of address
	address as in Scalar context above

  ($sa_family,$size,$hwaddr) = $if->hwaddress();

returns a three byte array of the form:

	address family		(AF_LOCAL)
	size of address
	binary MAC address

=head2 Set methods

Where it is supported by the OS, the methods above may be used to set a
value with the syntax:

	$optional = $if->method($value);
	@optional = $if->method($value);

=head2 Functions

=over 4

=item * $hexstring = mac_bin2hex(scalar $if->hwaddress);

Converts the binary MAC address returned by the hwaddress method into a
colon separated series of hex octets representing the MAC address of the
hardware interface.

  input:	binary MAC address
  returns:	hex string MAC address

	i.e.  00:A0:CC:26:D3:80

=back

=head1 AUTHOR

  Stephen Zander <gibreel@pobox.com>

  recent updates by:
  Jerrad Pierce jpierce@cpan.org
  Michael Robinton <michael@bizsystems.com>
  Jens Rehsack <rehsack@web.de>

=head1 COPYRIGHT  1998 - 2008. All rights reserved.

  Stephen Zander	1998
  Jerrad Pierce		2000
  Michael Robinton	2006 - 2008
  Jens Rehsack 		2008

  All rights reserved.

  Parts of the text of this README copyright 1996,1997 Graham Barr.
  All rights reserved.

  This library is free software; you can redistribute it 
  and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

perl(1), ifconfig(8)

=cut

1;
