package Bric::App::Callback::Profile::FieldType;

use base qw(Bric::App::Callback::Profile);
__PACKAGE__->register_subclass;
use constant CLASS_KEY => 'field_type';

use strict;
use Bric::App::Event qw(log_event);
use Bric::App::Authz qw(:all);
use Bric::App::Util qw(:history);

my $type = CLASS_KEY;
my $disp_name = 'Field';


sub save : Callback {
    my $self = shift;

    my $param = $self->params;
    my $ed = $self->obj;
    my $elem = Bric::Biz::ElementType->lookup({ id => $ed->get_element_type_id });

    unless (chk_authz($elem, EDIT, 1)) {
        # If we're in here, the user doesn't have permission to do what
        # s/he's trying to do.
        $self->raise_forbidden('Changes not saved: permission denied.');
        $self->set_redirect(last_page());
        $self->has_perms(0);
        return;
    }

    my $name = $param->{name};
    if ($param->{delete}) {
        # Deactivate it.
        $ed->deactivate;
        $ed->set_min_occurrence(0);
        log_event("$type\_rem", $elem, { Name => $name });
        log_event("$type\_deact", $ed);
        $self->add_message(qq{$disp_name profile "[_1]" deleted.}, $name);
    } else {
        my $numregex = qr{^\s*\d+\s*$};
        my $meths = $ed->my_meths;

        # Save metadata/display attributes
        my $set_meta_string = sub {
            my ($ed, $f, $param) = @_;
            my $set = $meths->{$f}->{set_meth};
            $set->($ed, $param->{$f}) if exists $param->{$f};
        };
        my $set_meta_number = sub {
            my ($ed, $f, $param) = @_;
            my $set = $meths->{$f}->{set_meth};
            my $val = $param->{$f};
            return unless defined $val;
            $val = 0 if $val eq '';
            return unless $val =~ $numregex;
            $set->($ed, $val );
        };
        my $set_meta_boolean = sub {
            my ($ed, $f, $param) = @_;
            my $set = $meths->{$f}->{set_meth};
            $set->($ed, defined $param->{$f} ? 1 : 0);
        };

        for my $f (qw(max_length rows cols length precision min_occurrence max_occurrence)) {
            $set_meta_number->($ed, $f, $param);
        }

        for my $f (qw(vals name description widget_type)) {
            $set_meta_string->($ed, $f, $param);
        }

        # The default value for checkboxes is boolean.
        if ($ed->get_widget_type eq 'checkbox') {
            $set_meta_boolean->($ed, 'default_val', $param);
        }

        # All other default vals are strings.
        else {
            $set_meta_string->($ed, 'default_val', $param);
        }

        for my $f (qw(multiple)) {
            $set_meta_boolean->($ed, $f, $param);
        }

        # The occurrence specs are string variables
        #for my $f (qw(min_occurrence max_occurrence)) {
        #    $set_meta_string->($ed, $f, $param);
        #}

        $self->add_message(qq{$disp_name profile "[_1]" saved.}, $name);
        log_event("$type\_save", $ed);
    }

    # Save changes and redirect back to the manager.
    $ed->save();
    $self->set_redirect(last_page());
}

1;
