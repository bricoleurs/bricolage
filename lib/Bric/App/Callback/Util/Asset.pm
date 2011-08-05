package Bric::App::Callback::Util::Asset;

use strict;
use Bric::App::Event qw(log_event);
use Bric::App::Session qw(:user);

sub new { bless {} => shift }

sub cancel_checkout {
    my ($self, $ass) = @_;
    $ass->cancel_checkout;
    my $kn = $ass->key_name;
    my $class = ref $ass;
    $class =~ s/::Media::.+$/::Media/ if $class =~ /Business::Media/;

    log_event("$kn\_cancel_checkout", $ass);
    if ($ass->isa('Bric::Biz::Asset::Template')) {
        my $sb = Bric::Util::Burner->new({user_id => get_user_id()});
        $sb->undeploy($ass);
    }

    # If the asset was last recalled from the library, then remove it from the
    # desk and workflow. We can tell this because there will only be one
    # $kn\_moved event and one $kn\_checkout event since the last
    # $kn\_add_workflow event.

    my @events = Bric::Util::Event->list({
        class => $class,
        obj_id => $ass->get_id
    });

    my ($desks, $cos) = (0, 0);
    while (@events && $events[0]->get_key_name ne "$kn\_add_workflow") {
        my $ekn = shift(@events)->get_key_name;
        if ($ekn eq "$kn\_moved") {
            $desks++;
        } elsif ($ekn eq "$kn\_checkout") {
            $cos++
        }
    }

    # If one move to desk, and one checkout, and this isn't the first time the
    # asset has been in workflow since it was created...
    # XXX Two events upon creation: $kn\_create and $kn\_moved.

    if ($desks == 1 && $cos == 1 && @events > 2) {
        # It was just recalled from the library. So remove it from the
        # desk and from workflow.
        my $desk = $ass->get_current_desk;
        $desk->remove_asset($ass);
        $ass->set_workflow_id(undef);
        $desk->save;
        $ass->save;
        log_event("$kn\_rem_workflow", $ass);
    } else {
        # Just save the cancelled checkout. It will be left in workflow for
        # others to find.
        $ass->save;
    }
}

sub remove {
    my ($self, $ass) = @_;
    my $desk = $ass->get_current_desk;
    $desk->checkin($ass) if $ass->get_checked_out;
    $desk->remove_asset($ass);
    if ($ass->isa('Bric::Biz::Asset::Template')) {
        my $burn = Bric::Util::Burner->new;
        $burn->undeploy($ass);
        my $sb = Bric::Util::Burner->new({user_id => get_user_id() });
        $sb->undeploy($ass);
    }
    $ass->set_workflow_id(undef);
    $ass->deactivate;
    $desk->save;
    $ass->save;
    my $kn = $ass->key_name;
    log_event("$kn\_rem_workflow", $ass);
    log_event("$kn\_deact", $ass);
};

1;

=head1 Name

Bric::App::Callback::Util::Asset - Asset utilities for callbacks

=head1 Synopsis

  use Bric::App::Callback::Util::Asset;
  Bric::App::Callback::Util::Asset->cancel_checkout($asset);

=head1 Description

This module provides utility methods for managing Bricolage assets.

=head1 Interface

=head2 Constructors

=head3 new

  my $au = Bric::App::Callback::Util::Asset->new;

Constructs a new Bric::App::Callback::Util::Asset object.

=head2 Class Methods

=head3 cancel_checkout

  Bric::App::Callback::Util::Asset->cancel_checkout($asset);

Cancels the checkout of C<$asset>. This method does its best to remove all
vestiges of the current checkout of the asset. If the asset is a template, it
will be undeployed from the user's sandbox.

=head3 remove

  Bric::App::Callback::Util::Asset->remove($asset);

Checks in an asset (if it's checked out), removes it from workflow, and
deactivates it. If the asset is a template, it will be undeployed.

=head1 Author

David E. Wheeler <david@justatheory.com>

=head1 See Also

=over 4

=item L<Bric::App::Callback::Desk>

=item L<Bric::App::Callback::Story>

=item L<Bric::App::Callback::Media>

=item L<Bric::App::Callback::Template>

=back

=head1 Copyright and License

Copyright (c) 2010 Kineticode, Inc. See L<Bric::License|Bric::License> for
complete license terms and conditions.

=cut
