package Bric::App::Callback::Util::OutputChannel;

use strict;
use Bric::App::Event qw(log_event);
use Bric::App::Util qw(:aref);

use base qw(Exporter);
our @EXPORT_OK = qw(update_output_channels);
our %EXPORT_TAGS = (all => \@EXPORT_OK);


sub update_output_channels {
    my ($cb, $element, $param) = @_;

    my $type = $element->key_name();
    my ($oc_ids, @to_add, @to_delete, %checked_ocs);
    my %existing_ocs = map { $_->get_id => $_ } $element->get_output_channels;

    $oc_ids = mk_aref($param->{"oc_id"});

    # Bail unless there are categories submitted via the UI. Otherwise we end
    # up deleting categories added during create().  This should also prevent
    # us from ever somehow deleting all categories on a story, which really
    # screws things up (the error is not (currently) fixable through the UI!)
    return unless @$oc_ids;

    foreach my $oc_id (@$oc_ids) {
        # Mark this output channel as seen so we don't delete it later
        $checked_ocs{$oc_id} = 1;

        # If the output channel already exists, don't add it again
        next if (defined $existing_ocs{$oc_id});

        # Since the output channel doesn't exist, we need to add it
        my $oc = Bric::Biz::OutputChannel->lookup({ id => $oc_id });
        push @to_add, $oc;
        log_event($type . '_add_oc', $element, { 'Output Channel' => $oc->get_name });
    }

    $element->add_output_channels(@to_add);

    # Set primary output channel.
    $element->set_primary_oc_id($param->{primary_oc_id})
        if exists $param->{primary_oc_id};

    my $primary = $param->{"primary_oc_id"} || $element->get_primary_oc_id;
    for my $oc_id (keys %existing_ocs) {
        my $oc = $existing_ocs{$oc_id};
        # If the output channel isn't still in the list of categories, delete it
        if (!(defined $checked_ocs{$oc_id})) {
            if ($oc_id == $primary) {
                $cb->raise_conflict(
                    'Output Channel "[_1]" cannot be dissociated because it is the primary output channel',
                    $oc->get_name,
                );
                $param->{__data_errors__} = 1;
                next;
            }

            push @to_delete, $oc;
            log_event($type . '_del_oc', $element, { 'Output Channel' => $oc->get_name });
        }
    }

    $element->del_output_channels(@to_delete);
}

1;

=head1 Name

Bric::App::Callback::Util::OutputChannel - Utility function for adding/removing OCs

=head1 Synopsis

  use Bric::App::Callback::Util::OutputChannel qw(:all);
  update_output_channels($element, $widget, $params);

=head1 Description

This module provides utility functions for updating Output Channel associations
based on form input provided by Story and Media profile pages.

=head1 Interface

=head2 Functions

=head3 update_output_channels

  update_output_channels($story, $params);

Updates the output channels for C<$story> by pulling the OC data from
C<$params>. See
L<Bric::App::Callback::Profile::Story|Bric::App::Callback::Profile::Story> for a
sample usage.

=head1 Author

Marshall Roch <marshall@exclupen.com>

=head1 See Also

=over 4

=item L<Bric::App::Callback::Profile::Story|Bric::App::Callback::Profile::Story>

=item L<Bric::App::Callback::Profile::Media|Bric::App::Callback::Profile::Media>

=back

=head1 Copyright and License

Copyright (c) 2006 Marshall Roch. See L<Bric::License|Bric::License> for
complete license terms and conditions.

=cut
