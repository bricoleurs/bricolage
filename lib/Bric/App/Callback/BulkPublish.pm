package Bric::App::Callback::BulkPublish;

use base qw(Bric::App::Callback);
__PACKAGE__->register_subclass;
use constant CLASS_KEY => 'bulk_publish';

use strict;
use Bric::App::Authz qw(:all);
use Bric::App::Callback::Desk;
use Bric::App::Session qw(set_state_data);
use Bric::App::Util qw(mk_aref);
use Bric::Biz::Asset::Business::Media;
use Bric::Biz::Asset::Business::Story;
use Bric::Util::DBI qw(ANY);
use Bric::Util::Priv::Parts::Const qw(:all);

sub publish_categories : Callback {
    my $self = shift;

    # Get category IDs from checkboxes
    my (@story_cat_ids, @media_cat_ids);
    my $vals = mk_aref($self->value);
    foreach my $val (@$vals) {
        $val =~ s/^(story|media)=(\d+)$//;
        my $type = $1;
        my $id   = $2;
        if ($type eq 'story') {
            push @story_cat_ids, $id;
        } else {
            push @media_cat_ids, $id;
        }
    }

    # Get story/media IDs from categories
    # XXX This permission checking doesn't allow them to publish even if the
    # document is in a workflow with a publish desk for which the user has
    # PUBLISH permission to its assets. But this is a 99% solution, and much
    # more efficient than lots of extra code to check for such a desk would be
    # (not to mention moving documents to that desk).
    my (@story_ids, @media_ids);
    @story_ids = grep { chk_authz($_, PUBLISH, 1) }
      Bric::Biz::Asset::Business::Story->list_ids({
          category_id => ANY(@story_cat_ids)
      }) if @story_cat_ids;

    @media_ids = grep { chk_authz($_, PUBLISH, 1) }
      Bric::Biz::Asset::Business::Media->list_ids({
          category_id => ANY(@media_cat_ids)
      }) if @media_cat_ids;

    # This state data is needed for comp/widgets/publish/publish.mc
    set_state_data('publish', story => \@story_ids);
    set_state_data('publish', media => \@media_ids);

    # Use the desk callback to avoid code duplication
    my $pub = Bric::App::Callback::Desk->new(
        cb_request   => $self->cb_request,
        apache_req   => $self->apache_req,
        # for some reason pkg_key is necessary, he says hours later
        pkg_key      => 'desk_asset',
        params       => {
            'desk_asset|story_pub_ids' => \@story_ids,
            'desk_asset|media_pub_ids' => \@media_ids,
            story_sort_by              => 'cover_date',
            media_sort_by              => 'cover_date',
        },
    );
    $pub->publish;
}

1;
