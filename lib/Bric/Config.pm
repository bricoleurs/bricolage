package Bric::Config;
################################################################################

=head1 NAME

Bric::Config - A class to hold configuration settings.

=head1 VERSION

$Revision: 1.6.2.3 $

=cut

our $VERSION = substr(q$Revision: 1.6.2.3 $, 10, -1);

=head1 DATE

$Date: 2001-10-05 09:31:42 $

=head1 SYNOPSIS

use Config

=head1 DESCRIPTION

Holds configuration constants for the publishing system.

=cut

#==============================================================================#
# Dependencies                         #
#======================================#

#--------------------------------------#
# Standard Dependencies
use strict;
use File::Spec::Functions qw(catdir);

#--------------------------------------#
# Programatic Dependencies

#==============================================================================#
# Inheritance                          #
#======================================#

use base qw( Exporter );

our @EXPORT_OK = qw(DBD_PACKAGE
		    DBD_TYPE
		    DSN_STRING
		    DBI_USER
		    DBI_PASS
		    MASON_COMP_ROOT
		    MASON_DATA_ROOT
		    MASON_ARGS_METHOD
		    FIELD_INDENT
		    SYS_USER
		    SYS_GROUP
		    SERVER_NAME
		    SERVER_WINDOW_NAME
		    SERVER_ADMIN
		    APACHE_SERVER_ROOT
		    PID_FILE
		    DOCUMENT_ROOT
                    KEEP_ALIVE
		    MAX_KEEP_ALIVE_REQUESTS
		    KEEP_ALIVE_TIMEOUT
		    MIN_SPARE_SERVERS
		    MAX_SPARE_SERVERS
                    START_SERVERS
		    MAX_CLIENTS
		    MAX_REQUESTS_PER_CHILD
		    ERROR_LOG
		    LOG_LEVEL
		    LOG_FORMAT
		    CUSTOM_LOG
		    SCORE_BOARD_FILE
		    TYPES_CONFIG
                    HOST_NAME_LOOKUPS
		    SERVER_SIGNATURE
		    USE_CANONICAL_NAME
		    SSL_SESSION_CACHE
		    SSL_SESSION_CACHE_TIMEOUT
		    SSL_MUTEX
		    SSL_LOG
		    SSL_LOG_LEVEL
                    SSL_CERTIFICATE_FILE
                    SSL_CERTIFICATE_KEY_FILE
		    SSL_CIPHER_SUITE
		    SSL_PASS_PHRASE_DIALOG
		    CHAR_SET
		    AUTH_TTL
		    AUTH_SECRET
		    QA_MODE
		    ADMIN_GRP_ID
		    PASSWD_LENGTH
		    LOGIN_LENGTH
		    ERROR_URI
		    ENABLE_DIST
		    DIST_ATTEMPTS
                    MEDIA_URI_ROOT
		    MEDIA_FILE_ROOT
		    SMTP_SERVER
		    ALERT_FROM
		    ALERT_TO_METH
		    BURN_ROOT
		    BURN_COMP_ROOT
		    BURN_DATA_ROOT
		    BURN_ARGS_METHOD
		    INCLUDE_XML_WRITER
		    XML_WRITER_ARGS
		    ISO_8601_FORMAT
		    PREVIEW_LOCAL
		    PREVIEW_MASON
                    FULL_SEARCH
                    DEFAULT_FILENAME
                    DEFAULT_FILE_EXT
		   );

our %EXPORT_TAGS = (all => [qw(:dbi
			       :mason
			       :auth
			       :conf
			       :ssl
			       :qa
			       :admin
			       :char
			       :media
			       :err
			       :dist
			       :ui
			       :email
			       :alert
			       :burn
                               :oc
                               :search)],
		    dbi => [qw(DBD_PACKAGE
			       DBD_TYPE
			       DSN_STRING
			       DBI_USER
			       DBI_PASS)],
		    mason => [qw(MASON_COMP_ROOT
				 MASON_DATA_ROOT
				 MASON_ARGS_METHOD)],
		    burn => [qw(BURN_ROOT
				BURN_COMP_ROOT
			        BURN_DATA_ROOT
                                DEFAULT_FILENAME
                                INCLUDE_XML_WRITER
             		        XML_WRITER_ARGS
                                DEFAULT_FILE_EXT
				BURN_ARGS_METHOD)],
                    oc => [qw(DEFAULT_FILENAME
                              DEFAULT_FILE_EXT)],
		    sys_user => [qw(SYS_USER
				    SYS_GROUP)],
		    auth => [qw(AUTH_TTL
			        AUTH_SECRET)],
		    auth_len => [qw(PASSWD_LENGTH
				    LOGIN_LENGTH)],
		    prev => [qw(PREVIEW_LOCAL
				DOCUMENT_ROOT
				PREVIEW_MASON)],
		    dist => [qw(ENABLE_DIST
				DIST_ATTEMPTS
				PREVIEW_LOCAL)],
		    qa => [qw(QA_MODE)],
		    err => [qw(ERROR_URI)],
		    char => [qw(CHAR_SET)],
		    ui => [qw(FIELD_INDENT
                              SERVER_WINDOW_NAME)],
		    email => [qw(SMTP_SERVER)],
		    admin => [qw(ADMIN_GRP_ID)],
		    time => [qw(ISO_8601_FORMAT)],
		    alert => [qw(ALERT_FROM
				 ALERT_TO_METH)],
		    conf    => [qw(APACHE_SERVER_ROOT
				   PID_FILE
				   SERVER_NAME
				   SERVER_ADMIN
				   DOCUMENT_ROOT
				   KEEP_ALIVE
				   MAX_KEEP_ALIVE_REQUESTS
				   KEEP_ALIVE_TIMEOUT
				   MIN_SPARE_SERVERS
				   MAX_SPARE_SERVERS
				   START_SERVERS
				   MAX_CLIENTS
				   MAX_REQUESTS_PER_CHILD
				   ERROR_LOG
				   LOG_LEVEL
				   LOG_FORMAT
				   CUSTOM_LOG
				   SCORE_BOARD_FILE
				   TYPES_CONFIG
				   HOST_NAME_LOOKUPS
				   SERVER_SIGNATURE
				   USE_CANONICAL_NAME
				   PREVIEW_LOCAL
				   PREVIEW_MASON)],
		    ssl => [qw(SSL_SESSION_CACHE
			       SSL_SESSION_CACHE_TIMEOUT
			       SSL_MUTEX
			       SSL_LOG
			       SSL_LOG_LEVEL
			       SSL_CERTIFICATE_FILE
			       SSL_CERTIFICATE_KEY_FILE
			       SSL_CIPHER_SUITE
			       SSL_PASS_PHRASE_DIALOG)],
		    media => [qw(MEDIA_URI_ROOT
                                 MEDIA_FILE_ROOT)],
                    search => [qw(FULL_SEARCH)],
		   );

#=============================================================================#
# Function Prototypes                  #
#======================================#

#==============================================================================#
# Constants                            #
#======================================#
{
    # We'll store the settings loaded from the configuration file here.
    my $config;

    BEGIN {
	# Load the configuration file, if it exists.
	my $conf_file = $ENV{BRICOLAGE_ROOT} || '/usr/local/bricolage';
	$conf_file = catdir($conf_file, 'conf', 'bricolage.conf');
	if (-e $conf_file) {
	    open CONF, $conf_file or die "Cannot open $conf_file: $!\n";
	    while (<CONF>) {
		# Get each configuration line into $conifig.
		chomp;                  # no newline
		s/#.*//;                # no comments
		s/^\s+//;               # no leading white
		s/\s+$//;               # no trailing white
		next unless length;     # anything left?
		my ($var, $value) = split(/\s*=\s*/, $_, 2);
		$config->{uc $var} = $value;
	    }
	    close CONF;

	    # Invent a server name, if necessary.
	    $config->{SERVER_NAME} ||= do {
		my $h = `hostname`;
		my $d = `dnsdomainname`;
		chomp ($h, $d);
		$d ? "$h.$d" : $h;
	    };

	    # Set up the server window name (because Netscape is retarted!).
	    ($config->{SERVER_WINDOW_NAME} = $config->{SERVER_NAME}) =~ s/\W+/_/g;

	}
	# Process boolean directives here. These default to 1.
	foreach (qw(ENABLE_DIST PREVIEW_LOCAL PREVIEW_MASON)) {
	    my $d = exists $config->{$_} ? lc($config->{$_}) : '1';
	    $config->{$_} = $d eq 'on' || $d eq 'yes' || $d eq '1' ? 1 : 0;
	}
	# While these default to 0.
	foreach (qw(PREVIEW_MASON FULL_SEARCH INCLUDE_XML_WRITER)) {
	    my $d = exists $config->{$_} ? lc($config->{$_}) : '0';
	    $config->{$_} = $d eq 'on' || $d eq 'yes' || $d eq '1' ? 1 : 0;
	}

    }

    # Apache Settings.
    use constant SERVER_NAME             => $config->{SERVER_NAME};
    use constant SERVER_WINDOW_NAME      => $config->{SERVER_WINDOW_NAME};

    use constant SERVER_ADMIN            => $config->{SERVER_ADMIN}
      || 'root@' . SERVER_NAME;
    use constant DOCUMENT_ROOT           => $config->{DOCUMENT_ROOT}
      || catdir($ENV{BRICOLAGE_ROOT}, 'comp');
    use constant MIN_SPARE_SERVERS       => $config->{MIN_SPARE_SERVERS} || 2;
    use constant MAX_SPARE_SERVERS       => $config->{MAX_SPARE_SERVERS} || 6;
    use constant START_SERVERS           => $config->{START_SERVERS} || 2;
    use constant MAX_REQUESTS_PER_CHILD  => $config->{MAX_REQUESTS_PER_CHILD}
      || 0;
    use constant MAX_CLIENTS             => $config->{MAX_CLIENTS} || 150;
    use constant KEEP_ALIVE              => $config->{KEEP_ALIVE} || 'Off';
    use constant MAX_KEEP_ALIVE_REQUESTS => $config->{MAX_KEEP_ALIVE_REQUESTS}
      || 100;
    use constant KEEP_ALIVE_TIMEOUT      => $config->{KEEP_ALIVE_TIMEOUT} || 15;
    use constant ERROR_LOG               => $config->{ERROR_LOG}
      || '/usr/local/apache/logs/error_log';
    use constant LOG_LEVEL               => $config->{LOG_LEVEL} || 'info';
    use constant LOG_FORMAT              => $config->{LOG_FORMAT}
      || qq{'"%h %l %u %t "%r" %>s %b "%{Referer}i"} .
	 qq{ "%{User-Agent}i" "%{Cookie}i" "%v:%p"' combined};
    use constant CUSTOM_LOG              => $config->{CUSTOM_LOG}
      || '/usr/local/apache/logs/access_log combined';
    use constant APACHE_SERVER_ROOT      => $config->{APACHE_SERVER_ROOT}
      || '/usr/local/apache';
    use constant PID_FILE                => $config->{PID_FILE}
      || '/usr/local/apache/logs/httpd.pid';
    use constant SCORE_BOARD_FILE        => $config->{SCORE_BOARD_FILE};
    use constant TYPES_CONFIG            => $config->{TYPES_CONFIG}
      || '/usr/local/apache/conf/mime.types';
    use constant HOST_NAME_LOOKUPS       => $config->{HOST_NAME_LOOKUPS}
      || 'Off';
    use constant SERVER_SIGNATURE        => $config->{SERVER_SIGNATURE}
      || 'Email';
    use constant TIMEOUT                 => $config->{TIMEOUT}
      || 30;
    use constant USE_CANONICAL_NAME      => $config->{USE_CANONICAL_NAME}
      || 'On';

    # mod_ssl Settings.
    use constant SSL_SESSION_CACHE       => $config->{SSL_SESSION_CACHE}
      || 'dbm:/usr/local/apache/logs/ssl_scache';
    use constant SSL_SESSION_CACHE_TIMEOUT =>
      $config->{SSL_SESSION_CACHE_TIMEOUT} || 300;

    use constant SSL_MUTEX               => $config->{SSL_MUTEX}
    || 'file:/usr/local/apache/logs/ssl_mutex';
    use constant SSL_LOG                 => $config->{SSL_LOG} ||
      '/usr/local/apache/logs/ssl_engine_log';
    use constant SSL_LOG_LEVEL           => $config->{SSL_LOG_LEVEL}
      || 'info';
    use constant SSL_CERTIFICATE_FILE    => $config->{SSL_CERTIFICATE_FILE}
      || '/usr/local/apache/conf/ssl.crt/server.crt';
    use constant SSL_CERTIFICATE_KEY_FILE => $config->{SSL_CERTIFICATE_KEY_FILE}
      || '/usr/local/apache/conf/ssl.key/server.key';
    use constant SSL_CIPHER_SUITE        => $config->{SSL_CIPHER_SUITE}
      || 'ALL:!ADH:!EXP56:RC4+RSA:+HIGH:+MEDIUM:+LOW:+SSLv2:+EXP:+eNULL';
    use constant SSL_PASS_PHRASE_DIALOG  => $config->{SSL_PASS_PHRASE_DIALOG}
      || 'builtin';

    # DBI Settings.
    use constant DBD_PACKAGE             => 'Bric::Util::DBD::Pg';
    use constant DBD_TYPE                => 'Pg';
    use constant DB_NAME                 => $config->{DB_NAME} || 'sharky';
    use constant DSN_STRING              => 'dbname=' . DB_NAME;
    use constant DBI_USER                => $config->{DBI_USER} || 'castellan';
    use constant DBI_PASS                => $config->{DBI_PASS} || 'nalletsac';

    # Mason settings.
    use constant MASON_COMP_ROOT         => $config->{MASON_COMP_ROOT}
      || catdir($ENV{BRICOLAGE_ROOT}, 'comp');
    use constant MASON_DATA_ROOT         => $config->{MASON_DATA_ROOT}
      || catdir($ENV{BRICOLAGE_ROOT}, 'data');
    use constant MASON_ARGS_METHOD       => 'mod_perl';  # Could also be 'CGI'

    # Burner settings.
    use constant BURN_ROOT               => $config->{BURN_ROOT}
      || catdir(MASON_DATA_ROOT, 'burn', 'stage');
    use constant BURN_COMP_ROOT          => $config->{BURN_COMP_ROOT}
      || catdir(MASON_DATA_ROOT, 'burn', 'comp');
    use constant BURN_DATA_ROOT          => $config->{BURN_DATA_ROOT}
      || catdir(MASON_DATA_ROOT, 'burn', 'data');
    use constant BURN_ARGS_METHOD        => MASON_ARGS_METHOD;
    use constant INCLUDE_XML_WRITER      => $config->{INCLUDE_XML_WRITER};
    use constant XML_WRITER_ARGS         => $config->{XML_WRITER_ARGS} ?
      (eval "$config->{XML_WRITER_ARGS}" ) : ();

    # System User (The user and group under which the server children run). use
    use constant SYS_USER => scalar getpwnam $config->{SYS_USER} || "nobody";
    use constant SYS_GROUP => scalar getgrnam $config->{SYS_GROUP} || "nobody";

    # Cookie/Session Settings.
    # AUTH_TTL is in seconds.
    use constant AUTH_TTL                => $config->{AUTH_TTL} || 8 * 60 * 60;
    use constant AUTH_SECRET             => $config->{AUTH_SECRET}
      || '^eFH;5D,~3!f9o&3f_=dwePL3f:/.Oi|FG/3sd9=45oi%8GF;*)4#0gn3)34tf\`3~'
         . 'fdIf^ N;:';

    # QA Mode settings.
    use constant QA_MODE                 => 0;

    # Character translation settings.
    use constant CHAR_SET                => $config->{CHAR_SET} || 'ISO-8859-1';

    # Time constants.
    use constant ISO_8601_FORMAT         => "%G-%m-%d %T";

    # Admin group ID. This will go away once permissions are implemented.
    use constant ADMIN_GRP_ID            => 6;

    # the base directory that will store media assets
    use constant MEDIA_URI_ROOT => '/data/media';
    use constant MEDIA_FILE_ROOT => catdir(DOCUMENT_ROOT, 'data', 'media');

    # The minimum login name and password lengths users can enter.
    use constant LOGIN_LENGTH            => $config->{LOGIN_LENGTH} || 6;
    use constant PASSWD_LENGTH           => $config->{PASSWD_LENGTH} || 6;

    # Error Page Setting.
    use constant ERROR_URI => '/errors/500.mc';
#    use constant ERROR_URI => '/errors/error.html';

    # Distribution Settings.
    use constant ENABLE_DIST => $config->{ENABLE_DIST};
    use constant DIST_ATTEMPTS => $config->{DIST_ATTEMPTS} || 3;
    use constant PREVIEW_LOCAL => $config->{PREVIEW_LOCAL} ? qw(data preview) : 0;
    use constant PREVIEW_MASON => $config->{PREVIEW_MASON};

    # Email Settings.
    use constant SMTP_SERVER => $config->{SMTP_SERVER} || SERVER_NAME;

    # Alert Settings.
    use constant ALERT_FROM => $config->{ALERT_FROM} || SERVER_ADMIN;
    use constant ALERT_TO_METH => lc $config->{ALERT_TO_METH} || 'bcc';

    # UI Settings.
    use constant FIELD_INDENT => 125;

    # Search Settings
    use constant FULL_SEARCH => => $config->{FULL_SEARCH};

    # Output Channel Settings.
    use constant DEFAULT_FILENAME => => $config->{DEFAULT_FILENAME} || 'index';
    use constant DEFAULT_FILE_EXT => => $config->{DEFAULT_FILE_EXT} || 'html';

    # Okay, now load the end-user's code, if any.
    if ($config->{PERL_LOADER}) {
	package Bric::Util::Burner;
	eval "$config->{PERL_LOADER}";
    }
}

#==============================================================================#
# FIELDS                               #
#======================================#

#--------------------------------------#
# Public Class Fields

#--------------------------------------#
# Private Class Fields

#--------------------------------------#
# Instance Fields

#==============================================================================#

=head1 INTERFACE

=head2 Constructors

NONE

=over 4

=cut

#--------------------------------------#
# Constructors

#--------------------------------------#

=head2 Public Class Methods

NONE

=cut

#--------------------------------------#

=head2 Public Instance Methods

NONE

=cut

#==============================================================================#

=head2 Private Methods

NONE

=cut

#--------------------------------------#

=head2 Private Class Methods

NONE

=cut

#--------------------------------------#

=head2 Private Instance Methods

NONE

=cut


1;
__END__

=back

=head1 NOTES

NONE

=head1 AUTHOR

"Garth Webb" <garth@perijove.com>

=head1 SEE ALSO

L<perl>, L<DBC>

=head1 REVISION HISTORY

$Log: Config.pm,v $
Revision 1.6.2.3  2001-10-05 09:31:42  wheeler
Added configurations for XML::Writer in templates.

Revision 1.6.2.2  2001/10/05 08:15:42  wheeler
Added SERVER_WINDOW_NAME for use in window.open() JavaScript calls.

Revision 1.6.2.1  2001/10/04 13:37:38  wheeler
Added PERL_LOADER and fixed bug where *no* directives were getting loaded!

Revision 1.6  2001/09/27 15:41:46  wheeler
Added filename and file_ext columns to OutputChannel API. Also added a
configuration directive to CE::Config to specify the default filename and
extension for the system. Will need to document later that these can be set, or
move them into preferences. Will also need to use the filename and file_ext
properties of Bric::Biz::OutputChannel in the Burn System.

Revision 1.5  2001/09/26 10:38:56  wheeler
Unset debugging settings.

Revision 1.4  2001/09/25 13:34:31  wheeler
Changed FULL_SEARCH to allow standard setting arguments in bricolage.conf,
and to default to 0.

Revision 1.3  2001/09/20 02:12:29  wheeler
Undid changes I accidentally committed.

Revision 1.2  2001/09/20 02:11:40  wheeler
Removed files that I'd put in the wrong place!

Revision 1.1.1.1  2001/09/06 21:52:50  wheeler
Upload to SourceForge.

=cut
