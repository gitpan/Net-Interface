
/*	BEGIN ni_IFF_inc.c	include
 ****************************************************************
 *	DO NOT ALTER THIS FILE					*
 *	IT IS WRITTEN BY Makefile.PL & inst/netsymbols.pl	*
 *	EDIT THOSE INSTEAD					*
 ****************************************************************
 */

const ni_iff_t ni_iff_tab[] = {

	{IFF_ALLMULTI,	"ALLMULTI"},
	{IFF_AUTOMEDIA,	"AUTOMEDIA"},
	{IFF_BROADCAST,	"BROADCAST"},
	{IFF_DEBUG,	"DEBUG"},
	{IFF_LOOPBACK,	"LOOPBACK"},
	{IFF_MASTER,	"MASTER"},
	{IFF_MULTICAST,	"MULTICAST"},
	{IFF_NOARP,	"NOARP"},
	{IFF_NOTRAILERS,	"NOTRAILERS"},
	{IFF_POINTOPOINT,	"POINTOPOINT"},
	{IFF_PORTSEL,	"PORTSEL"},
	{IFF_PROMISC,	"PROMISC"},
	{IFF_RUNNING,	"RUNNING"},
	{IFF_SLAVE,	"SLAVE"}
};

#ifdef HAVE_STRUCT_IN6_IFREQ
const ni_iff_t ni_iff_tabIN6[] = {

};
#endif
/*	END ni_IFF_inc.c	include		*/
