use strict;
use File::Spec::Functions qw(catdir updir);
use FindBin;
use lib catdir $FindBin::Bin, updir, 'lib';
use bric_upgrade qw(:all);
use Bric::Util::DBI qw(:all);
use POSIX qw(strftime);
use Bric::Util::Trans::FS;
use File::Spec::Functions qw(catfile);

# check if we're already upgraded.
exit if test_index 'fkx_story__story_uri';

for my $type (qw(story media)) {
    do_sql
      qq{CREATE INDEX fkx_$type\__$type\_uri ON $type\_uri($type\__id)},

      qq{CREATE UNIQUE INDEX udx_$type\_uri__site_id__uri
         ON $type\_uri(lower_text_num(uri, site__id))},

      qq{ALTER TABLE $type\_uri
         ADD CONSTRAINT fk_$type\__$type\_uri FOREIGN KEY ($type\__id)
             REFERENCES $type(id) ON DELETE CASCADE},

      qq{ALTER TABLE $type\_uri
         ADD CONSTRAINT fk_$type\__site__id FOREIGN KEY (site__id)
             REFERENCES site(id) ON DELETE CASCADE},
      ;
}

my %uri_format_hash = ( 'categories' => '',
                        'day'        => '%d',
                        'month'      => '%m',
                        'slug'       => '',
                        'year'       => '%Y' );

my $oc_formats = load_ocs();

# Set the time zone to the preferred zone.
$ENV{TZ} = col_aref("select value from pref where name = 'Time Zone'")->[0];
POSIX::tzset;

# Use our own DIE.
local $SIG{__DIE__}= \&error;

my ($type, $aid, $uri, $ocname, $rolled_back);
insert_story_uris($oc_formats);
insert_media_uris($oc_formats);

##############################################################################

sub insert_story_uris {
    my $oc_formats = shift;
    $type = 'story';

    # Figure out if they're using file names for story URIs.
    my $use_fn = uri_with_file_name();

    my $sel = prepare(q{
      SELECT DISTINCT s.id, s.cover_date, i.slug, c.uri,
                      so.output_channel__id, s.site__id,
             CASE WHEN et.fixed_url = 1
                  THEN 'fixed_uri_format'
                  ELSE 'uri_format'
             END
      FROM   story s, story_instance i, story__category sc, category c,
             story__output_channel so, element e, at_type et
      WHERE  s.id = i.story__id
             AND so.story_instance__id = i.id
             AND sc.story_instance__id = i.id
             AND c.id = sc.category__id
             AND s.current_version = i.version
             AND i.checked_out = (
                 SELECT MAX(checked_out)
                 FROM   story_instance
                 WHERE  version = i.version
                        AND story__id = i.story__id
             )
             AND s.active = 1
             AND s.element__id = e.id
             AND e.type__id = et.id
      ORDER  BY s.id;
    });

    my $ins = prepare(q{INSERT INTO story_uri (story__id, site__id, uri)
                        VALUES (?, ?, ?)});

    execute($sel);
    my ($cover_date, $slug, $cat_uri, $ocid, $site_id, $format, %seen);
    bind_columns($sel, \($aid, $cover_date, $slug, $cat_uri, $ocid,
                         $site_id, $format));
    my $last = -1;
    while (fetch($sel)) {
        %seen = () if $aid != $last;
        $last = $aid;

        my $oc = $oc_formats->{$ocid};
        $uri = build_uri($oc, $cover_date, $cat_uri, $ocid, $format, $slug);
        $ocname = $oc->{name};

        if ($use_fn) {
            my $fname = $oc->{use_slug}
              ? $slug || $oc->{filename}
              : $oc->{filename};
            if ($fname) {
                $fname .= ".$oc->{file_ext}"
                  if defined $oc->{file_ext} && $oc->{file_ext} ne '';
                $uri = Bric::Util::Trans::FS->cat_uri($uri, $fname);
            }
        }
#        next if $seen{$uri}++;
        execute($ins, $aid, $site_id, $uri);
    }
}

sub insert_media_uris {
    my $oc_formats = shift;
    $type = 'media';

    my $sel = prepare(q{
      SELECT DISTINCT m.id, m.cover_date, c.uri, mo.output_channel__id,
                      m.site__id, i.file_name,
             CASE WHEN et.fixed_url = 1
                  THEN 'fixed_uri_format'
                  ELSE 'uri_format'
             END
      FROM   media m, media_instance i, category c,
             media__output_channel mo, element e, at_type et
      WHERE  m.id = i.media__id
             AND mo.media_instance__id = i.id
             AND c.id = i.category__id
             AND m.current_version = i.version
             AND i.checked_out = (
                 SELECT MAX(checked_out)
                 FROM   media_instance
                 WHERE  version = i.version
                        AND media__id = i.media__id
             )
             AND m.active = 1
             AND m.element__id = e.id
             AND e.type__id = et.id
      ORDER  BY m.id
    });

    my $ins = prepare(q{INSERT INTO media_uri (media__id, site__id, uri)
                        VALUES (?, ?, ?)});

    execute($sel);
    my ($cover_date, $cat_uri, $ocid, $site_id, $format, $filename, %seen);
    bind_columns($sel, \($aid, $cover_date, $cat_uri, $ocid, $site_id,
                         $filename, $format));
    my $last = -1;
    while (fetch($sel)) {
        %seen = () if $aid != $last;
        $last = $aid;
        next unless defined $filename && $filename ne '';

        my $oc = $oc_formats->{$ocid};
        $uri = build_uri($oc, $cover_date, $cat_uri, $ocid, $format);
        $uri = Bric::Util::Trans::FS->cat_uri($uri, $filename);
        $ocname = $oc->{name};
        next if $seen{$uri}++;
        execute($ins, $aid, $site_id, $uri);
    }
}

##############################################################################

sub build_uri {
    my ($oc, $cover_date, $cat_uri, $ocid, $format, $slug) = @_;
    my @path = ('', defined $oc->{pre_path} ? $oc->{pre_path} : ());
    my @tokens = split '/', $oc->{$format};

    # iterate over tokens pushing each onto @path
    foreach my $token (@tokens) {
        next unless $token;
        if ($uri_format_hash{$token}  ne '') {
            # Add the cover date value.
            push @path, strftime($uri_format_hash{$token},
                                 db_date_parts($cover_date));
        } else {
            if ($token eq 'categories') {
                # Add Category
                push @path, $cat_uri;
            } elsif ($token eq 'slug' and $type eq 'story') {
                # Add the slug.
                next unless defined $slug && $slug ne '';
                push @path, $slug;
            }
        }
    }

    # Add the post value.
    push @path, $oc->{pre_path} if $oc->{pre_path};
    return Bric::Util::Trans::FS->cat_uri(@path);
}

##############################################################################

sub load_ocs {
    # Load the URI patterns.
    my $sth = prepare('
      SELECT id, name, uri_format, fixed_uri_format, pre_path, post_path,
             use_slug, filename, file_ext
      FROM   output_channel
    ');

    my %oc_formats;
    execute($sth);
    my ($id, $name, $urif, $furif, $pre, $post, $use_slug, $fn, $ext);
    bind_columns($sth, \($id, $name, $urif, $furif, $pre, $post, $use_slug,
                         $fn, $ext));
    while (fetch($sth)) {
        $oc_formats{$id} = { uri_format       => $urif,
                             fixed_uri_format => $furif,
                             pre_path         => $pre,
                             post_path        => $post,
                             name             => $name,
                             use_slug         => $use_slug,
                             filename         => $fn,
                             file_ext         => $ext,
                           };
    }
    return \%oc_formats;
}

##############################################################################

sub uri_with_file_name {
    my $conf_file = $ENV{BRICOLAGE_ROOT} || '/usr/local/bricolage';
    $conf_file = catfile($conf_file, 'conf', 'bricolage.conf');
    return 0 unless -e $conf_file;
    open CONFIG, $conf_file or die "Cannot open $conf_file";
    while (<CONFIG>) {
        chomp;                  # no newline
        s/#.*//;                # no comments
        s/^\s+//;               # no leading white
        s/\s+$//;               # no trailing white
        next unless length;     # anything left?
        next unless /^STORY_URI_WITH_FILENAME/i;
        # Get the variable and its value.
        my ($var, $val) = split(/\s*=\s*/, lc, 2);
        unless (defined $val and length $val) {
            print STDERR "Syntax error in $conf_file at line $.: '$_'\n";
            exit 1;
        }

        return $val eq 'on' || $val eq 'yes' || $val eq '1' ? 1 : 0;
    }
}

##############################################################################

sub error {
    my $err = shift;
    $uri ||= '';
    $ocname ||= '';
    rollback();
    $err = ref $err ? $err->as_text : $err;
    $|++;
    print qq{

    #######################################################
    !!!!!!!!!!!!! ERROR ERROR ERROR ERROR !!!!!!!!!!!!!!!!!

    There was an error inserting the URIs for $type # $aid
    Most likely it did not have a unique URI. The URI that
    caused the error was:

      $uri

    Non-unique URIs can be created by cloning a document
    and then neglecting to change its slug, cover date,
    and category associations sufficiently to differentiate
    the clone's URI from the original's.

    The above URI was generated for the "$ocname" output
    channel. Please make sure that all of its URIs are
    unique and try again. You'll need to either restore the
    database or clone and fix the issue in the Bricolage
    UI, or drop the new tables "story_uri" and "media_uri",
    fix the issue directly in the database, and then run
    `make upgrade` again.

    For reference, the error encountered was:

    $err

    !!!!!!!!!!!!! ERROR ERROR ERROR ERROR !!!!!!!!!!!!!!!!!
    #######################################################
} unless $rolled_back;
    $rolled_back = 1;
    exit(1);
}

1;
__END__
