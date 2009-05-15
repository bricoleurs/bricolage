package Bric::Config;

################################################################################

=head1 Name

Bric::Config - A class to hold configuration settings.

=head1 Synopsis

  # import all configuration constants
  use Bric::Config qw(:all);

  if (CONFIG_VARIABLE) { ... }

=head1 Description

Provides access to configuration variables set in conf/bricolage.conf.
See L<Bric::Admin|Bric::Admin> for the list of configuration variables
and their use.

=cut

#==============================================================================#
# Dependencies                         #
#======================================#

#--------------------------------------#
# Standard Dependencies
use strict;

#--------------------------------------#
# Programmatic Dependencies
use File::Spec::Functions qw(catdir tmpdir catfile);

#==============================================================================#
# Inheritance                          #
#======================================#

use base qw(Exporter);

our @EXPORT_OK = qw(DBD_PACKAGE
                    DB_NAME
                    DB_HOST
                    DB_PORT
                    DBD_TYPE
                    DBI_USER
                    DBI_PASS
                    DBI_DEBUG
                    DBI_CALL_TRACE
                    DBI_PROFILE
                    MASON_COMP_ROOT
                    MASON_DATA_ROOT
                    MASON_ARGS_METHOD
                    MASON_STATIC_SOURCE
                    FIELD_INDENT
                    SYS_USER
                    SYS_GROUP
                    SERVER_WINDOW_NAME
                    NO_TOOLBAR
                    APACHE_BIN
                    APACHE_CONF
                    PID_FILE
                    LISTEN_PORT
                    NAME_VHOST
                    VHOST_SERVER_NAME
                    ALWAYS_USE_SSL
                    SSL_ENABLE
                    SSL_PORT
                    SSL_CERTIFICATE_FILE
                    SSL_CERTIFICATE_KEY_FILE
                    AUTH_TTL
                    AUTH_SECRET
                    AUTH_ENGINES
                    LDAP_SERVER
                    LDAP_VERSION
                    LDAP_USER
                    LDAP_PASS
                    LDAP_BASE
                    LDAP_UID_ATTR
                    LDAP_FILTER
                    LDAP_GROUP
                    LDAP_MEMBER_ATTR
                    LDAP_TLS
                    LDAP_SSL_VERSION
                    AUTH_COOKIE
                    COOKIE
                    LOGIN_MARKER
                    QA_MODE
                    TEMPLATE_QA_MODE
                    ADMIN_GRP_ID
                    PASSWD_LENGTH
                    PUBLISH_RELATED_ASSETS
                    PUBLISH_RELATED_FAIL_BEHAVIOR
                    LOGIN_LENGTH
                    ERROR_URI
                    ENABLE_DIST
                    QUEUE_PUBLISH_JOBS
                    FTP_UNLINK_BEFORE_MOVE
                    DIST_ATTEMPTS
                    MEDIA_URI_ROOT
                    DEF_MEDIA_TYPE
                    ENABLE_SFTP_MOVER
                    ENABLE_SFTP_V2
                    SFTP_MOVER_CIPHER
                    SFTP_HOME
                    ENABLE_WEBDAV_MOVER
                    MEDIA_FILE_ROOT
                    MEDIA_UNIQUE_FILENAME
                    MEDIA_FILENAME_PREFIX
                    MEDIA_UPLOAD_LIMIT
                    AUTO_PREVIEW_MEDIA
                    USE_THUMBNAILS
                    THUMBNAIL_SIZE
                    SMTP_SERVER
                    ALERT_FROM
                    ALERT_TO_METH
                    BURN_ROOT
                    STAGE_ROOT
                    PREVIEW_ROOT
                    BURN_COMP_ROOT
                    BURN_DATA_ROOT
                    BURN_SANDBOX_ROOT
                    BURN_ARGS_METHOD
                    TEMPLATE_BURN_PKG
                    INCLUDE_XML_WRITER
                    XML_WRITER_ARGS
                    MASON_INTERP_ARGS
                    TT_OPTIONS
                    ISO_8601_FORMAT
                    PREVIEW_LOCAL
                    PREVIEW_MASON
                    FULL_SEARCH
                    BLOB_SEARCH
                    EXPIRE_ON_DEACTIVATE
                    DEFAULT_FILENAME
                    DEFAULT_FILE_EXT
                    ENABLE_OC_ASSET_ASSOCIATION
                    ALLOW_URIS_WITHOUT_CATEGORIES
                    ENABLE_FTP_SERVER
                    FTP_DEPLOY_ON_UPLOAD
                    FTP_PORT
                    FTP_ADDRESS
                    FTP_LOG
                    FTP_PID_FILE
                    FTP_DEBUG
                    DISABLE_NAV_LAYER
                    TEMP_DIR
                    PROFILE
                    CHECK_PROCESS_SIZE
                    MAX_PROCESS_SIZE
                    CHECK_FREQUENCY
                    MIN_SHARE_SIZE
                    MAX_UNSHARED_SIZE
                    MANUAL_APACHE
                    ALLOW_WORKFLOW_TRANSFER
                    MOD_PERL
                    MOD_PERL_VERSION
                    ALLOW_ALL_SITES_CX
                    RELATED_MEDIA_UPLOAD
                    ALLOW_SLUGLESS_NONFIXED
                    AUTOGENERATE_SLUG
                    YEAR_SPAN_BEFORE
                    YEAR_SPAN_AFTER
                    CACHE_DEBUG_MODE
                    STORY_URI_WITH_FILENAME
                    ENABLE_CATEGORY_BROWSER
                    LOAD_LANGUAGES
                    ENCODE_OK
                    LOAD_CHAR_SETS
                    LOAD_TIME_ZONES
                    ENABLE_WYSIWYG
                    WYSIWYG_EDITOR
                    XINHA_PLUGINS
                    XINHA_TOOLBAR
                    FCKEDITOR_CONFIG
                    HTMLAREA_TOOLBAR
                    ENABLE_GZIP
                    RELATED_DOC_POD_TAG
                   );

our %EXPORT_TAGS = (all       => \@EXPORT_OK,
                    cookies   => [qw(AUTH_COOKIE
                                     COOKIE
                                     LOGIN_MARKER)],
                    dbi       => [qw(DBD_PACKAGE
                                     DB_NAME
                                     DB_HOST
                                     DB_PORT
                                     DBD_TYPE
                                     DBI_USER
                                     DBI_PASS
                                     DBI_DEBUG
                                     DBI_CALL_TRACE
                                     DBI_PROFILE)],
                    mason     => [qw(MASON_COMP_ROOT
                                     MASON_DATA_ROOT
                                     MASON_STATIC_SOURCE
                                     MASON_ARGS_METHOD)],
                    burn      => [qw(BURN_ROOT
                                     STAGE_ROOT
                                     PREVIEW_ROOT
                                     BURN_COMP_ROOT
                                     BURN_DATA_ROOT
                                     BURN_SANDBOX_ROOT
                                     TEMPLATE_BURN_PKG
                                     DEFAULT_FILENAME
                                     INCLUDE_XML_WRITER
                                     XML_WRITER_ARGS
                                     MASON_INTERP_ARGS
                                     TT_OPTIONS
                                     DEFAULT_FILE_EXT
                                     BURN_ARGS_METHOD)],
                    oc        => [qw(DEFAULT_FILENAME
                                     DEFAULT_FILE_EXT
                                     ENABLE_OC_ASSET_ASSOCIATION
                                     ALLOW_URIS_WITHOUT_CATEGORIES )],
                    sys_user  => [qw(SYS_USER
                                     SYS_GROUP)],
                    auth      => [qw(AUTH_TTL
                                     AUTH_ENGINES
                                     AUTH_SECRET)],
                    ldap      => [qw(LDAP_SERVER
                                     LDAP_VERSION
                                     LDAP_USER
                                     LDAP_PASS
                                     LDAP_BASE
                                     LDAP_UID_ATTR
                                     LDAP_FILTER
                                     LDAP_GROUP
                                     LDAP_MEMBER_ATTR
                                     LDAP_TLS
                                     LDAP_SSL_VERSION)],
                    auth_len  => [qw(PASSWD_LENGTH
                                     LOGIN_LENGTH)],
                    prev      => [qw(PREVIEW_LOCAL
                                     STAGE_ROOT
                                     PREVIEW_ROOT
                                     MASON_COMP_ROOT
                                     AUTO_PREVIEW_MEDIA
                                     PREVIEW_MASON)],
                    pub       => [qw(PUBLISH_RELATED_ASSETS
                                     PUBLISH_RELATED_FAIL_BEHAVIOR)],
                    dist      => [qw(ENABLE_DIST
                                     QUEUE_PUBLISH_JOBS
                                     FTP_UNLINK_BEFORE_MOVE
                                     ENABLE_SFTP_MOVER
                                     ENABLE_SFTP_V2
                                     SFTP_MOVER_CIPHER
                                     SFTP_HOME
                                     ENABLE_WEBDAV_MOVER
                                     DEF_MEDIA_TYPE
                                     DIST_ATTEMPTS
                                     PREVIEW_LOCAL)],
                    qa        => [qw(QA_MODE
                                     TEMPLATE_QA_MODE)],
                    err       => [qw(ERROR_URI)],
                    ui        => [qw(FIELD_INDENT
                                     DISABLE_NAV_LAYER
                                     FULL_SEARCH
                                     BLOB_SEARCH
                                     EXPIRE_ON_DEACTIVATE
                                     ALLOW_WORKFLOW_TRANSFER
                                     ALLOW_ALL_SITES_CX
                                     RELATED_MEDIA_UPLOAD
                                     ALLOW_SLUGLESS_NONFIXED
                                     AUTOGENERATE_SLUG
                                     SERVER_WINDOW_NAME
                                     YEAR_SPAN_BEFORE
                                     YEAR_SPAN_AFTER
                                     NO_TOOLBAR
                                     ENABLE_CATEGORY_BROWSER
                                     ENABLE_WYSIWYG
                                     WYSIWYG_EDITOR
                                     XINHA_PLUGINS
                                     XINHA_TOOLBAR
                                     FCKEDITOR_CONFIG
                                     LOAD_CHAR_SETS
                                     HTMLAREA_TOOLBAR)],
                    email     => [qw(SMTP_SERVER)],
                    admin     => [qw(ADMIN_GRP_ID)],
                    time      => [qw(ISO_8601_FORMAT
                                     LOAD_TIME_ZONES)],
                    alert     => [qw(ALERT_FROM
                                     ALERT_TO_METH)],
                    apachectl => [qw(APACHE_BIN
                                     APACHE_CONF
                                     PID_FILE
                                     SSL_ENABLE)],
                    ssl       => [qw(SSL_ENABLE
                                     SSL_PORT
                                     ALWAYS_USE_SSL
                                     LISTEN_PORT)],
                    conf      => [qw(SSL_ENABLE
                                     SSL_CERTIFICATE_FILE
                                     SSL_CERTIFICATE_KEY_FILE
                                     SSL_PORT
                                     LISTEN_PORT
                                     ENABLE_DIST
                                     QUEUE_PUBLISH_JOBS
                                     NAME_VHOST
                                     VHOST_SERVER_NAME
                                     MASON_COMP_ROOT
                                     PREVIEW_LOCAL
                                     PREVIEW_MASON
                                     MANUAL_APACHE
                                     ENABLE_GZIP)],
                    media     => [qw(MEDIA_URI_ROOT
                                     MEDIA_FILE_ROOT
                                     MEDIA_UPLOAD_LIMIT
                                     AUTO_PREVIEW_MEDIA
                                     MEDIA_UNIQUE_FILENAME
                                     MEDIA_FILENAME_PREFIX
                                     AUTO_PREVIEW_MEDIA
                                     MEDIA_FILE_ROOT)],
                    thumb     => [qw(USE_THUMBNAILS
                                     THUMBNAIL_SIZE)],
                    ftp       => [qw(ENABLE_FTP_SERVER
                                     FTP_DEPLOY_ON_UPLOAD
                                     FTP_PORT
                                     FTP_ADDRESS
                                     FTP_LOG
                                     FTP_PID_FILE
                                     FTP_DEBUG)],
                    temp      => [qw(TEMP_DIR)],
                    profile   => [qw(PROFILE)],
                    proc_size => [qw(CHECK_PROCESS_SIZE
                                     MAX_PROCESS_SIZE
                                     CHECK_FREQUENCY
                                     MIN_SHARE_SIZE
                                     MAX_UNSHARED_SIZE)],
                    mod_perl  => [qw(MOD_PERL
                                     MOD_PERL_VERSION)],
                    uri       => [qw(STORY_URI_WITH_FILENAME)],
                    l10n      => [qw(LOAD_LANGUAGES
                                     ENCODE_OK
                                     LOAD_CHAR_SETS)],
                    pod       => [qw(RELATED_DOC_POD_TAG)],
                   );

# This has to come after the EXPORT vars so that other Bricolage modules
# will load properly.
require Bric; our $VERSION = Bric->VERSION;

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
        if (not -e $conf_file and $ENV{BRIC_TEMP_DIR}) {
            # We're testing but can't find an existing bricolage.conf. Try to
            # find one that was created during `make`.
            $conf_file = catfile 'bconf', 'bricolage.conf'
        }

        if (-e $conf_file) {
            my $cf;
            unless (open $cf, '<', $conf_file) {
                require Carp;
                Carp::croak( "Cannot open $conf_file: $!\n" );
            }

            while (<$cf>) {
                # Get each configuration line into $config.
                chomp;                  # no newline
                s/#.*//;                # no comments
                s/^\s+//;               # no leading white
                s/\s+$//;               # no trailing white
                next unless length;     # anything left?

                # Get the variable and its value.
                my ($var, $val) = split(/\s*=\s*/, $_, 2);

                # Check that the line is a valid config line and exit
                # immediately if not.
                unless (defined $var and length $var and
                        defined $val and length $val) {
                  print STDERR "Syntax error in $conf_file at line $.: '$_'\n";
                  exit 1;
                }

                # Save the configuration directive.
                $config->{uc $var} = $val;
            }

            close $cf;
        }

        # Set the default VHOST_SERVER_NAME.
        $config->{VHOST_SERVER_NAME} ||= '_default_';

        # Set up the server window name (because Netscape is retarted!).
        ($config->{SERVER_WINDOW_NAME} =
             $config->{VHOST_SERVER_NAME} || '_default_') =~ s/\W+/_/g;

        my $wysiwyg = $config->{ENABLE_WYSIWYG} ? lc $config->{ENABLE_WYSIWYG} : '';
        if ($wysiwyg && ($wysiwyg eq '1' || $wysiwyg eq 'on' || $wysiwyg eq 'yes')) {
            my $ed = lc ($config->{WYSIWYG_EDITOR} ||= 'xinha');

            if ($ed eq 'xinha') {
                # Set default plugins for Xinha
                $config->{XINHA_PLUGINS} ||= "['FullScreen','SpellChecker']";

                # Set default toolbar for Xinha
                $config->{XINHA_TOOLBAR}
                    ||= q{[['popupeditor','separator'],['bold','italic',}
                      . q{'underline','strikethrough','separator'],}
                      . q{['subscript','superscript','separator'],}
                      . q{(HTMLArea.is_gecko ? [] : ['cut','copy','paste']),}
                      . q{['space','undo','redo','separator'],['createlink',}
                      . q{'separator'],['killword','removeformat',}
                      . q{'separator','htmlmode']]};

            } elsif ($ed eq 'xhmlarea') {
                # Set default toolbar for HtmlArea
                $config->{HTMLAREA_TOOLBAR}
                    ||= q{[['bold','italic','underline','strikethrough',}
                      . q{'separator','subscript','superscript','separator',}
                      . q{'copy','cut','paste','space','undo','redo',}
                      . q{'createlink','htmlmode','separator','popupeditor',}
                      . q{'separator','showhelp','about']]};

            } elsif ($ed eq 'fckeditor') {
                # Set default toolbar for FCKeditor.
                $config->{FCKEDITOR_CONFIG}
                    ||= q{FCKConfig.ToolbarSets.Default = }
                      . q{[['Bold','Italic','Underline','StrikeThrough',}
                      . q{'RemoveFormat','-','Subscript','Superscript'],}
                      . q{['Cut','Copy','Paste','PasteText','PasteWord','-',}
                      . q{'Undo','Redo'],['Link','Unlink','Anchor','Source',}
                      . q{'SpellCheck']];};
            }
        }

        # Process boolean directives here. These default to 1.
        foreach (qw(ENABLE_DIST PREVIEW_LOCAL NO_TOOLBAR
                    ALLOW_SLUGLESS_NONFIXED PUBLISH_RELATED_ASSETS
                    ENABLE_OC_ASSET_ASSOCIATION RELATED_MEDIA_UPLOAD
                    USE_THUMBNAILS)) {
            my $d = exists $config->{$_} ? lc($config->{$_}) : '1';
            $config->{$_} = $d eq 'on' || $d eq 'yes' || $d eq '1' ? 1 : 0;
        }
        # While these default to 0.
        foreach (qw(PREVIEW_MASON FULL_SEARCH BLOB_SEARCH INCLUDE_XML_WRITER
                    MANUAL_APACHE DISABLE_NAV_LAYER QA_MODE TEMPLATE_QA_MODE
                    DBI_PROFILE PROFILE CHECK_PROCESS_SIZE ENABLE_SFTP_MOVER
                    ENABLE_SFTP_V2 ENABLE_WEBDAV_MOVER ALWAYS_USE_SSL
                    ALLOW_WORKFLOW_TRANSFER ALLOW_ALL_SITES_CX
                    STORY_URI_WITH_FILENAME ENABLE_FTP_SERVER
                    ENABLE_CATEGORY_BROWSER QUEUE_PUBLISH_JOBS
                    FTP_DEPLOY_ON_UPLOAD FTP_UNLINK_BEFORE_MOVE
                    ENABLE_WYSIWYG AUTOGENERATE_SLUG ENABLE_GZIP
                    MEDIA_UNIQUE_FILENAME LDAP_TLS AUTO_PREVIEW_MEDIA
                    MASON_STATIC_SOURCE ALLOW_URIS_WITHOUT_CATEGORIES
                    EXPIRE_ON_DEACTIVATE))
        {
            my $d = exists $config->{$_} ? lc($config->{$_}) : '0';
            $config->{$_} = $d eq 'on' || $d eq 'yes' || $d eq '1' ? 1 : 0;
        }

        $config->{LOAD_LANGUAGES} = [ split /\s+/,
                                      $config->{LOAD_LANGUAGES} || 'en_us' ];
        $config->{LOAD_CHAR_SETS} = [ split /\s+/,
                                      $config->{LOAD_CHAR_SETS} || 'UTF-8' ];

        # Special case for the SSL_ENABLE configuration directive.
        if (my $ssl = lc $config->{SSL_ENABLE}) {
            if ($ssl eq 'off' or $ssl eq 'no') {
                $config->{SSL_ENABLE} = 0;
            } else {
                require Carp;
                Carp::croak( "Invalid SSL_ENABLE directive: '$ssl'" )
                  unless $ssl eq 'mod_ssl' or $ssl eq 'apache_ssl';
            }
        } else {
            $config->{SSL_ENABLE} = 0;
        }

        # Set the Mason component root to its default here.
        $config->{MASON_COMP_ROOT} ||=
          catdir($ENV{BRICOLAGE_ROOT} || '/usr/local/bricolage', 'comp');

        # Grab the Apache configuration file.
        $config->{APACHE_CONF} ||= '/usr/local/apache/conf/httpd.conf';
        if (not -e $config->{APACHE_CONF} and $ENV{BRIC_TEMP_DIR}) {
            # We're testing and can't find the httpd.conf. Try to find one
            # in our root directory.
            $config->{APACHE_CONF} =
              catfile $ENV{BRICOLAGE_ROOT} || '/usr/local/bricolage',
              'httpd.conf';
            # And try just a local directory if all else fails. This would
            # most likely be used during `make test`.
            $config->{APACHE_CONF} = catfile 'bconf', 'httpd.conf'
              unless -e $config->{APACHE_CONF};
        }

        # Get the Apache PID file location from httpd.conf.
        open my $hc, '<', $config->{APACHE_CONF}
          or die "Cannot open $config->{APACHE_CONF}: $!\n";
        while (<$hc>) {
            # Ignore comments.
            chomp;                  # no newline
            s/#.*//;                # no comments
            s/^\s+//;               # no leading white
            s/\s+$//;               # no trailing white
            next unless length;     # anything left?
            next unless /^PidFile\s+(.*)/i;
            $config->{__PIDFILE__} = $1;
            last;
        }
        close $hc;
    }

    # Apache Settings.
    use constant MANUAL_APACHE           => $config->{MANUAL_APACHE};
    use constant SERVER_WINDOW_NAME      => $config->{SERVER_WINDOW_NAME};
    use constant NO_TOOLBAR              => $config->{NO_TOOLBAR};

    use constant APACHE_BIN              => $config->{APACHE_BIN}
      || '/usr/local/apache/bin/httpd';
    use constant APACHE_CONF             => $config->{APACHE_CONF};

    use constant PID_FILE                => $config->{__PIDFILE__}
      || '/usr/local/apache/log/httpd.pid';

    use constant LISTEN_PORT             => $config->{LISTEN_PORT} || 80;
    use constant NAME_VHOST              => $config->{NAME_VHOST} || '*';
    use constant VHOST_SERVER_NAME       => $config->{VHOST_SERVER_NAME};

    use constant ENABLE_GZIP             => $config->{ENABLE_GZIP};

    # ssl Settings.
    use constant SSL_ENABLE              => $config->{SSL_ENABLE};
    use constant SSL_CERTIFICATE_FILE    =>
      $config->{SSL_CERTIFICATE_FILE} || '';
    use constant SSL_CERTIFICATE_KEY_FILE =>
      $config->{SSL_CERTIFICATE_KEY_FILE} || '';
    use constant ALWAYS_USE_SSL          => $config->{ALWAYS_USE_SSL};
    use constant SSL_PORT                => $config->{SSL_PORT} || 443;

    # cookie Settings
    use constant AUTH_COOKIE             => 'BRICOLAGE_AUTH';
    use constant COOKIE                  => 'BRICOLAGE';
    use constant LOGIN_MARKER            => 'BRIC_LOGIN_MARKER';

    # DBI Settings.
    use constant DBD_TYPE                => $config->{DB_TYPE} || 'Pg';
    use constant DBD_PACKAGE             => 'Bric::Util::DBD::' . DBD_TYPE;
    use constant DB_NAME                 => $config->{DB_NAME} || 'sharky';
    use constant DB_HOST                 => $config->{DB_HOST};
    use constant DB_PORT                 => $config->{DB_PORT};
    use constant DBI_USER                => $config->{DBI_USER} || 'castellan';
    use constant DBI_PASS                => $config->{DBI_PASS} || 'nalletsac';
    use constant DBI_CALL_TRACE          => $config->{DBI_CALL_TRACE} || 0;
    use constant DBI_PROFILE             => $config->{DBI_PROFILE} || 0;
    # DBI_CALL_TRACE and DBI_PROFILE imply DBI_DEBUG
    use constant DBI_DEBUG               => $config->{DBI_DEBUG}      ||
                                            $config->{DBI_CALL_TRACE} ||
                                            $config->{DBI_PROFILE}    || 0;

    # Distribution Settings.
    use constant ENABLE_DIST             => $config->{ENABLE_DIST};
    use constant QUEUE_PUBLISH_JOBS      => $config->{QUEUE_PUBLISH_JOBS};
    use constant FTP_UNLINK_BEFORE_MOVE  => $config->{FTP_UNLINK_BEFORE_MOVE} || 0;
    use constant DIST_ATTEMPTS           => $config->{DIST_ATTEMPTS} || 3;
    use constant PREVIEW_LOCAL           => $config->{PREVIEW_LOCAL} ? qw(data preview) : 0;
    use constant PREVIEW_MASON           => $config->{PREVIEW_MASON};
    use constant DEF_MEDIA_TYPE          => $config->{DEF_MEDIA_TYPE} || 'text/html';
    use constant ENABLE_SFTP_MOVER       => $config->{ENABLE_SFTP_MOVER};
    use constant ENABLE_SFTP_V2          => $config->{ENABLE_SFTP_V2};
    use constant SFTP_MOVER_CIPHER       => $config->{SFTP_MOVER_CIPHER} || 0;
    use constant SFTP_HOME               => $config->{SFTP_HOME};
    use constant ENABLE_WEBDAV_MOVER     => $config->{ENABLE_WEBDAV_MOVER};

    # Publishing Settings.
    use constant PUBLISH_RELATED_ASSETS => $config->{PUBLISH_RELATED_ASSETS};
    use constant PUBLISH_RELATED_FAIL_BEHAVIOR => $config->{PUBLISH_RELATED_FAIL_BEHAVIOR} || 'warn';

    # Mason settings.
    use constant MASON_COMP_ROOT         => PREVIEW_LOCAL && PREVIEW_MASON ?
      [[bric_ui => $config->{MASON_COMP_ROOT}],
       [bric_preview => catdir($config->{MASON_COMP_ROOT}, PREVIEW_LOCAL)]]
        : [[bric_ui => $config->{MASON_COMP_ROOT}]];

    use constant MASON_DATA_ROOT         => $config->{MASON_DATA_ROOT}
      || catdir($ENV{BRICOLAGE_ROOT} || '/usr/local/bricolage', 'data');
    use constant MASON_ARGS_METHOD       => 'mod_perl';  # Could also be 'CGI'
    use constant MASON_STATIC_SOURCE     => $config->{MASON_STATIC_SOURCE};

    # Burner settings.
    use constant BURN_ROOT               => $ENV{BRIC_BURN_ROOT}
      || $config->{BURN_ROOT} || catdir(MASON_DATA_ROOT, 'burn');
    use constant STAGE_ROOT              => catdir(BURN_ROOT, 'stage');
    use constant PREVIEW_ROOT            => catdir(BURN_ROOT, 'preview');
    use constant BURN_COMP_ROOT          => catdir(BURN_ROOT, 'comp');
    use constant BURN_DATA_ROOT          => catdir(BURN_ROOT, 'data');
    use constant BURN_SANDBOX_ROOT       => catdir(BURN_ROOT, 'sandbox');
    use constant BURN_ARGS_METHOD        => MASON_ARGS_METHOD;
    use constant TEMPLATE_BURN_PKG       => 'Bric::Util::Burner::Commands';
    use constant INCLUDE_XML_WRITER      => $config->{INCLUDE_XML_WRITER};
    use constant XML_WRITER_ARGS         => $config->{XML_WRITER_ARGS} ?
      ( eval "$config->{XML_WRITER_ARGS}" ) : ();
    use constant MASON_INTERP_ARGS       => $config->{MASON_INTERP_ARGS} ?
      ( eval "$config->{MASON_INTERP_ARGS}" ) : ();
    use constant TT_OPTIONS       => $config->{TT_OPTIONS} ?
      ( eval "$config->{TT_OPTIONS}" ) : ();

    # System User (The user and group under which the server children run). use
    use constant SYS_USER  => scalar getpwnam($config->{SYS_USER} or "nobody");
    use constant SYS_GROUP => scalar getgrnam($config->{SYS_GROUP} or "nobody");

    # Cookie/Session Settings.
    # AUTH_TTL is in seconds.
    use constant AUTH_TTL                => $config->{AUTH_TTL} || 8 * 60 * 60;
    use constant AUTH_SECRET             => $config->{AUTH_SECRET}
      || '^eFH;5D,~3!f9o&3f_=dwePL3f:/.Oi|FG/3sd9=45oi%8GF;*)4#0gn3)34tf\`3~'
         . 'fdIf^ N;:';
    use constant AUTH_ENGINES            => (
        map { "Bric::Util::Auth$_"}
        split /\s+/, $config->{AUTH_ENGINES} || 'Internal'
    );

    # LDAP settings.
    use constant LDAP_SERVER             => $config->{LDAP_SERVER} || 'localhost';
    use constant LDAP_VERSION            => $config->{LDAP_VERSION} || 3;
    use constant LDAP_USER               => $config->{LDAP_USER} || '';
    use constant LDAP_PASS               => $config->{LDAP_PASS} || '';
    use constant LDAP_BASE               => $config->{LDAP_BASE} || '';
    use constant LDAP_UID_ATTR           => $config->{LDAP_UID_ATTR} || 'uid';
    use constant LDAP_FILTER             => $config->{LDAP_FILATER} || '(objectclass=*)';
    use constant LDAP_GROUP              => $config->{LDAP_GROUP} || '';
    use constant LDAP_MEMBER_ATTR        => $config->{LDAP_MEMBER_ATTR} || 'uniqueMember';
    use constant LDAP_TLS                => $config->{LDAP_TLS};
    use constant LDAP_SSL_VERSION        => $config->{LDAP_SSL_VERSION} || 3;

    # QA Mode settings.
    use constant QA_MODE                 => $config->{QA_MODE} || 0;
    use constant TEMPLATE_QA_MODE        => $config->{TEMPLATE_QA_MODE} || 0;

    # Time constants.
    use constant ISO_8601_FORMAT         => "%Y-%m-%d %T.%6N";
    use constant LOAD_TIME_ZONES         => $config->{LOAD_TIME_ZONES} || 'UTC';

    # Admin group ID. This will go away once permissions are implemented.
    use constant ADMIN_GRP_ID            => 6;

    # the base directory that will store media assets
    use constant MEDIA_URI_ROOT          => '/data/media';
    use constant MEDIA_FILE_ROOT         => $ENV{MEDIA_FILE_ROOT}
        || catdir(MASON_COMP_ROOT->[0][1], 'data', 'media');

    # Use Media ID as filename to ensure unique filenames across the site
    # Prefix to append to media id if required.
    use constant MEDIA_UNIQUE_FILENAME    => $config->{MEDIA_UNIQUE_FILENAME};
    use constant MEDIA_FILENAME_PREFIX    => $config->{MEDIA_FILENAME_PREFIX} || '';

    # Media upload limit and auto-preview.
    use constant MEDIA_UPLOAD_LIMIT      => $config->{MEDIA_UPLOAD_LIMIT} || 0;
    use constant AUTO_PREVIEW_MEDIA      => $config->{AUTO_PREVIEW_MEDIA} || 0;

    # Are we using thumbnails and how big are they ?
    use constant USE_THUMBNAILS          => $config->{USE_THUMBNAILS};
    use constant THUMBNAIL_SIZE          => $config->{THUMBNAIL_SIZE} || 75;

    # Enable WYSIWYG editor?
    use constant ENABLE_WYSIWYG          => $config->{ENABLE_WYSIWYG};
    use constant WYSIWYG_EDITOR          => $config->{WYSIWYG_EDITOR};

    # WYSIWYG editor settings
    use constant XINHA_PLUGINS           => $config->{XINHA_PLUGINS};
    use constant XINHA_TOOLBAR           => $config->{XINHA_TOOLBAR};
    use constant FCKEDITOR_CONFIG        => $config->{FCKEDITOR_CONFIG};
    use constant HTMLAREA_TOOLBAR        => $config->{HTMLAREA_TOOLBAR};

    # The minimum login name and password lengths users can enter.
    use constant LOGIN_LENGTH            => $config->{LOGIN_LENGTH} || 5;
    use constant PASSWD_LENGTH           => $config->{PASSWD_LENGTH} || 5;

    # Error Page Setting.
    use constant ERROR_URI               => '/errors/500.mc';

    # Email Settings.
    use constant SMTP_SERVER => $ENV{BRIC_TEST_SMTP} || $config->{SMTP_SERVER}
      || 'localhost';

    # Alert Settings.
    use constant ALERT_FROM => $config->{ALERT_FROM};
    use constant ALERT_TO_METH => lc $config->{ALERT_TO_METH} || 'bcc';

    # UI Settings.
    use constant FIELD_INDENT => 125;
    use constant DISABLE_NAV_LAYER       => $config->{DISABLE_NAV_LAYER};
    use constant ALLOW_WORKFLOW_TRANSFER => $config->{ALLOW_WORKFLOW_TRANSFER};
    use constant ALLOW_ALL_SITES_CX      => $config->{ALLOW_ALL_SITES_CX};
    use constant RELATED_MEDIA_UPLOAD    => $config->{RELATED_MEDIA_UPLOAD};
    use constant ALLOW_SLUGLESS_NONFIXED => $config->{ALLOW_SLUGLESS_NONFIXED};
    use constant AUTOGENERATE_SLUG       => $config->{AUTOGENERATE_SLUG};
    use constant FULL_SEARCH             => $config->{FULL_SEARCH};
    use constant BLOB_SEARCH             => $config->{BLOB_SEARCH};
    use constant EXPIRE_ON_DEACTIVATE    => $config->{EXPIRE_ON_DEACTIVATE};
    use constant YEAR_SPAN_BEFORE        => $config->{YEAR_SPAN_BEFORE} || 10;
    use constant YEAR_SPAN_AFTER         => $config->{YEAR_SPAN_AFTER}  || 10;

    # Asset settings.
    use constant STORY_URI_WITH_FILENAME => $config->{STORY_URI_WITH_FILENAME};

    # FTP Settings
    use constant ENABLE_FTP_SERVER => $config->{ENABLE_FTP_SERVER} || 0;
    use constant FTP_DEPLOY_ON_UPLOAD => $config->{FTP_DEPLOY_ON_UPLOAD} || 0;
    use constant FTP_ADDRESS       => $config->{FTP_ADDRESS}       || "";
    use constant FTP_PORT          => $config->{FTP_PORT}          || 2121;
    use constant FTP_DEBUG         => $config->{FTP_DEBUG}         || 0;
    use constant FTP_LOG           => $config->{FTP_LOG}           ||
      catfile($ENV{BRICOLAGE_ROOT} || '/usr/local/bricolage', 'ftp.log');
    use constant FTP_PID_FILE      => $config->{FTP_PID_FILE}      ||
      catfile($ENV{BRICOLAGE_ROOT} || '/usr/local/bricolage', 'ftp.pid');

    # Output Channel Settings.
    use constant DEFAULT_FILENAME => $config->{DEFAULT_FILENAME} || 'index';
    use constant DEFAULT_FILE_EXT => $config->{DEFAULT_FILE_EXT} || 'html';
    use constant ENABLE_OC_ASSET_ASSOCIATION => $config->{ENABLE_OC_ASSET_ASSOCIATION};
    use constant ALLOW_URIS_WITHOUT_CATEGORIES => $config->{ALLOW_URIS_WITHOUT_CATEGORIES};

    # Temp Dir Setting
    use constant TEMP_DIR               => $ENV{BRIC_TEMP_DIR} ||
      $config->{TEMP_DIR} || tmpdir();

    # Process Size Limit Settings
    use constant CHECK_PROCESS_SIZE     => $config->{CHECK_PROCESS_SIZE};
    use constant MAX_PROCESS_SIZE       => $config->{MAX_PROCESS_SIZE} || 56000;
    use constant CHECK_FREQUENCY        => $config->{CHECK_FREQUENCY} || 1;
    use constant MIN_SHARE_SIZE         => $config->{MIN_SHARE_SIZE} || 0;
    use constant MAX_UNSHARED_SIZE      => $config->{MAX_UNSHARED_SIZE} || 0;

    # Profiler settings
    use constant PROFILE => $config->{PROFILE} || 0;

    # Category browser setting
    use constant ENABLE_CATEGORY_BROWSER => $config->{ENABLE_CATEGORY_BROWSER};

    # L10N & Character Translation settings.
    use constant ENCODE_OK              => $] >= 5.008;
    use constant LOAD_LANGUAGES         => $config->{LOAD_LANGUAGES};
    use constant LOAD_CHAR_SETS         => $config->{LOAD_CHAR_SETS};

    # POD Settings.
    if (my $tag = $config->{RELATED_DOC_POD_TAG}) {
        die 'RELATED_DOC_POD_TAG must be "uuid", "uri", "url", or "id"'
            unless $tag eq 'uuid'
                or $tag eq 'uri'
                or $tag eq 'url'
                or $tag eq 'id';
    }
    use constant RELATED_DOC_POD_TAG    => $config->{RELATED_DOC_POD_TAG} || 'uuid';

    # XXX Shove the PERL_LOADER code into our INC hash. Bric::Util::Burner
    # will pull it out and execute it. Yes, this is a nasty hack, but it works
    # nicely, allows the code to execute after Bric::Config is completely
    # loaded, and it doesn't leave the string of perl code hanging around in
    $Bric::Config::INC{PERL_LOADER} = $config->{PERL_LOADER};

    # Set the MOD_PERL constant.
    use constant MOD_PERL => $ENV{MOD_PERL};

    # if not in MOD_PERL environment, set to 0,
    # if bricolage.conf sets HTTPD_VERSION to 'apache2' and we seem
    # to have mod_perl2, set to 2;
    # otherwise, set to 1
    use constant MOD_PERL_VERSION => $ENV{MOD_PERL}
          ? ( ($config->{HTTPD_VERSION} eq 'apache2'
                 and exists($ENV{MOD_PERL_API_VERSION})
                 and $ENV{MOD_PERL_API_VERSION} >= 2)
                ? 2
                : 1
             )
          : 0;

    use constant CACHE_DEBUG_MODE => $ENV{BRIC_CACHE_DEBUG_MODE} || 0;
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

=head1 Interface

=head2 Constructors

NONE

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

=head1 Notes

NONE

=head1 Author

Garth Webb  E<lt>garth@perijove.comE<gt>

David Wheeler E<lt>david@justatheory.comE<gt>

=head1 See Also

L<Bric::Admin>

=cut
