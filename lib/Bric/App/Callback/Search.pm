package Bric::App::Callback::Search;

use base qw(Bric::App::Callback);
__PACKAGE__->register_subclass;
use constant CLASS_KEY => 'search';

use strict;
use Bric::App::Session qw(:state);
use Bric::App::Util qw(:all);
use Bric::Config qw(FULL_SEARCH);
use Bric::Util::DBI qw(ANY);
use Bric::Util::ApacheReq;

sub no_new_search {
    my $r = Bric::Util::ApacheReq->instance;
    $r->pnotes(CLASS_KEY . '.no_new_search' => 1);
}

sub substr : Callback( priority => 7 ) {
    my $self = shift;
    return if $self->apache_req->pnotes(CLASS_KEY . '.no_new_search');

    my $widget  = $self->class_key;
    my $param   = $self->params;
    my $val_fld = $self->class_key.'|value';
    my $crit    = $param->{$val_fld}
        ? (FULL_SEARCH ? '%' : '') . $param->{$val_fld} . '%'
        : '%';

    my $object  = get_state_name($widget);
    my $state   = get_state_data($widget => $object);

    # Set the search criterion and append a '%' to do a prefix search.
    $state->{criterion} = $crit;

    # Set the value that will repopulate the search box and clear the alpha
    $state->{crit_field}  = $param->{$val_fld};
    $state->{crit_letter} = '';
    $state->{timestamp} = time();
    set_state_data($widget, $object => $state);
}

sub alpha : Callback {
    my $self    = shift;
    my $widget  = $self->class_key;
    my $crit    = $self->value ? $self->value . '%' : '';
    my $object  = get_state_name($widget);
    my $state   = get_state_data($widget => $object);

    # Add a '%' to create a prefix search by first letter.
    $state->{criterion} = $crit;

    # Clear the substr search box and set the letter selector
    $state->{crit_letter} = $self->value;
    $state->{crit_field}  = '';
    $state->{timestamp} = time();
    set_state_data($widget, $object => $state);
}

sub story : Callback {
    my $self = shift;

    my (@field, @crit);

    if ($self->value eq "simple") {
        _build_fields($self, \@field, \@crit, ['simple']);
    } else {
        _build_fields(
            $self, \@field, \@crit,
            [qw(title primary_uri category_uri keyword data_text)],
        );
        _build_id_fields(
            $self, \@field, \@crit,
            [qw(element_type_id site_id subelement_id)],
        );
        _build_bool_fields($self, \@field, \@crit, [qw(active)]);
        _build_date_fields(
            $self, \@field, \@crit,
            [qw(cover_date publish_date expire_date)],
        );
    }

    # Display no results for an empty search.
    return unless @field;

    my $widget = $self->class_key;
    my $object = get_state_name($widget);
    my $state  = get_state_data($widget => $object);
    $state->{advanced_search} = ($self->value eq "advanced");
    $state->{criterion} = \@crit;
    $state->{field}     = \@field;
    $state->{timestamp} = time();
    set_state_data($widget, $object => $state);
}

sub media : Callback {
    my $self = shift;

    my (@field, @crit);

    if ($self->value eq "simple") {
        _build_fields($self, \@field, \@crit, ['simple']);
    } else {
        _build_fields(
            $self, \@field, \@crit,
            [qw(name uri keyword data_text)]
        );
        _build_id_fields(
            $self, \@field, \@crit,
            [qw(element_type_id site_id)]
        );
        _build_bool_fields($self, \@field, \@crit, [qw(active)]);
        _build_date_fields(
            $self, \@field, \@crit,
            [qw(cover_date publish_date expire_date)]
        );
    }

    # Display no results for an empty search.
    return unless @field;

    my $widget = $self->class_key;
    my $object = get_state_name($widget);
    my $state  = get_state_data($widget => $object);
    $state->{advanced_search} = ($self->value eq "advanced");
    $state->{criterion} = \@crit;
    $state->{field}     = \@field;
    $state->{timestamp} = time();
    set_state_data($widget, $object => $state);
}

sub template : Callback {
    my $self = shift;

    my (@field, @crit);

    if ($self->value eq "simple") {
        _build_fields($self, \@field, \@crit, ['simple']);
    } else {
        _build_fields(
            $self, \@field, \@crit,
            [qw(name file_name)]
        );
        _build_id_fields(
            $self, \@field, \@crit,
            [qw(site_id output_channel_id)]
        );
        _build_bool_fields($self, \@field, \@crit, [qw(active)]);
        _build_date_fields(
            $self, \@field, \@crit,
            [qw(cover_date publish_date expire_date)]
        );
    }

    # Display no results for an empty search.
    return unless @field;

    my $widget = $self->class_key;
    my $object = get_state_name($widget);
    my $state  = get_state_data($widget => $object);
    $state->{advanced_search} = ($self->value eq "advanced");
    $state->{criterion} = \@crit;
    $state->{field}     = \@field;
    $state->{timestamp} = time();
    set_state_data($widget, $object => $state);
}

sub generic : Callback {
    my $self = shift;
    my $param = $self->params;

    # Callback in 'leech' mode.  Any old page can send search criteria here

    # A '+' separated list of object field names
    my $flist  = $param->{$self->class_key . "|generic_fields"};

    # A '+' separated list of form field names who's values are the criteria for
    # the object field names in $flist above
    my $clist  = $param->{$self->class_key . "|generic_criteria"};

    # A '+' separated list of object fields that are meant to be substring
    # searches and thus should be wrapped in '%'
    my $substr = $param->{$self->class_key . "|generic_set_substr"};

    my $fields = [split('\+', $flist)];
    my $crit   = [map { $param->{$_} } split('\+', $clist)];

    my %sub = map { $_ => 1 } split('\+', $substr);

    my $i = $#{$fields};
    while ($i >= 0) {
    # Remove any criteria from the list who's value is the null string or
    # the string '_all'.
    if (($crit->[$i] eq '_all') or ($crit->[$i] eq '')) {
        splice @$fields, $i, 1;
        splice @$crit,   $i, 1;
        }

    # Check for searches that should be substring searches.
    if ($sub{$fields->[$i]}) {
        $crit->[$i] = '%'.$crit->[$i].'%';
    }
        $i--;
    }

    my $widget = $self->class_key;
    my $object = get_state_name($widget);
    my $state  = get_state_data($widget => $object);
    $state->{criterion} = $crit;
    $state->{field}     = $fields;
    set_state_data($widget, $object => $state);
}

sub clear : Callback {
    my $self = shift;
    my $widget = $self->class_key;
    my $object = get_state_name($widget);
    set_state_data($widget, $object => {});
}

###

sub _build_fields {
    my ($self, $field, $crit, $add) = @_;
    my $widget = $self->class_key;
    my $param  = $self->params;
    my $object = get_state_name($widget);
    my $state  = get_state_data($widget => $object);

    foreach my $f (@$add) {
        my $v = $param->{$self->class_key."|$f"};

        # Save the value so we can repopulate the form.
        $state->{$f} = $v;

        # Skip it if it's blank
        next unless defined $v && $v ne '';

        push @$field, $f;
        push @$crit, (FULL_SEARCH ? '%' : '') . $v . '%';
    }
    set_state_data($widget, $object => $state);
};

sub _build_id_fields {
    my ($self, $field, $crit, $add) = @_;
    my $widget = $self->class_key;
    my $param  = $self->params;
    my $object = get_state_name($widget);
    my $state  = get_state_data($widget => $object);

    foreach my $f (@$add) {
        my $v = $param->{$self->class_key."|$f"};

        # Save the value so we can repopulate the form.
        $state->{$f} = $v;

        # Skip it if it's blank
        next unless defined $v && $v =~ /^\d+$/;

        push @$field, $f;
        push @$crit, $v;
    }
    set_state_data($widget, $object => $state);
};

sub _build_bool_fields {
    my ($self, $field, $crit, $add) = @_;
    my $widget = $self->class_key;
    my $param  = $self->params;
    my $object = get_state_name($widget);
    my $state  = get_state_data($widget => $object);

    foreach my $f (@$add) {
        my $v = $param->{$self->class_key."|$f"};

        # Save the value so we can repopulate the form.
        $state->{$f} = $v;

        # Skip it if it's not boolean
        next unless defined $v && $v =~ /^(?:t|f|tf)$/;

        # The value 'tf' is a hack meaning 't' or 'f'
        # (in particular to allow returning 'active' and 'inactive' stories/media)
        $v = ANY('t', 'f') if $v eq 'tf';

        push @$field, $f;
        push @$crit, $v;
    }
    set_state_data($widget, $object => $state);
};

sub _build_date_fields {
    my ($cb, $field, $crit, $add) = @_;
    my $widget = $cb->class_key;
    my $param  = $cb->params;
    my $object = get_state_name($widget);
    my $state  = get_state_data($widget => $object);

    foreach my $f (@$add) {
        my $v_start = $param->{$widget."|${f}_start"};
        my $v_end   = $param->{$widget."|${f}_end"};

        # HACK. Adjust the end date to be inclusive by bumping it up
        # to 23:59:59.
        $v_end =~ s/00:00:00$/23:59:59/ if $v_end;

        # check date fields
        if ($v_start) {
            eval('my $check_date = DateTime->new(year=>'.CORE::substr($v_start,0,4).
                ', month=>'.CORE::substr($v_start,5,2).
                ', day=>'.CORE::substr($v_start,8,2).')');
            if ($@) {
                $cb->raise_conflict(
                    'Invalid start date ' . CORE::substr($v_start, 0, 10) . " ($f)"
                );
                $v_start = '';
            }
        }
        if ($v_end) {
            eval('my $check_date = DateTime->new(year=>'.CORE::substr($v_end,0,4).
                ', month=>'.CORE::substr($v_end,5,2).
                ', day=>'.CORE::substr($v_end,8,2).')');
            if ($@) {
                $cb->raise_conflict(
                    'Invalid end date ' . CORE::substr($v_end, 0, 10) . " ($f)"
                );
                $v_end = '';
            }
        }

        # Save the value so we can repopulate the form.
        $state->{"$f\_start"} = $v_start;
        $state->{"$f\_end"}   = $v_end;

        if ($v_start) {
            push @$field, "$f\_start";
            push @$crit,  $v_start;
        }

        if ($v_end) {
            push @$field, "$f\_end";
            push @$crit,  $v_end;
        }
    }
    set_state_data($widget, $object => $state);
};

1;
