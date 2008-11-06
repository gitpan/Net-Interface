# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

use Test::More tests => 10;

# test 1
BEGIN { use_ok( 'Net::Interface' ); }
my $loaded = 1;
END {print "not ok 1\n" unless $loaded;}

#use diagnostics;
use Socket;

######################### End of black magic.

# find the local interface

my($haveifs,$m,$i,$name,@allifs,@ifnames,%uniqifs);
my $loopback = (defined $Socket::{INADDR_LOOPBACK})	# broken on some platforms
	? INADDR_LOOPBACK
	: inet_aton('127.0.0.1');

$haveifs = @allifs = Net::Interface->interfaces();	# get all interfaces

SKIP: {
	skip "no interfaces found, possible jail environment", 2 unless $haveifs;
# test 2
	ok(@allifs, 'found interface(s): ' . join( ', ', map { $_->name() } @allifs ) );

# test 3
	@ifnames = map { $_->name() } @allifs;
	%uniqifs = map { $_->name() => 1 } @allifs;
	ok( scalar(@ifnames) == scalar(keys(%uniqifs)), 'interface names are uniq' );

	eval {	foreach (@allifs) {
		  $i = $_;
		  eval {
			local $SIG{__DIE__} = 'DEFAULT';
			$m = $i->address();
			$name = $i->name();
		  };
		  last if $name eq 'lo' || $name eq 'lo0' || $m eq $loopback;
		  $i = undef;
		};
		$loopback = undef if $@;
      die "could not find loopback address" unless defined $i;
	};
}

SKIP: {
	skip "no interfaces found, possible jail environment", 2 unless $haveifs;
	skip "loopback not found, possible jail environment", 2 unless $loopback;
# test 4
	ok(!$@, $@ || "found loopback interface '$name'");

# test 5
	$i = Net::Interface->new ($loopback = $i->name());
	isa_ok( $i, 'Net::Interface' );
}

# test 6
SKIP: {
	skip "no loopback interface, possible jail environment", 1 unless $haveifs && $loopback;
	local $! = 0;
	eval {$m = $i->mtu (576)};
	skip "mtu update because '$!'\n$@", 1 if $!;
	pass("mtu updated");
}

# test 7
SKIP: {
	skip "no loopback interface, possible jail environment", 1 unless $haveifs && $loopback;
	local $! = 0;
	eval {$m = $i->mtu (576)};
	skip "mtu restore because '$!'\n$@", 1 if $!;
	pass("mtu restored");
}

SKIP: {
	skip "no loopback interface, possible jail environment", 3 unless $haveifs && $loopback;
# test 8
	$m = $i->address();
	ok( $m = inet_ntoa($m), "getting interface address" );

# test 9
	my @y = (TESTme->new ($loopback))->address();
	ok( $y[2] = inet_ntoa($y[2]), 'interface address in array' );

# test 10
	ok( $m eq $y[2], "'$m' eq '$y[2]'" );
}

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
