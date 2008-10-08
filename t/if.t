# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

use Test::More tests => 9;

# test 1
BEGIN { use_ok( 'Net::Interface' ); }
my $loaded = 1;
END {print "not ok 1\n" unless $loaded;}

#use diagnostics;
use Socket;

######################### End of black magic.

# find the local interface

my @allifs = Net::Interface->interfaces();	# get all interfaces

#test 2
ok(@allifs, 'found interface(s)');
my $loopback = INADDR_LOOPBACK;
my($i,$m);

eval {	foreach (@allifs) {
	  $i = $_;
	  last if ($m = $i->address()) eq $loopback;
	  die "could not find loopback address";
	}
};

# test 3
ok(!$@, $@ || 'found loopback interface');

# test 4
$i = Net::Interface->new ($loopback = $i->name());
isa_ok( $i, 'Net::Interface' );

# test 5
SKIP: {
	local $! = 0;
	eval {$m = $i->mtu (576)};
	skip "mtu update because '$!'\n$@", 1 if $!;
	pass("mtu updated");
}

# test 6
SKIP: {
	local $! = 0;
	eval {$m = $i->mtu (576)};
	skip "mtu restore because '$!'\n$@", 1 if $!;
	pass("mtu restored");
}


# test 7
$m = $i->address();
ok( $m = inet_ntoa($m), "getting interface address" );

# test 8
my @y = (TESTme->new ($loopback))->address();
ok( $y[2] = inet_ntoa($y[2]), 'interface address in array' );

# test 9
ok( $m eq $y[2], "'$m' eq '$y[2]'" );

package TESTme;

# otherwise this line is not executed before related test is run
BEGIN { @ISA = qw (Net::Interface); };

#print "missing interface address in array\nnot "
#	unless ($y[2] = main::inet_ntoa($y[2]));
#print "ok 6\n";

#print "got: $y[2], exp: $m\nnot "
#	unless $m eq $y[2];;
#print "ok 7\n";

1;
