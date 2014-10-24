package Net::Interface::Developer;

use vars qw($VERSION);

$VERSION = '0.03';

=pod

=head1 NAME

Net::Interface::Developer api, notes, hints

=head1 DESCRIPTION

This contains development notes and API documentation for the
Net::Interface module. It is hoped that others will help fill in the missing pieces
for OS's and address families that are currently unsupported.

=head1 ARCHITECTURE

Net::Interface gathers information about the network interfaces in an OS
independent fashion by first attempting to use C<getifaddrs> if
C<getifaddrs> is not supported on the OS it falls back to using system
C<ioctl's> and the C<ifreq, in6_ifreq, lifreq> structures defined on the
local host. Linux differs somewhat since ipV6 information is available only directly
from the kernel on older versions where C<getifaddrs> is not available. The
C<ifreq> and friends information is used to generate a C<getifaddrs>
response.

Herein lies the need for continued development by the opensource community.
Many OS's have peculiar C<ioctl> variants and SIOC's variants that require
unique code solutions. I'm sure that all of them are not presently included.

Net::Interface is built in 5 layers, listed below from the base up.

=head2 description:	files		code

=head2 1) AF_xxx families: ni_af_inetcommon.c	(C)

Code modules for AF families. Currently supported are AF_INET, AF_INET6. There
is partial support for AF_LINK and AF_PACKET for retrieval of MAC address
from the interface where it is needed. Where the code is reasonably
universal for a particular address family and the methods used to retrieve
the information from the OS, it resides in an af_xxxx.c file.

=head2 2) IFREQ families: ni_xx_ifreq.c	(C)

Code modules for IFREQ families. Currently supported are:

=over 2

=item * C<ifreq> ni_ifreq.c

Provides support for retrieval of ipV4 information. The structure C<ifreq>
does not provide enough space to return data about socket address families
larger than C<struct sockaddr>. All known operating systems support this
flavor of data retrieval. ni_ifreq.c makes use of calls to ni_af_inet.c

=item * C<in6_ifreq> ni_in6_ifreq.c

Provides support for retrieval of both ipV4 and ipV6 information.
C<in6_ifreq> uses C<struct sockaddr_storage> rather than the smaller
C<struct sockaddr> that is used in C<ifreq>. This code modules support
variants of the BSD operating system and a few others. ni_in6_ifreq makes
use of calls to ni_af_inetcommon.c

=item * C<lifreq> ni_lifreq.c

Provides support for retrieval of both ipV4 and ipV6 information. C<lifreq>
has a custom format unique to the SUN operating systems. Pretty much
everything in it, while similar to the two previous code modules, is custom.

=item * C<linuxproc> ni_linuxproc.c

Provides support for retrieval of both ipV4 and ipV6 information.
C<linuxproc> uses calls to ni_af_inet.c to get ipV4 information int
C<getifaddrs> format and custom code to collect similarly formatted ipV6
information directly from the /proc file system. It then performs a merge
on these two data sets to put them into proper order and add B<fake> AF_LINK
or AF_PACKET records to provide C<getifaddrs> compatiable access to the MAC
address through the returned C<struct ifaddrs> array.

=back

=head2 3) C<getifaddrs> ni_getifaddrs.c	(C)

The C<getifaddrs> code module contains the decision mechanism for how data
is retrieved for a particular build of Net::Interface. At build time,
portions of the code are #ifdef'd in/out depending on the availabiltiy of
resource from the underlying OS. In addition, at run time, if the system
does not have native C<getifaddrs> then a decision tree is used depending on
the response to calls for data to the various code modules described in
section 2).

=head2 4) Sub-system Interface.xs	(PERLXS)

This file asks for the data about the interfaces with a generic call to
C<getifaddrs>. The data returned resides in memory allocated by the OS and
must be freed or a memory leak will result as it is not tracked by Perl's
garbage collector. C<Interface.xs> moves the interface data from allocated
memory to Perl managed memory where it can be reclaimed by the garbage
collection mechanism if/when the user space program turns it loose. This
eliminates the need for a C<close> operation to free the OS's allocated
memory.

=head2 5) User space Interface.pm	(Perl)

=head1 DATA FLOW BLOCK DIAGRAM

The pure perl portion of this module performs most of the presentation operations for the
user that are published in the API for Net::Interface.

	*\  \  \    |	 /  /  /*
	*      user space	*
	*************************
		    ^				     Net::Interface
		    |				Architecture Block Diagram
		    v
	*************************
	*      Interface.pm	*
	*************************
		    |
	*************************
	*      Interface.xs	*
	*************************
		    |
	*************************		*************************	
	*   system getifaddrs	*		*      ni_getifreqs	*
	*	   via		*<-if missing ->*	    via		*
	*   (ni_getifaddrer.c)	*		*    (ni_ifreq.c)	*
	*************************		*    (ni_lifreq.c)	*
						*    (ni_in6_ifreq.c)	*
						*    (ni_linuxproc.c)	*
						*************************
							    |
						*************************
				   		*  (ni_af_inetcommon.c)	*
						*************************

=head1 DEVELOPER API

Access to the pieces of code in the block diagram above are available
through a developer API. These codes snippets from Interfaces.xs describe
the access.

 void
 __developer(ref)
        SV *ref
    ALIAS:
        d_ni_ifreq      = NI_IFREQ
        d_ni_lifreq     = NI_LIFREQ
        d_ni_in6_ifreq  = NI_IN6_IFREQ
        d_ni_linuxproc  = NI_LINUXPROC
    PREINIT:
        char * process;
        int er = ni_developer(ix);

B<and.....>

 void
 gifaddrs_base(ref)
        SV * ref
    ALIAS:
 #      base            = 0
        gifa_ifreq      = NI_IFREQ
        gifa_lifreq     = NI_LIFREQ
        gifa_in6_ifreq  = NI_IN6_IFREQ
        gifa_linuxproc  = NI_LINUXPROC
    PREINIT:
        struct ifaddrs * ifap;
        int rv;
    CODE:
        if ((rv = ni_getifaddrs(&ifap,ix)) == -1) {
            printf("failed PUNT!\n");
            XSRETURN_EMPTY;

Both function sets result in a printed description to the terminal window to
facilitate code creation and debug. Currently the B<ref> is unused. It is
expected that future developement will modify or add to function access.

  # test.pl for developer
  #
  use strict;
  use Net::Interface;

  # to call OS native getifaddrs if present
  print "\nifreq\n";  gifaddrs_base Net::Interface();

  # to call ni_linuxproc fallback getifaddrs
  print "\nlxp\n";    gifa_linuxproc Net::Interface();

  # to call ni_linuxproc ifreq emulation
  print "\nglxp\n";   d_ni_linuxproc Net::Interface();

See: test.pl.developer

=head1 DEVELOPER API DESCRIPTION

If you have gotten this far, it is time to read some of the code. AF_familes
and IFREQ_families are accessed through constuctor structs found at the bottom
of each of the ni_af_xxx and ni_xx_ifreq source files. Their vectoring
components are described in C<ni_func.h> near the bottom and in C<ni_util.c>
in the section labeled B<constructor registration> the essence of which is
described here.

  struct ni_ifconf_flavor * ni_ifcf_get(enum ni_FLAVOR type)
  struct ni_ifconf_flavor * ni_safe_ifcf_get(enum ni_FLAVOR type);

  nifp = ni_ifcf_get(NI_IFREQ);

Returns a pointer C<nifp> to the structure for a particular flavor of
B<ifreq>. If a flavor is unsupported on a particular architecture a NULL
is returned by the first invocation and NI_IFREQ by the second. 
Currently supported flavors are:

  enum ni_FLAVOR {
        NI_NULL,	reserved for the getifaddrs base system call
        NI_IFREQ,
        NI_LIFREQ,
        NI_IN6_IFREQ,
        NI_LINUXPROC
  };

  struct ni_ifconf_flavor {
    enum ni_FLAVOR              ni_type;
    int                         (*gifaddrs)
    int                         siocgifindex;  
    int                         siocsifaddr;   
    int                         siocgifaddr;   
    int                         siocdifaddr;   
    int                         siocaifaddr;   
    int                         siocsifdstaddr;
    int                         siocgifdstaddr;
    int                         siocsifflags;
    int                         siocgifflags;
    int                         siocsifmtu;
    int                         siocgifmtu;
    int                         siocsifbrdaddr;
    int                         siocgifbrdaddr;
    int                         siocsifnetmask;
    int                         siocgifnetmask;
    int                         siocsifmetric;
    int                         siocgifmetric;
    int                         ifr_offset;
    void                        (*fifaddrs)	 howto free ifaddrs
    int                         (*refreshifr)	 howto refresh ifreq
    void *                      (*getifreqs)	 howto get ifreq
    int                         (*developer)	 developer access
    struct ni_ifconf_flavor *   ni_ifcf_next;
  };

=head1 MACROS

=over 4

=item NI_PRINT_MAC(u_char * hex_mac_string);

  printf statement for terminal output of the form

	XX:XX:XX:XX:XX:XX:XX:XX

=item NI_MAC_NOT_ZERO(u_char * hex_mac_string)

  if( NI_MAC_NOT_ZERO(macp))
	do something

=item NI_PRINT_IPV6(struct sin6_addr);

  Takes an agrument of the form sockaddr_in6.sin6_addr and prints

	XXXX:XXXX:XXXX:XXXX:XXXX:XXXX:XXXX:XXXX

=back

=head1 FUNCTIONS

=over 4

=item int ni_clos_reopn_dgrm(int fd, int af)

Closes and then opens an C<ioctl> socket of type SOCK_DGRAM and returns the
socket value. If the socket value is NEGATIVE, no close is attempted an the
call is equivalent to:

  socket(af,SOCK_DGRAM,0)

=item void ni_gifa_free(struct ifaddrs * ifap, int flavor)

Use the appropriate free memory function call depending on the flavor of the
getifaddrs function that returned the ifaddrs structure list.

=item int nifreq_gifaddrs(struct ifaddrs **ifap, 
	struct ni_ifconf_flavor *nifp)

Our semi-standard version of C<getifaddrs> used by OS's that provide C<ifreq>
and C<in6_ifreq>.

NOTE: all calls to C<getifaddrs> return -1 on failure and and the FLAVOR as
enumerated above on success. 

  i.e. NI_NULL for the native getifaddrs, NI_IFREQ, NI_LINUXPROC, etc...

=item uint32_t ni_ipv6addr_gettype(struct in6_addr * in6p)

Extracts information about the type of ipV6 address. The returned value may
be passed to the NEXT function call to print.

=item int ni_lx_map2scope(int lscope)

This function maps I<Linux> style scope bits to their RFC-2373 equivalent.

    scope flags	rfc-2373
	0 	reserved
	1    node-local (aka loopback, interface-local)
	2    link-local
	3	unassigned
	4	unassigned
	5    site-local
	6	unassigned
	7	unassigned
	8    organization-local
	9	unassigned
	A	unassigned
	B	unassigned
	C	unassigned
	D	unassigned
	E    global scope
	F	reserved

      Linux   rfc-2372		      
     0x0000	0xe	GLOBAL
     0x0010u	0x1	NODELOCAL, LOOPBACK, INTERFACELOCAL
     0x0020u	0x2	LINKLOCAL
     0x0040u	0x5	SITELOCAL

=item void ni_linux_scope2txt(uint32_t type)

Print information about an ipV6 address for each bit present in C<type>.

  const ni_iff_t ni_lx_type2txt[] = {
	{ IPV6_ADDR_ANY,		"unknown" },
	{ IPV6_ADDR_UNICAST,		"unicast" },
	{ IPV6_ADDR_MULTICAST,		"multicast" },
	{ IPV6_ADDR_ANYCAST,		"anycast" },
	{ IPV6_ADDR_LOOPBACK,		"loopback" },
	{ IPV6_ADDR_LINKLOCAL,		"link-local" },
	{ IPV6_ADDR_SITELOCAL,		"site-local" },
	{ IPV6_ADDR_COMPATv4,		"compat-v4" },
	{ IPV6_ADDR_SCOPE_MASK,		"scope-mask" },
	{ IPV6_ADDR_MAPPED,		"mapped" },
	{ IPV6_ADDR_RESERVED,		"reserved" },
	{ IPV6_ADDR_ULUA,		"uniq-lcl-unicast" },
	{ IPV6_ADDR_6TO4,		"6to4" },
	{ IPV6_ADDR_6BONE,		"6bone" },
	{ IPV6_ADDR_AGU,		"global-unicast" },
	{ IPV6_ADDR_UNSPECIFIED,	"unspecified" },
	{ IPV6_ADDR_SOLICITED_NODE,	"solicited-node" },
	{ IPV6_ADDR_ISATAP,		"ISATAP" },
	{ IPV6_ADDR_PRODUCTIVE,		"productive" },
	{ IPV6_ADDR_6TO4_MICROSOFT,	"6to4-ms" },
	{ IPV6_ADDR_TEREDO,		"teredo" },
	{ IPV6_ADDR_ORCHID,		"orchid" },
	{ IPV6_ADDR_NON_ROUTE_DOC,	"non-routeable-doc" }
  };


=item int ni_sizeof_type2txt()

Returns the size of the above table.

=item u_int ni_get_scopeid(struct sockaddr_in6 * sin6)

On systems using KAME, this function extracts and returns the scope from field 2 of the
ipV6 address and sets fields 2,3 to zero. On all other systems it returns

	sin6->sin6_scopeid

   scope flags     rfc-2373

        0         reserved
        1       node-local
        2       link-local
        3         unassigned
        4         unassigned
        5       site-local
        6         unassigned
        7         unassigned
        8       organization-local
        9         unassigned
        A         unassigned
        B         unassigned
        C         unassigned
        D         unassigned
        E       global scope
        F         reserved

=item void * ni_memdup(void *memp, int size)

Allocate memory of for B<size> and copy contents from B<memp>. Returns NULL
on error and sets B<errno> to ENOMEM.

=item void ni_plen2mask(void * in_addr, int plen, int sizeofaddr)

Create a NETMASK string from a prefix length

For ipV4: ni_plen2mask(&in_addr, cidr, sizeof(struct in_addr));

For ipV6: ni_plen2mask(&in6_addr, cidr, sizeof(struct in6_addr));

=item int ni_prefix(void * ap, int len, int size)

Calculated the prefix length for a NETMASK where *ap points to the binary
representation of the NETMASK and size is the number of bytes in the mask.

For ipV4: ni_prefix(&in_addr,sizeof(struct in_addr));

For ipV6: ni_prefix(&in6_addr,sizeof(struct(in6_addr));

=item int ni_refresh_ifreq(int fd, struct ifconf *ifc, void **oifr,
	void **olifr, struct ni_ifconf_flavor * nifp)

Some OS lose scope on the particular device/addr
handle when certain ioctl's are performed. This
function refreshs the ifconf chain and positions
the pointers in the exact same spot with fresh scope.

See ni_in6_ifreq.c and ni_af_net6.c for usage. Search for the
string B<refreshifr>. Code snippit looks like:

	nifp->refreshir 


=head1 COPYRIGHT

	Copyright 2008-2009 - Michael Robinton

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2, or (at your option)
any later version.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
General Public License in the file named "Copying" for more details.

You should also have received a copy of the GNU General Public
License along with this program in the file named "Copying". If not,
write to the

	Free Software Foundation, Inc.
	59 Temple Place, Suite 330
	Boston, MA  02111-1307, USA

or visit their web page on the internet at:

	http://www.gnu.org/copyleft/gpl.html.

=cut

1;
