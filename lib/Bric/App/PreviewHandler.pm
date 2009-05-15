package Bric::App::PreviewHandler;

=head1 Name

Bric::App::PreviewHandler - Special Apache handlers used for local previewing.

=cut

# Grab the Version Number.
require Bric; our $VERSION = Bric->VERSION;

=head1 Synopsis

  <Perl>
      if (PREVIEW_LOCAL) {
          $PerlTransHandler = 'Bric::App::PreviewHandler::uri_handler';
          if (PREVIEW_MASON) {
              $PerlFixupHandler = 'Bric::App::PreviewHandler::fixup_handler';
          }
      }
  </Perl>

=head1 Description

This package is the main package used by Apache for managing the Bricolage application.
It loads all the necessary Mason and Bricolage libraries and sets everything up for
use in Apache. It is one function is handler(), which is called by mod_perl for
every request.

=cut

################################################################################
# Dependencies
################################################################################
# Standard Dependencies
use strict;

################################################################################
# Programmatic Dependences
use Bric::Config qw(:prev :err);
use Bric::Util::ApacheConst qw(DECLINED OK);
use Bric::Util::Trans::FS;

################################################################################
# Inheritance
################################################################################

################################################################################
# Function and Closure Prototypes
################################################################################

################################################################################
# Constants
################################################################################
use constant ERROR_FILE =>
  Bric::Util::Trans::FS->cat_dir(MASON_COMP_ROOT->[0][1],
                   Bric::Util::Trans::FS->split_uri(ERROR_URI));

################################################################################
# Fields
################################################################################
# Public Class Fields

################################################################################
# Private Class Fields
my $fs = Bric::Util::Trans::FS->new;

# We'll use this to check to seed if the referer is a preview page.
my $prev_qr = do {
    my $prev = $fs->cat_uri('/', PREVIEW_LOCAL);
    qr{[^/]*//[^/]*$prev};
};


################################################################################
# Instance Fields
################################################################################

################################################################################
# Class Methods
################################################################################

=head1 Interface

=head2 Constructors

NONE.

=head2 Destructors

NONE.

=head2 Public Class Methods

NONE.

=head2 Public Functions

=over 4

=item my $status = uri_handler()

Handles the URI Translation phase of the Apache request if the PREVIEW_LOCAL
directive is true. Otherwise unused. It's job is to ensure that files requested
directly from the preview directory (/data/preview) as if they were requested
from the document root (/) are directed to the correct file.

B<Throws:> NONE.

B<Side Effects:> This handler will slow Bricolage, as it will be executing a
fair bit of extra code on every request. It is thus recommended to use a
separate server for previews.

B<Notes:> NONE.

=cut

sub uri_handler {
    my $r = shift;
    # Do nothing to subrequests.
    return DECLINED if $r->main;

    my $ret = eval {
        # Decline the request unless it's coming from the preview directory.
        {
            local $^W;
            return DECLINED unless $r->headers_in->{'referer'} =~ $prev_qr;
        }
        # Grab the URI and break it up into its constituent parts.
        my $uri = $r->uri;
        my @dirs = $fs->split_uri($uri);
        # Let the request continue if the file exists.
        return DECLINED if -e $fs->cat_dir(MASON_COMP_ROOT->[0][1], @dirs);
        # Let the request continue (with a 404) if the file doesn't exist in
        # the preview directory.
        return DECLINED unless -e $fs->cat_dir(
            MASON_COMP_ROOT->[0][1], PREVIEW_LOCAL, @dirs
        );
        # If we're here, it exists in the preview directory. Point the request
        # to it.
        $r->pnotes('burner.preview' => 1);
        $r->uri( $fs->cat_uri('/', PREVIEW_LOCAL, $uri) );
        return DECLINED;
    };
    return $@ ? handle_err($r, $@) : $ret;
}

=item my $status = fixup_handler()

Runs after the MIME-checking request phase so that, if the content-type is not
text/html. Only used when both the C<PREVIEW_LOCAL> and C<PREVIEW_MASON>
directives have been enabled, as it will prevent Mason from munging non-Mason
files such as images.

B<Throws:> NONE.

B<Side Effects:> This handler will slow Bricolage, as it will be executing a
fair bit of extra code on every request. It is thus recommended to use a
separate server for previews, or to disable Mason for previews on the Bricolage
server.

B<Notes:> NONE.

=cut

sub fixup_handler {
    my $r = shift;
    # Do nothing to subrequests.
    return OK if $r->main;

    my $ret = eval {
        # Start by disabling browser caching.
        $r->no_cache(1);
        # Just return if it's an httpd content type.
        my $ctype = $r->content_type;
        return OK if $ctype =~ /^httpd/;
        # Set the default handler if its content type is known and it's not
        # text/html.
        $r->handler('default-handler') if $ctype && $ctype ne 'text/html';
        return OK;
    };
    return $@ ? handle_err($r, $@) : $ret;
}

################################################################################

=item my $status = handle_err($r, $err)

Handles errors for the other handlers in this class.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub handle_err {
    my ($r, $err) = @_;

    $r->uri(ERROR_URI);
    $r->filename(ERROR_FILE);

    $err = Bric::Util::Fault::Exception::AP->new(
        error => 'Error executing PreviewHandler',
        payload => $err,
    );
    $r->pnotes('BRIC_EXCEPTION' => $err);

    # Send the error(s) to the apache error log.
    $r->log->error($err->full_message);

    # Exception::Class::Base provides trace->as_string, but trace_as_text is
    # not guaranteed. Use print STDERR to avoid escaping newlines.
    print STDERR $err->can('trace_as_text')
      ? $err->trace_as_text
      : join ("\n",
              map {sprintf "  [%s:%d]", $_->filename, $_->line }
                $err->trace->frames),
        "\n";

    # Return OK so that Mason can handle displaying the error element.
    return OK;
}

=back

=head1 Private

=head2 Private Class Methods

NONE.

=head2 Private Instance Methods

NONE.

=head2 Private Functions

NONE.

=cut

1;
__END__

=head1 Notes

NONE.

=head1 Author

David Wheeler <david@justatheory.com>

=head1 See Also

L<Bric|Bric>

=cut
