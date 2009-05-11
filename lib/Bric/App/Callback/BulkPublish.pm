package Bric::App::Callback::BulkPublish;

use base qw(Bric::App::Callback);
__PACKAGE__->register_subclass;
use constant CLASS_KEY => 'bulk_publish';

use strict;
use Bric::App::Authz qw(:all);
use Bric::App::Event qw(:all);
use Bric::App::Session qw(:user);
use Bric::App::Util qw(mk_aref);
use Bric::Biz::Asset::Business::Media;
use Bric::Biz::Asset::Business::Story;
use Bric::Util::DBI qw(ANY);
use Bric::Util::Priv::Parts::Const qw(:all);
use Bric::Util::Time qw(:all);

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

    my $pub_time = $self->params->{pub_time};
    my %counts;
    for my $spec ([\@story_cat_ids, 'Story'],
                  [\@media_cat_ids, 'Media']
    ) {
        my $cat_ids = shift @$spec;
        next unless @$cat_ids;
        my $key = lc $spec->[0];
        my $pkg = 'Bric::Biz::Asset::Business::' . shift @$spec;
        for my $doc (grep { chk_authz($_, PUBLISH, 1) } $pkg->list({
            published_version => 1,
            unexpired         => 1,
            category_id       => ANY(@$cat_ids)
        })) {
            my $job = Bric::Util::Job::Pub->new({
                sched_time          => $pub_time,
                user_id             => get_user_id(),
                name                => 'Publish "' . $doc->get_name . '"',
                "$key\_instance_id" => $doc->get_version_id,
                priority            => $doc->get_priority,
            });
            $job->save;
            log_event('job_new', $job);
            $counts{$key}++;
        }

        # Publish stuff passed to publish_another().
        Bric::Util::Burner->flush_another_queue if $key eq 'story';
    }
    if (%counts) {
        if (my $c = $counts{story}) {
            $self->add_message('[quant,_1,story,stories] published.', $c);
        }
        if (my $c = $counts{media}) {
            $self->add_message('[quant,_1,media,media] published.', $c);
        }
    } else {
        $self->add_message('Nothing republished') unless %counts;
    }
}

1;
