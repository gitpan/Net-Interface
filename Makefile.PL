use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile(
	'NAME'	 => 'Net::Interface',
	'VERSION_FROM' => 'Interface.pm', # finds $VERSION
	'LIBS'	 => ['-lc'],   # e.g., '-lm' 
	'DEFINE' => '',     # e.g., '-DHAVE_SOMETHING' 
	'INC'	 => '',     # e.g., '-I/usr/include/other' 
	'dist'	 => {'COMPRESS' => 'gzip', 
		    'SUFFIX' => 'gz'},
	'clean'	 => { FILES    => "*~ tmp* config.log config.status config.h"},
);

sub MY::top_targets {
   package MY;
   my $begin = q|

config :: config.h
	@$(NOOP)

config.h :
	$(SHELL) configure
|;
  my $inherited = shift->SUPER::top_targets(@_);
# whatever additional change, additions that may be needed
  $begin . $inherited;
}
