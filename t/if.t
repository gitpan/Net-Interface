# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

use Test::More tests => 7;

BEGIN { use_ok( 'Net::Interface' ); }
my $loaded = 1;
END {print "not ok 1\n" unless $loaded;}

#use diagnostics;
use Socket;

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

use POSIX qw(EPERM);

# use 'lo0' as default for all systems except linux - keeps open TODO for e.g. win32
my $loopback = ($^O eq 'linux') ? 'lo' : 'lo0';

my ($i) = Net::Interface->interfaces ();
#print $i ? "ok 2\n" : "not ok 2: $!\n";
ok( $i );
$i = Net::Interface->new ($i->name());
#print $i ? "ok 3\n" : "not ok 3: $!\n";
isa_ok( $i, 'Net::Interface' );
my $m = $i->mtu (576);
#print (($m || $! == EPERM) ? "ok 4\n" : "not ok 4: $!\n");
ok( $m || $! == EPERM );
$m = $i->mtu ($m);
$m = $i->address();
ok( $m = inet_ntoa($m), "getting interface address" );
#print "missing interface address\nnot "
#	unless ($m = inet_ntoa($m));
#print "ok 5\n";

my @y = (TEST->new ($loopback))->address();

ok( $y[2] = main::inet_ntoa($y[2]), 'interface address in array' );

ok( $m eq $y[2], "expected '$m' but got '$y[2]'" );

package TEST;

# otherwise this line is not executed before related test is run
BEGIN { @ISA = qw (Net::Interface); };

#print "missing interface address in array\nnot "
#	unless ($y[2] = main::inet_ntoa($y[2]));
#print "ok 6\n";

#print "got: $y[2], exp: $m\nnot "
#	unless $m eq $y[2];;
#print "ok 7\n";

1;
