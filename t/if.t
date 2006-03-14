# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..7\n"; }
END {print "not ok 1\n" unless $loaded;}

#use diagnostics;
use Socket;

require Net::Interface;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

use POSIX qw(EPERM);

my $loopback = ($^O eq 'solaris') ? "lo0" : ($^O eq 'linux') ? "lo" : undef;

my ($i) = Net::Interface->interfaces ();
print $i ? "ok 2\n" : "not ok 2: $!\n";
$i = Net::Interface->new ($i->name);
print $i ? "ok 3\n" : "not ok 3: $!\n";
my $m = $i->mtu (576);
print (($m || $! == EPERM) ? "ok 4\n" : "not ok 4: $!\n");
$m = $i->mtu ($m);
$m = $i->address;
print "missing interface address\nnot "
	unless ($m = inet_ntoa($m));
print "ok 5\n";

package TEST;

@ISA = qw (Net::Interface);
my @y = (__PACKAGE__->new ($loopback))->address;

print "missing interface address in array\nnot "
	unless ($y[2] = main::inet_ntoa($y[2]));
print "ok 6\n";

print "got: $y[2], exp: $m\nnot "
	unless $m eq $y[2];;
print "ok 7\n";
1;