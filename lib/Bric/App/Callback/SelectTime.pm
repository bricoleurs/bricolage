package Bric::App::Callback::SelectTime;

use base qw(Bric::App::Callback);
__PACKAGE__->register_subclass;
use constant CLASS_KEY => 'select_time';

use strict;
use Bric::App::Session qw(:state);
use Bric::App::Util qw(:aref);

my $defs = {
    min  => '00',
    hour => '00',
    day  => '01',
    sec  => '00',
    mic  => '00',
    mon  => '01',
};

my ($is_clear_state);

sub refresh : Callback(priority => 0) {
    my $self = shift;
    my $param = $self->params;
    return if $is_clear_state->($self);

    # There might be many time widgets on this page.
    my $base = mk_aref($self->value);

    foreach my $b (@$base) {
        # Keep this widget with this base name distict from others on the page.
        my $sub_widget = $self->class_key . ".$b";
        my @vals;
        my $incomplete = 0;
        # This is complements $incomplete.  It tells whether *any* time fields
        # were set.  This way we know if they started to add time fields, but
        # then stopped.
        my $has_data = 0;

        # Set up the basic parts.
        foreach my $unit (qw(year mon day hour min sec)) {
            if (exists $param->{"$b\_$unit"}) {
                my $v = $param->{"$b\_$unit"};

                # Set the incomplete flag and stop if we get an unset date
                # value.
                if ($v eq '-1') {
                    $defs->{$unit} ? (push @vals, $defs->{$unit}) : ($incomplete = 1);
                } else {
                    $has_data = 1;

                    # Collect the values.
                    push @vals, $v || '0';
                }
                set_state_data($sub_widget, $unit, $v) if defined $v;
            } else {
                # There was no field for this date part. So use the default.
                push @vals, $defs->{$unit};
                set_state_data($sub_widget, $unit, $defs->{$unit});
            }

            # Update all the time values.
        }

        # Set up the microseconds.
        if (my $mil = $param->{"$b\_mil"}) {
            if ($mil =~ /^\d{1,3}$/) {
                # It's a valid number of milliseconds. Multiply by 1000
                # to get microseconds and save.
                push @vals, $mil * 1000;
                set_state_data($sub_widget, 'mil', $vals[-1]);
            } else {
                $incomplete = 1;
            }
        } else {
            my $mic = $param->{"$b\_mic"} || $defs->{mic};
            if ($mic =~ /^\d{1,6}$/) {
                # It's a valid number of microseconds. Save it.
                push @vals, $mic;
                set_state_data($sub_widget, 'mic', $mic);
            } else {
                $incomplete = 1;
            }
        }

        if ($incomplete) {
            # If some fields were set, flag it
            if ($has_data) {
                $param->{$b . '-partial'} = 1;
            } else {
                # It's undefined.
                $param->{$b} = undef;
            }
        } else {
            # Write the date to the parameters.
            $param->{$b} = sprintf('%04d-%02d-%02d %02d:%02d:%02d.%06d', @vals);
        }
    }
}

sub clear : Callback {
    my $self = shift;

    # If the trigger field was submitted with a true value then, clear state!
    if ($is_clear_state->($self)) {
        my $s = Bric::App::Session->instance;

        # Find all the select_time widget information
        my @sel = grep(substr($_,0,11) eq 'select_time', keys %$s);

        # Clear out all the state data.
        foreach my $sub_widget (@sel) {
            set_state_data($sub_widget, {});
        }
    }
}

###

$is_clear_state = sub {
    my $self = shift;
    my $param = $self->params;
    my $trigger = $param->{$self->class_key . '|clear_cb'} || return;
    return $param->{$trigger};
};


1;
