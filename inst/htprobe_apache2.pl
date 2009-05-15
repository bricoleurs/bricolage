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

changes for Apache 2:  Scott Lanning <slanning@cpan.org>, Chris Heiland

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
$AP{user}        = get_default('APACHE_USER')     || 'nobody';
$AP{group}       = get_default('APACHE_GROUP')    || 'nobody';
$AP{port}        = get_default('APACHE_PORT')     || 80;
$AP{ssl_port}    = get_default('APACHE_SSL_PORT') || 443;
$AP{server_name} = get_default('APACHE_HOSTNAME') || `hostname`;
chomp $AP{server_name};

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
print OUT Data::Dumper->Dump([\%AP], ['AP']);
close OUT;
print "\n\n==> Finished Probing Apache Configuration <==\n\n";
exit();


# find and read configuration file
sub read_conf {
    print "Extracting configuration data from `$REQ->{APACHE_EXE} -V`.\n";

    my $data = `$REQ->{APACHE_EXE} -V`;
    hard_fail("Unable to extract needed data from `$REQ->{APACHE_EXE} -V`.")
        unless $data;

    # parse out definitions and put them in AP
    while ($data =~ /^\s*-D\s+([\w]+)(?:="([^"]*)")?/mg) {
        $AP{uc($1)} = defined $2 ? $2 : 1;
    }
    hard_fail("Unable to extract conf file location from ",
              "`$REQ->{APACHE_EXE} -V`.")
        unless exists $AP{HTTPD_ROOT} and exists $AP{SERVER_CONFIG_FILE};

    # figure out conf_file
    # If HTTPD_ROOT eq "", we try to set it to something reasonable here.
    if (file_name_is_absolute($AP{SERVER_CONFIG_FILE})) {
        $AP{conf_file} = $AP{SERVER_CONFIG_FILE};

        if ($AP{HTTPD_ROOT} eq '') {
            # set it to the directory part of SERVER_CONFIG_FILE
            my ($vol, $dir, $file) = File::Spec::Functions::splitpath($AP{SERVER_CONFIG_FILE});
            $AP{HTTPD_ROOT} = catdir($vol, $dir);
        }
    } else {
        if ($AP{HTTPD_ROOT} eq '') {
            $AP{HTTPD_ROOT} = rootdir();
            print qq{`$REQ->{APACHE_EXE} -V` says HTTPD_ROOT="", but we need a directory.\n},
              "This is probably where your httpd.conf is.\n";
            ask_confirm("HTTPD_ROOT directory? ", \$AP{HTTPD_ROOT}, $QUIET);
        }

        $AP{conf_file} = catfile($AP{HTTPD_ROOT}, $AP{SERVER_CONFIG_FILE});
    }

    # read in conf file contents.
    $AP{conf} = slurp_conf($AP{conf_file});

    # Read in any included configuration files.
    # (note: this is wrong in htprobe_apache.pl, where I left it alone.)
    my $included = '';
    while ($AP{conf} =~ /^\s*Include\s+(.+)$/gim) {
        $included .= "\n" . slurp_conf($1);
    }
    $AP{conf} .= $included;
}

sub slurp_conf {
    my $file = shift;
    my @files = ();

    if ($file =~ /\*/) {
        @files = glob($file);
    }
    else {
        return '' unless -e $file and ! -d _;
        push @files, $file;
    }

    # XXX: it's actually worse than this in general....
    # Include also handles directories,
    # even when you don't use a wildcard (*).
    # I didn't implement that because it WORKSFORME
    # (and it's complicated). I just wanted to get TypesConfig.
    # README.Debian says:
    # The Include directive ignores files with names that
    # - do not begin with a letter or number
    # - contain a character that is neither letter nor number nor _-.
    # - contain .dpkg

    my $str = '';
    foreach my $f (@files) {
        next if -d $f;

        print "Reading Apache conf file: $f.\n";
        open my $conf, $f or warn("Cannot open '$f': $!\n"), return '';
        $str .= join('', <$conf>) . "\n";
        close($conf);
    }
    return $str;
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

    # set dso flag of mod_so.c if compiled in
    $AP{dso} = exists $AP{static_modules}{mod_so} ? 1 : 0;
    print "Your Apache ", $AP{dso} ? "supports" : "doesn't support",
        " loadable modules (DSOs).\n";
}

# find User and Group declarations
sub get_user_and_group {
    if ($AP{conf} =~ /^\s*User\s+(.*)$/m) {
        $AP{user} = $1;

        # ubuntu uses env vars; just set it explicitly..
        $AP{user} = 'www-data' if $AP{user} =~ m{^\$};

        print "Found Apache user: $AP{user}\n";
    }
    if ($AP{conf} =~ /^\s*Group\s+(.*)$/m) {
        $AP{group} = $1;

        # ubuntu uses env vars; just set it explicitly..
        $AP{group} = 'www-data' if $AP{group} =~ m{^\$};

        print "Found Apache group: $AP{group}\n";
    }
}

# find the default port setting
sub get_port {
    # For apache 1.3, this searched for Port,
    # but Port is gone in apache 2. Listen is more complicated..
    # There can be multiple Listen directives; I just punt
    # and assume the first one found is the default one....
    # (it could be an SSL one, or in a virtual host...)
    # XXX: this could be better
    if ($AP{conf} =~ /^\s*Listen\s+(\S+)(\s|$)/m) {
        # Here I assume the port number is either:
        # 1) a single numeric argument to Listen,
        my $arg = $1;
        if ($arg =~ /^\d+$/) {
            $AP{port} = $arg;
        }
        # or 2) a number following a colon in the first argument after Listen
        # (note: IPv6 addresses contain colons, so this matches the last colon;
        # note also that a protocol can come after the IP:port)
        elsif ($arg =~ /:(\d+)(\s|$)/) {
            $AP{port} = $1;
        }
        else {
            # it's only a default value anyway.. :)
            $AP{port} = 80;
        }
    }
}

# find AddModule and LoadModule data for DSO Apaches
sub get_dso_data {
    # get a hash of load module directives (name => filename)
    while ($AP{conf} =~ /^\s*LoadModule\s+(\S+)\s+(.*)$/gm) {
        $AP{load_modules}{$1} = $2;
    }
    # Apache 2 does not support AddModule
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
    foreach my $mod (qw(apreq expires perl log_config mime alias apache_ssl ssl)) {
        # first look in static modules
        if (exists $AP{static_modules}{"mod_$mod"} ||
           ($mod eq 'apache_ssl' && exists $AP{static_modules}{$mod})) {
            $AP{$mod} = 1 if $mod =~ /ssl$/;
            next;
        }

        # try DSO
        if ($AP{dso}) {
            # try modules specified in LoadModule
            # (note: removed add_module part)
            if ($AP{load_modules}{"${mod}_module"}
                  and -e catfile($AP{HTTPD_ROOT},
                                 $AP{load_modules}{"${mod}_module"}))
            {
                $AP{$mod} = 1 if $mod =~ /ssl$/;
                next MOD;
            }
            # On some platforms, "log_config" can actually be loaded via
            # AddModule as "config_log". (note: hopefully they "fixed" that,
            # but I left support for it in)
            elsif ($mod eq 'log_config'
                     and $AP{load_modules}{config_log_module}
                     and -e catfile($AP{HTTPD_ROOT},
                                    $AP{load_modules}{config_log_module}))
            {
                next MOD;
            }

            # The apache2 package provided by Debian uses the full path
            # to the module on the LoadModule line.
            if ($AP{load_modules}{"${mod}_module"}
                  and file_name_is_absolute($AP{load_modules}{"${mod}_module"})
                  and -e $AP{load_modules}{"${mod}_module"})
            {
                $AP{$mod} = 1 if $mod =~ /ssl$/;
                next MOD;
            }

            # last chance, see if we can find them on the
            # filesystem by guessing.  This comes in handy if someone
            # decides to install a DSO module but doesn't put it in
            # their default conf file.  Like Redhat 7.2 and mod_proxy.

            # potential paths for modules
            foreach my $path (catdir($AP{HTTPD_ROOT}, "modules"),
                              catdir($AP{HTTPD_ROOT}, "libexec"),
                              "/usr/lib/apache/2.0",
                              "/usr/lib/apache/2.2",
                              "/usr/lib/apache2/modules",
                              "/usr/lib/apache2/libexec",
                              "/usr/local/lib/apache2/modules",
                              "/usr/local/lib/apache2/libexec",
                  "/usr/pkg/include/httpd",
)
            {
                # perl uses libfoo.so format filenames
                if ($mod eq 'perl') {
                    if (-e ($_ = catfile($path, "lib${mod}.so"))) {
                        $AP{load_modules}{"${mod}_module"} = $_;
                        $AP{$mod} = 1 if $mod =~ /ssl$/;
                        next MOD;
                    }
                }

                # everything else is mod_foo.so.  Not an elsif in case
                # perl is sometimes mod_foo.so too.  I can imagine a
                # package maintainer getting smart and "fixing" it.
                if (-e ($_ = catfile($path, "mod_${mod}.so"))) {
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
              (map { "\tmod_$_\n" } @missing), "\n",
              "Please install them or, if they are installed, you may need to enable them in\n",
              "the mods-enabled directory of your apache2 installation or use a2enmod <module>,\n",
              "if you have that installed on your operating system.\n")
        if @missing;

    # Make sure that a DSO mod_perl is okay.
    # (I assume this still applies for Apache 2?)
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

Your Apache2 configuration suggested the following defaults. Press
[return] to confirm each item or type an alternative.  In most cases
the default should be correct.

END

    ask_confirm("Apache2 User:\t\t\t",  \$AP{user}, $QUIET);
    ask_confirm("Apache2 Group:\t\t\t", \$AP{group}, $QUIET);
    ask_confirm("Apache2 Port:\t\t\t",  \$AP{port}, $QUIET);
    ask_confirm("Apache2 Server Name:\t\t",  \$AP{server_name}, $QUIET);
    my $use_ssl = get_default('SSL');
    $use_ssl = !!$AP{ssl} unless defined $use_ssl;

    if ( $AP{ssl} ) {
        if (ask_yesno("Do you want to use SSL?", $use_ssl, $QUIET)) {
            # Apache 2 only has mod_ssl, no Apache-SSL.
            $AP{ssl} = 'mod_ssl';

            # Get the key and cert files.
            $AP{ssl_key} = get_default('SSL_KEY') ||
                catfile($AP{HTTPD_ROOT}, 'conf', 'ssl.key', 'server.key');
            $AP{ssl_cert} = get_default('SSL_CERT') ||
                catfile($AP{HTTPD_ROOT}, 'conf', 'ssl.crt','server.crt');

            ask_confirm("Apache2 SSL Port:\t\t",     \$AP{ssl_port}, $QUIET);
            ask_confirm("SSL certificate file:\t\t", \$AP{ssl_cert}, $QUIET);
            ask_confirm("SSL certificate key file:\t", \$AP{ssl_key}, $QUIET);
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
