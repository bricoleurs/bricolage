package Bric::App::Callback::Profile::ElementData;

use base qw(Bric::App::Callback::Package);
__PACKAGE__->register_subclass(class_key => 'element_data');
use strict;
use Bric::App::Event qw(log_event);
use Bric::App::Util qw(:all);


my $type = CLASS_KEY;
my $disp_name = get_disp_name($type);


sub save : Callback {
    my $self = shift;

    return unless $self->has_perms;

    my $param = $self->request_args;
    my $ed = $self->obj;

    my $name = "&quot;$param->{name}&quot;";
    if ($param->{delete}) {
        # Deactivate it.
        $ed->deactivate();
        log_event("$type\_del", $ed);
        add_msg($self->lang->maketext("$disp_name profile [_1] deleted.",$name));
    } else {
        my $numregex = qr{^\s*\d+\s*$};

        # Roll in the changes.
        $ed->set_description($param->{'description'});
        $ed->set_max_length($param->{'max_length'})
          if defined $param->{'max_length'} && $param->{'max_length'} =~ $numregex;
        $ed->set_required(defined $param->{'required'} ? 1 : 0);
        # Note: here's another place I assume quantifier is boolean
        $ed->set_quantifier(defined $param->{'quantifier'} ? 1 : 0);

        # Save metadata/display attributes
        my $set_meta_string = sub {
            my ($ed, $f, $param) = @_;
            $ed->set_meta('html_info', $f, $param->{$f}) if defined $param->{$f};
        };
        my $set_meta_number = sub {
            my ($ed, $f, $param) = @_;
            $ed->set_meta('html_info', $f, $param->{$f})
              if defined($param->{$f}) && $param->{$f} =~ $numregex;
        };
        my $set_meta_boolean = sub {
            my ($ed, $f, $param) = @_;
            if (defined $param->{$f}) {
                $ed->set_meta('html_info', $f, 1);
            } else {
                $ed->set_meta('html_info', $f, 0);
            }
        };

        my $f = 'size';
        $set_meta_number->($ed, $f, $param);
        $f = 'disp';
        $set_meta_string->($ed, $f, $param);
        $f = 'maxlength';
        $set_meta_number->($ed, $f, $param);
        $f = 'value';
        $set_meta_string->($ed, $f, $param);
        $f = 'vals';
        $set_meta_string->($ed, $f, $param);
        $f = 'multiple';
        $set_meta_boolean->($ed, $f, $param);
        $f = 'rows';
        $set_meta_number->($ed, $f, $param);
        $f = 'cols';
        $set_meta_number->($ed, $f, $param);

        add_msg($self->lang->maketext("$disp_name profile [_1] saved.",$name));
        log_event("$type\_save", $ed);
    }

    # Save changes and redirect back to the manager.
    $ed->save();
    set_redirect(last_page());
}


1;
