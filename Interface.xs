#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "localStuff.h"

#include <net/if.h>
#include <errno.h>
#include <strings.h>
#ifdef __linux__
#include </usr/include/sys/user.h>
#include <linux/sockios.h>
#endif

#ifdef __cplusplus
}
#endif

/*
** Fix up missing definition
*/

#ifndef IFHWADDRLEN
# define IFHWADDRLEN    6
#endif

/*
** Fix up non-POSIX compliant address family names
*/

#ifndef AF_FILE
# ifdef AF_UNIX
#  define AF_FILE AF_UNIX
# else
#  ifdef AF_LOCAL
#   define AF_FILE AF_LOCAL
#  endif
# endif
#endif

/*
** Fix up missing of struct sockaddr field sa_len
*/

#ifndef SA_LEN
#ifndef HAVE_SA_LEN
static int
__libc_sa_len (const sa_family_t af)
{
   switch(af)
   {
/*
     case AF_APPLETALK:
       return sizeof (struct sockaddr_at);
     case AF_ASH:
       return sizeof (struct sockaddr_ash);
     case AF_AX25:
       return sizeof (struct sockaddr_ax25);
     case AF_ECONET:
       return sizeof (struct sockaddr_ec);      
*/
     case AF_INET:
       return sizeof (struct sockaddr_in);
     case AF_INET6:
       return sizeof (struct sockaddr_in6);
/*
     case AF_IPX:
       return sizeof (struct sockaddr_ipx);
     case AF_LOCAL:
       return sizeof (struct sockaddr_un);
     case AF_PACKET:
       return sizeof (struct sockaddr_ll);
     case AF_ROSE:
       return sizeof (struct sockaddr_rose);
*/
   }
   return -1;
}
#define SA_LEN(sa) __libc_sa_len(((struct sockaddr)(sa)).sa_family)
#else
#define SA_LEN(sa) ((sa).sa_len)
#endif
#endif

/*
** Fix up variable length of struct ifr and missing of struct sockaddr field SA_LEN
*/

#ifndef _SIZEOF_ADDR_IFREQ
#define _SIZEOF_ADDR_IFREQ(ifr) \
        (SA_LEN((ifr).ifr_addr) > sizeof(struct sockaddr) ? \
         (sizeof(struct ifreq) - sizeof(struct sockaddr) + \
          SA_LEN((ifr).ifr_addr)) : sizeof(struct ifreq))
#endif

/*
** Fix up slightly damaged ifreq entries
*/

#ifndef ifr_mtu
#define ifr_mtu ifr_ifru.ifru_metric
#endif

/*
** Function select values for int and sockaddr access routines
*/

enum _int_fields
{
  NI_FLAGS = 1, NI_MTU, NI_METRIC
};

enum _sockaddr_fields
{
  NI_ADDR = 1, NI_BRDADDR, NI_NETMASK, NI_HWADDR, NI_DSTADDR
};

/*
** Short-cuts to reduce typing
*/

typedef struct ifreq ifreq;

typedef union sockaddr_all {
  struct sockaddr sa;
  struct sockaddr_in sin;
} sockaddr_all;

#define NI_REF_CHECK(ref) \
        if (!SvROK (ref) || !SvOBJECT (SvRV(ref)) || !SvREADONLY (SvRV(ref))) \
          croak ("Can't call method \"%s\" without a valid object reference", GvNAME (CvGV (cv)));

#define NI_CONNECT(fd) \
        if ((fd = socket (PF_INET, SOCK_DGRAM, 0)) == -1) \
          XSRETURN_EMPTY;

#define NI_ACCESS(fd,value,buf) \
        if (ioctl (fd, value, buf) == -1) { \
	  perror("NI_ACCESS: "); \
          NI_DISCONNECT (fd); \
          XSRETURN_EMPTY; \
        }

#define NI_DISCONNECT(fd) close (fd)

/*
** max size of struct ifreq can be > PATH_MAX -> let's alloc MY_PGSIZE
*/
#define        NI_NEW_REF(rv,sv,stash) \
        sv = newSV (0); \
        rv = sv_2mortal (newRV_noinc (sv)); \
        sv_bless (rv, stash); \
        SvGROW (sv, MY_PGSIZE); \
        SvREADONLY_on (sv); \
        XPUSHs (rv);

#define        NI_NEW_IFREQ_REF(rv,sv,stash,ifr) \
        sv = newSV (0); \
        rv = sv_2mortal (newRV_noinc (sv)); \
        sv_bless (rv, stash); \
        SvGROW (sv, _SIZEOF_ADDR_IFREQ(*ifr)); \
        SvREADONLY_on (sv); \
        XPUSHs (rv);

#define NI_MAX_ARGS(x) \
        if (items > x) \
          croak ("Too many arguments for method \"%s\"", GvNAME (CvGV (cv)))

/*
** Fix up for perl's New()/Renew() interface
*/
typedef struct { uint8_t pgsize_array[MY_PGSIZE]; } pgsize_as;

MODULE = Net::Interface        PACKAGE = Net::Interface

#sub ifa_broadaddr () { &ifa_ifu. &ifu_broadaddr;}
#sub ifa_dstaddr () { &ifa_ifu. &ifu_dstaddr;}

void
interfaces (ref)
  SV *ref;

  PROTOTYPE: $

  PREINIT:
    struct ifconf ifc;
    struct ifreq *ifr, *lifr;
    int fd, n;
    HV *stash;
    SV *rv, *sv;

  PPCODE:
    {
      NI_CONNECT (fd);
      bzero(&ifc, sizeof(ifc));
#ifdef SIOCGIFCOUNT
      if (ioctl (fd, SIOCGIFCOUNT, &ifc) != -1) {
        New (0xbad, ifr, ifc.ifc_len, struct ifreq);
        ifc.ifc_req = ifr;
        ifc.ifc_len *= sizeof (*ifr);
        if (ioctl (fd, SIOCGIFCONF, &ifc) == -1) {
          Safefree (ifr);
          close (fd);
          XSRETURN_EMPTY;
        }
      }
      else
#endif
      {
        n = 1;
        /* New (0xbad, ifr, n, pgsize_as); */
        ifr = (struct ifreq *)safemalloc( (MEM_SIZE)((n)*sizeof(pgsize_as)) );
        do {
          n *= 2;
          ifr = (struct ifreq *)saferealloc( (Malloc_t)ifr, (MEM_SIZE)(n*sizeof(pgsize_as)) );
          ifc.ifc_req = ifr;
          ifc.ifc_len = n * sizeof(pgsize_as);
        }
        while( ( ioctl( fd, SIOCGIFCONF, &ifc ) == -1 ) ||
               ( ifc.ifc_len >= ( (n-1) * sizeof(pgsize_as))) );
        NI_DISCONNECT (fd);
      }
      stash = SvROK (ref) ? SvSTASH (SvRV (ref)) : gv_stashsv (ref, 0);

      lifr = (struct ifreq *)&ifc.ifc_buf[ifc.ifc_len];
      while (ifr < lifr)
      {
        struct sockaddr *sa = &ifr->ifr_ifru.ifru_addr;
#ifndef __linux__
        if( AF_LINK != sa->sa_family ) /* collect only the AF_LINK entries */
        {
          ifr = (struct ifreq *)(((char *)ifr) + _SIZEOF_ADDR_IFREQ(*ifr));
          continue;
        }
#endif
        NI_NEW_IFREQ_REF (rv, sv, stash, ifr);
        memmove (SvPVX (sv), ifr, _SIZEOF_ADDR_IFREQ(*ifr));
        ifr = (struct ifreq *)(((char *)ifr) + _SIZEOF_ADDR_IFREQ(*ifr));
      }
      Safefree (ifc.ifc_req);
    }

void
new (...)

  PROTOTYPE: $$

  PREINIT:
    SV *rv, *sv;
    HV *stash;
    int fd;

  PPCODE:
    {
      NI_MAX_ARGS (2);
      stash = SvROK (ST (0)) ? SvSTASH (SvRV (ST (0))) : 
        gv_stashsv (ST (0), 0);
      NI_NEW_REF (rv, sv, stash);
      Move (SvPV (ST (1), PL_na), ((ifreq *) SvPVX (sv))->ifr_name, 
            SvCUR (ST (1)) + 1, char);
      NI_CONNECT (fd);
      NI_ACCESS (fd, SIOCGIFFLAGS, SvPVX (sv));
      NI_DISCONNECT (fd);
      XSRETURN (1);
    }

void
name (...)

  PROTOTYPE: $

  PPCODE:
    {
      NI_MAX_ARGS (1);
      NI_REF_CHECK (ST (0));
      XSRETURN_PV (SvPVX (SvRV (ST (0))));
    }

void
_int_value (...)

  PROTOTYPE: $;$

  PREINIT:
    int fd;
    ifreq *ifr;

  ALIAS:
    flags = NI_FLAGS
    mtu = NI_MTU
    metric = NI_METRIC

  PPCODE:
    {
      NI_MAX_ARGS (2);
      NI_REF_CHECK (ST (0));
      NI_CONNECT (fd);
      ifr = (ifreq *) SvPVX (SvRV (ST (0)));
      ST (0) = &PL_sv_undef;
      switch (ix) {
      case NI_FLAGS:
        NI_ACCESS (fd, SIOCGIFFLAGS, ifr);
        XST_mIV (0, ifr->ifr_flags);
        break;

      case NI_MTU:
        NI_ACCESS (fd, SIOCGIFMTU, ifr);
        XST_mIV (0, ifr->ifr_mtu);
        break;

      case NI_METRIC:
        NI_ACCESS (fd, SIOCGIFMETRIC, ifr);
        XST_mIV (0, ifr->ifr_metric);
        break;
      }
      if (items == 2) {
        switch (ix) {
        case NI_FLAGS:
          ifr->ifr_flags = SvIV (ST (1));
          NI_ACCESS (fd, SIOCSIFFLAGS, ifr);
          break;

        case NI_MTU:
          ifr->ifr_mtu = SvIV (ST (1));
          NI_ACCESS (fd, SIOCSIFMTU, ifr);
          break;

        case NI_METRIC:
          ifr->ifr_metric = SvIV (ST (1));
          NI_ACCESS (fd, SIOCSIFMETRIC, ifr);
          break;
        }
      }
      NI_DISCONNECT (fd);
      XSRETURN (1);
    }

void
_addr_value (...)

  PROTOTYPE: $;$

  PREINIT:
    int fd, array = 0;
    ifreq *ifr;
    sockaddr_all sa;

  ALIAS:
    address = NI_ADDR
    broadcast = NI_BRDADDR
    netmask = NI_NETMASK
    hwaddress = NI_HWADDR
    destination = NI_DSTADDR

  PPCODE:
    {
      NI_MAX_ARGS (2);
      NI_REF_CHECK (ST (0));
      NI_CONNECT (fd);
      ifr = (ifreq *) SvPVX (SvRV (ST (0)));
      ST (0) = &PL_sv_undef;
      switch (ix) {
      case NI_ADDR:
        NI_ACCESS (fd, SIOCGIFADDR, ifr);
        break;

      case NI_BRDADDR:
        NI_ACCESS (fd, SIOCGIFBRDADDR, ifr);
        break;

      case NI_NETMASK:
        NI_ACCESS (fd, SIOCGIFNETMASK, ifr);
        break;
#ifdef SIOCGIFHWADDR
      case NI_HWADDR:
      NI_ACCESS (fd, SIOCGIFHWADDR, ifr);
      break;
#endif
      case NI_DSTADDR:
        NI_ACCESS (fd, SIOCGIFDSTADDR, ifr);
        break;
      }
      Move (&(ifr->ifr_addr), &sa, 1, sockaddr_all);
#ifdef _AIX
      if( AF_UNSPEC == sa.sa.sa_family && NI_NETMASK == ix )
          sa.sa.sa_family = AF_INET;
#endif
      if (items == 2) {
        switch (ix) {
        case NI_ADDR:
          NI_ACCESS (fd, SIOCGIFADDR, ifr);
          break;

        case NI_BRDADDR:
          NI_ACCESS (fd, SIOCGIFBRDADDR, ifr);
          break;

        case NI_NETMASK:
          NI_ACCESS (fd, SIOCGIFNETMASK, ifr);
          break;
/*
#ifdef SIOCGIFHWADDR
        case NI_HWADDR:
          NI_ACCESS (fd, SIOCGIFHWADDR, ifr);
          break;
#endif
*/
        case NI_DSTADDR:
          NI_ACCESS (fd, SIOCGIFDSTADDR, ifr);
          break;
        }
      }
      NI_DISCONNECT (fd);
      array = (GIMME_V == G_ARRAY);
      if (array) {
        EXTEND (sp, 2);
        PUSHs (sv_2mortal (newSViv (sa.sa.sa_family)));
      }
      switch (sa.sa.sa_family) {
      case AF_INET:
        if (array)
          PUSHs (sv_2mortal (newSViv (sizeof (sa.sin.sin_addr))));
        PUSHs (sv_2mortal (newSVpv ((char *) &sa.sin.sin_addr,
                                      sizeof (sa.sin.sin_addr))));
        break;

      case AF_FILE:
        if (array)
/*Does not work */
/*          PUSHs (sv_2mortal (newSViv (sizeof (sa.sin.sin_addr))));*/
/* Bad hack to get hardware address, copied INET mechanism from above,
   returned last four digits of MAC, munge address and abs size to 6 */
          PUSHs (sv_2mortal (newSViv (IFHWADDRLEN)));
        PUSHs (sv_2mortal (newSVpv ((char *) (&sa.sa.sa_data),
                                      IFHWADDRLEN)));
      }
    }

#sub ifr_map () { &ifr_ifru. &ifru_map;}
#sub ifr_slave () { &ifr_ifru. &ifru_slave;}
#sub ifr_data () { &ifr_ifru. &ifru_data;}
#sub ifc_buf () { &ifc_ifcu. &ifcu_buf;}
#sub ifc_req () { &ifc_ifcu. &ifcu_req;}

