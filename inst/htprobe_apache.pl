#!/usr/bin/perl -w

=head1 Name

apache.pl - installation script to probe apache configuration

=head1 Description

This script is called during "make" to probe the Apache configuration.
It accomplishes this by parsing the output from httpd, reading the
default system httpd.conf and asking the user questions.  Output
collected in "apache.db".

=head1 Author

Sam Tregar <stregar@about-inc.com>

=head1 See Also

L<Bric::Admin>

=cut

use strict;
use FindBin;
use lib "$FindBin::Bin/lib";
use Bric::Inst qw(:all);
use File::Spec::Functions;
use Data::Dumper;

# check whether questions should be asked
my $QUIET = ($ARGV[0] and $ARGV[0] eq 'QUIET') || $ENV{DEVELOPER};

print "\n\n==> Probing Apache Configuration <==\n\n";

our (%AP, $REQ);
do "./required.db" or die "Failed to read required.db : $!";

# setup some defaults.
$AP{user}       = get_default("APACHE_USER") || 'nobody';
$AP{group}      = get_default("APACHE_GROUP") || 'nobody';
$AP{port}       = get_default("APACHE_PORT") || 80;
$AP{ssl_port}   = get_default("APACHE_SSL_PORT") || 443;
chomp ($AP{server_name} = get_default("APACHE_HOSTNAME") || `hostname`);

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

    # If the conf file doesn't exist, check for the funny location that
    # Debian uses.
    unless (-e $AP{conf_file}) {
        $AP{conf_file} = "/usr/share/doc/apache-perl/examples/httpd.conf"
          if -e "/usr/share/doc/apache-perl/examples/httpd.conf";
    }

    # read in conf file contents.
    $AP{conf} = slurp_conf($AP{conf_file});

    # Read in any included configuration files.
    for ($AP{conf} =~ /^\s*Include\s+(.+)$/gim) {
        $AP{conf} .= "\n" . slurp_conf($1);
    }
}

sub slurp_conf {
    my $file = shift;
    return '' unless -e $file;
    print "Reading Apache conf file: $file.\n";
    open CONF, $file or warn("Cannot open '$file': $!\n"), return '';
    return join '', <CONF>;
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
    hard_fail("Unable to extract static modules from `$REQ->{APACHE_EXE} -l`.")
        unless exists $AP{static_modules}{http_core};

    # set dso flag if mod_so.c is compiled in
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

    my (@missing);
    # loop over required modules
 MOD:
    foreach my $mod (qw(perl log_config mime alias apache_ssl ssl)) {
        # first look in static modules
        if (exists $AP{static_modules}{"mod_$mod"} ||
           ($mod eq 'apache_ssl' && exists $AP{static_modules}{$mod})) {
            $AP{$mod} = 1 if $mod =~ /ssl$/;
            next;
        }

        # try DSO
        if ($AP{dso}) {
            # try modules specified in AddModule/LoadModule pairs
            if (($AP{add_modules}{"mod_$mod"} ||
                 ( $mod eq 'apache_ssl' && $AP{add_modules}{$mod})) and
                $AP{load_modules}{"${mod}_module"}                  and
                -e catfile($AP{HTTPD_ROOT}, 
                           $AP{load_modules}{"${mod}_module"})) {
                $AP{$mod} = 1 if $mod =~ /ssl$/;
                next MOD;
            # On some platforms, "log_config" can actually be loaded via
            # AddModule as "config_log".
            } elsif ($mod eq 'log_config' and $AP{add_modules}{"mod_$mod"} and
                     $AP{load_modules}{config_log_module}                  and
                     -e catfile($AP{HTTPD_ROOT},
                                 $AP{load_modules}{config_log_module})) {
                next MOD;
            }

            # The apache-perl package provided by Debian doesn't
            # use the AddModule directive.  Also it uses the full
            # path to the module on the LoadModule line.
            if ($AP{load_modules}{"${mod}_module"} and
                file_name_is_absolute($AP{load_modules}{"${mod}_module"}) and
                -e $AP{load_modules}{"${mod}_module"}) {
                $AP{$mod} = 1 if $mod =~ /ssl$/;
                next MOD;
            }

            # last chance, see if we can find them in on the
            # filesystem by guessing.  This comes in handy if someone
            # decides to install a DSO module but doesn't put it in
            # their default conf file.  Like Redhat 7.2 and mod_proxy.

            # potential paths for modules
            foreach my $path (catdir($AP{HTTPD_ROOT}, "modules"),
                              catdir($AP{HTTPD_ROOT}, "libexec"),
                              '/usr/lib/apache/1.3',
                              '/usr/lib/apache/modules',
                              '/usr/lib/apache/libexec',
                              '/usr/lib/httpd',
                              '/usr/local/lib/apache/modules',
                              '/usr/local/lib/apache/libexec',
                             ) {

                # perl uses libfoo.so format filenames
                if ($mod eq 'perl') {
                    if (-e ($_ = catfile($path, "lib${mod}.so"))) {
                        $AP{add_modules}{"mod_$mod"} = 1;
                        $AP{load_modules}{"${mod}_module"} = $_;
                        $AP{$mod} = 1 if $mod =~ /ssl$/;
                        next MOD;
                    }
                }

                # everything else is mod_foo.so.  Not an elsif in case
                # perl is sometimes mod_foo.so too.  I can imagine a
                # package maintainer getting smart and "fixing" it.
                if (-e ($_ = catfile($path, "mod_${mod}.so"))) {
                    $AP{add_modules}{"mod_$mod"} = 1;
                    $AP{load_modules}{"${mod}_module"} = $_;
                    $AP{$mod} = 1 if $mod =~ /ssl$/;
                    next MOD;
                }
            }
        }

        # missing module
        # ssl missing is A-OK
        push @missing, $mod unless $mod =~ /ssl$/;
    }

    hard_fail("The following Apache modules are required by Bricolage and\n",
              "are missing from your installation:\n",
              (map { "\tmod_$_\n" } @missing), "\n")
      if @missing;

    # Make sure that a DSO mod_perl is okay.
    unless ($AP{static_modules}{mod_perl}) {
        # Check how Perl was compiled.
        require Config;
        if ($Config::Config{usemymalloc} eq 'y'
            && defined $Config::Config{bincompat5005}) {
            hard_fail("mod_perl must be either statically compiled into "
                     . "Apache or else be compiled with a Perl compiled\n"
                     . "with \"usemymalloc='n'\" or without "
                     . "\"bincompat5005\". See this FAQ for more information:"
                     . "\n\n  http://perl.apache.org/docs/1.0/guide/install."
                     . "html#When_DSO_can_be_Used\n\n");
        }
    }

    print "All required modules found.\n";
}

# confirm configuration with the user
sub confirm {
    print <<END;
====================================================================

Your Apache configuration suggested the following defaults. Press
[return] to confirm each item or type an alternative.  In most cases
the default should be correct.

END

    ask_confirm("Apache User:\t\t\t",  \$AP{user}, $QUIET);
    ask_confirm("Apache Group:\t\t\t", \$AP{group}, $QUIET);
    ask_confirm("Apache Port:\t\t\t",  \$AP{port}, $QUIET);
    ask_confirm("Apache Server Name:\t\t",  \$AP{server_name}, $QUIET);
    my $have_ssl = $AP{ssl} || $AP{apache_ssl} ? 1 : 0;
    my $use_ssl = get_default('SSL');
    $use_ssl = $have_ssl unless defined $use_ssl;

    if ($have_ssl) {
        # Get the key and cert files.
        if (ask_yesno("Do you want to use SSL?", $use_ssl, $QUIET)) {
            $AP{ssl_key} = get_default('SSL_KEY') ||
                catfile($AP{HTTPD_ROOT}, 'conf', 'ssl.key', 'server.key');
            $AP{ssl_cert} = get_default('SSL_CERT') ||
                catfile($AP{HTTPD_ROOT}, 'conf', 'ssl.crt','server.crt');

            if ($AP{ssl} and $AP{apache_ssl}) {
                $AP{ssl} = ask_choice(
                    'Which SSL module do you use? (apache_ssl or mod_ssl) ',
                    [ 'mod_ssl', 'apache_ssl' ],
                    'mod_ssl',
                    $QUIET
                );
            } else {
                $AP{ssl} = $AP{ssl} ? 'mod_ssl' : 'apache_ssl';
            }
            ask_confirm("Apache SSL Port:\t\t",     \$AP{ssl_port}, $QUIET);
            ask_confirm("SSL certificate file\t\t", \$AP{ssl_cert}, $QUIET);
            ask_confirm("SSL certificate key file\t", \$AP{ssl_key}, $QUIET);
        } else {
            $AP{ssl} = 0;
        }
    } else {
        $AP{ssl} = 0;
    }

    print <<END;

====================================================================
END
}
