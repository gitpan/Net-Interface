package Net::Interface;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;
require DynaLoader;
require AutoLoader;

@ISA = qw(Exporter DynaLoader);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT_OK = qw(
		IFF_UP,
		IFF_BROADCAST,
		IFF_DEBUG,
		IFF_LOOPBACK,
		IFF_POINTOPOINT,
		IFF_NOTRAILERS,
		IFF_RUNNING,
		IFF_NOARP,
		IFF_PROMISC,
		IFF_ALLMULTI,
		IFF_MASTER,
		IFF_SLAVE,
		IFF_MULTICAST,
		IFF_SOFTHEADERS,
		IFHWADDRLEN,
		IFNAMSIZ,
);

$VERSION = '0.04';

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

sub IFHWADDRLEN () {6;}
sub IFNAMSIZ () {16;}

sub DESTROY () {}

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

Net::Interface - Perl extension to access network interfaces

=head1 SYNOPSIS

  use Net::Interface;
  
  $if = Net::Interface->new ("lo0");
  $if->mtu (1024);

  foreach (Net::Interface->interfaces ()) {print $_->name;}

=head1 DESCRIPTION

Net::Interface is designed to make the use of ifconfig(1) and friends
unnecessary from within Perl.  It provides methods to get at set all
the attributes of an interface, and even create new logical or
physical interfaces (if your O/S supports it).

=head1 AUTHOR

Stephen Zander <gibreel@pobox.com>

=head1 SEE ALSO

perl(1), ifconfig(8)

=cut
