#!/usr/bin/perl -w

=head1 NAME

apache.pl - installation script to probe apache configuration

=head1 VERSION

$Revision: 1.3 $

=head1 DATE

$Date: 2002-05-10 19:44:54 $

=head1 DESCRIPTION

This script is called during "make" to probe the Apache configuration.
It accomplishes this by parsing the output from httpd, reading the
default system httpd.conf and asking the user questions.  Output
collected in "apache.db".

=head1 AUTHOR

Sam Tregar <stregar@about-inc.com>

=head1 SEE ALSO

L<Bric::Admin>

=cut

use strict;
use FindBin;
use lib "$FindBin::Bin/lib";
use Bric::Inst qw(:all);
use File::Spec::Functions;
use Data::Dumper;

print "\n\n==> Probing Apache Configuration <==\n\n";

our %AP;
our $REQ;
do "./required.db" or die "Failed to read required.db : $!";

# setup some reasonable defaults.  these will all get overridden, but
# better safe than sorry.
$AP{user}  = 'nobody';
$AP{group} = 'nobody';
$AP{port}  = 80;
$AP{ssl}   = 0;
chomp ($AP{server_name} = `hostname`);

read_conf();
read_modules();
get_user_and_group();
get_port();
get_dso_data() if $AP{dso};
get_types_config();
check_modules();
confirm();

# done with raw conf
delete $AP{conf};

# all done, dump out apache database, announce success and exit
open(OUT, ">apache.db") or die "Unable to open apache.db : $!";
print OUT Data::Dumper->Dump([\%AP],['AP']);
close OUT;

print "\n\n==> Finished Probing Apache Configuration <==\n\n";
exit 0;

# find and read configuration file
sub read_conf {    
    print "Extracting configuration data from `$REQ->{APACHE_EXE} -V`.\n";

    my $data = `$REQ->{APACHE_EXE} -V`;
    hard_fail("Unable to extract needed data from `$REQ->{APACHE_EXE} -V`.")
	unless $data;
    
    # parse out definitions and put them in AP
    while ($data =~ /^\s*-D\s+([\w]+)(?:="([^"]+)")?/mg) {
	$AP{uc($1)} = defined $2 ? $2 : 1;
    }
    hard_fail("Unable to extract conf file location from ", 
	      "`$REQ->{APACHE_EXE} -V`.")
	unless exists $AP{HTTPD_ROOT} and exists $AP{SERVER_CONFIG_FILE};

    # figure out conf_file
    if (file_name_is_absolute($AP{SERVER_CONFIG_FILE})) {
	$AP{conf_file} = $AP{SERVER_CONFIG_FILE};
    } else {
	$AP{conf_file} = catfile($AP{HTTPD_ROOT}, $AP{SERVER_CONFIG_FILE});
    }

    # read in conf file contents if file exists
    if (open(CONF, $AP{conf_file})) {
	print "Reading Apache conf file: $AP{conf_file}.\n";
	$AP{conf} = join('', <CONF>);
	close CONF;
    } elsif (open(CONF, "/usr/share/doc/apache-perl/examples/httpd.conf")) {
	# debian keeps an example conf in a funny location, maybe it's there?
	$AP{conf_file} = "/usr/share/doc/apache-perl/examples/httpd.conf";
	print "Reading Apache conf file: $AP{conf_file}.\n";
	$AP{conf} = join('', <CONF>);
	close CONF;
    } else {
	$AP{conf} = '';
    }    
}

# parse list of Apache modules
sub read_modules {
    print "Extracting static module list from `$REQ->{APACHE_EXE} -l`.\n";
    
    my $data = `$REQ->{APACHE_EXE} -l`;
    hard_fail("Unable to extract needed data from `$REQ->{APACHE_EXE} -l`.")
	unless $data;
    
    # parse out definitions and put them in AP
    while ($data =~ /^\s*(\w+)\.c\s*$/mg) {
	$AP{static_modules}{$1} = 1;
    }
    hard_fail("Unable to extract static modules from ", 
	      "`$REQ->{APACHE_EXE} -V`.")
	unless exists $AP{static_modules}{http_core};

    # set dso flag of mod_so.c is compiled in
    $AP{dso} = exists $AP{static_modules}{mod_so} ? 1 : 0;
    print "Your Apache ", $AP{dso} ? "supports" : "doesn't support", 
	" loadable modules (DSOs).\n";
}

# find User and Group declarations
sub get_user_and_group {
    if ($AP{conf} =~ /^\s*User\s+(.*)$/m) {	
	$AP{user} = $1;
	print "Found Apache user: $AP{user}\n";
    }
    if ($AP{conf} =~ /^\s*Group\s+(.*)$/m) {
	$AP{group} = $1;
	print "Found Apache group: $AP{group}\n";
    }
}

# find the default port setting
sub get_port {
    if ($AP{conf} =~ /^\s*Port\s+(.*)$/m) {
	$AP{port} = $1;
    }
}

# find AddModule and LoadModule data for DSO Apaches
sub get_dso_data {
    # get a hash of load module directives (name => filename)
    while ($AP{conf} =~ /^\s*LoadModule\s+(\S+)\s+(.*)$/gm) {
	$AP{load_modules}{$1} = $2;
    }
    # get a hash of add module directives
    while ($AP{conf} =~ /^\s*AddModule\s+(\w+).c$/gm) {
	$AP{add_modules}{$1} = 1;
    }
}

sub get_types_config {
    if ($AP{conf} =~ /^\s*TypesConfig\s+(.*)$/m) {
	$AP{types_config} = $1;
    }
}

# check that the modules we need are available, one way or another
sub check_modules {
    print "Checking for required Apache modules...\n";

    my @missing;
    # loop over required modules
 MOD: 
    foreach my $mod (qw(perl rewrite proxy ssl log_config mime alias)) {
	# first look in static modules
	next if exists $AP{static_modules}{"mod_$mod"};

	# try DSO
	if ($AP{dso}) {
	    # try modules specified in AddModule/LoadModule pairs
	    if ($AP{add_modules}{"mod_$mod"}       and
		$AP{load_modules}{"${mod}_module"} and
		-e catfile($AP{HTTPD_ROOT}, 
			   $AP{load_modules}{"${mod}_module"})) {
		next MOD;
	    }
	    
	    # The apache-perl package provided by Debian doesn't 
	    # use the AddModule directive.  Also it uses the full 
	    # path to the module on the LoadModule line.
	    if ($AP{load_modules}{"${mod}_module"} and
		file_name_is_absolute($AP{load_modules}{"${mod}_module"}) and
		-e $AP{load_modules}{"${mod}_module"}) {
		next MOD;
	    }
	    
	    # last chance, see if we can find them in on the
	    # filesystem by guessing.  This comes in handy if someone
	    # decides to install a DSO module but doesn't put it in
	    # their default conf file.  Like Redhat 7.2 and mod_proxy.

	    # potential paths for modules
	    foreach my $path (catdir($AP{HTTPD_ROOT}, "modules"),
			      catdir($AP{HTTPD_ROOT}, "libexec"),
			      "/usr/lib/apache/1.3"              ) {		

		# perl and proxy use libfoo.so format filenames
		if ($mod eq 'perl' or $mod eq 'proxy') {
		    if (-e ($_ = catfile($path, "lib${mod}.so"))) {
			$AP{add_modules}{"mod_$mod"} = 1;
			$AP{load_modules}{"${mod}_module"} = $_;
			next MOD;
		    } 
		}

		# everything else is mod_foo.so.  Not an elsif in case
		# perl or proxy are sometimes mod_foo.so too.  I can
		# imagine a package maintainer getting smart and "fixing"
		# them.
		if (-e ($_ = catfile($path, "mod_${mod}.so"))) {
		    $AP{add_modules}{"mod_$mod"} = 1;
		    $AP{load_modules}{"${mod}_module"} = $_;
		    next MOD;
		} 
	    }
	}

	# missing module
	push @missing, $mod;
    }

    # ssl missing is A-OK
    if (grep { /^ssl$/ } @missing) {
	$AP{ssl_avail} = 0;
	@missing = grep { !/^ssl$/ } @missing;
    } else {
	$AP{ssl_avail} = 1;
    }
    
    hard_fail("The following Apache modules are required by Bricolage and\n",
	      "are missing from your installation:\n",
	      (map { "\tmod_$_\n" } @missing), "\n")
      if @missing;

    print "All required modules found.\n";
}

# confirm configuration with the user
sub confirm {
    print <<END;
====================================================================

Your Apache configuration suggested the following defaults.  Press
[return] to confirm each item or type an alternative.  In most cases
the default should be correct.

END
  
    ask_confirm("Apache User:\t\t",  \$AP{user});
    ask_confirm("Apache Group:\t\t", \$AP{group});
    ask_confirm("Apache Port:\t\t",  \$AP{port});
    $AP{ssl} = ask_yesno("Use SSL:\t\t [".($AP{ssl} ? 'yes' : 'no')."] ", 
			 $AP{ssl});
    ask_confirm("Apache Server Name:\t",  \$AP{server_name});
    
    print <<END;

====================================================================
END
}
