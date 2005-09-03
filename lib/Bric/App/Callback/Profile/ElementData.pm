package Bric::App::Callback::Profile::ElementData;

use base qw(Bric::App::Callback::Profile);
__PACKAGE__->register_subclass;
use constant CLASS_KEY => 'element_type_data';

use strict;
use Bric::App::Event qw(log_event);
use Bric::App::Authz qw(:all);
use Bric::App::Util qw(:msg :history);

my $type = CLASS_KEY;
my $disp_name = 'Field';


sub save : Callback {
    my $self = shift;

    my $param = $self->params;
    my $ed = $self->obj;
    my $elem = Bric::Biz::AssetType->lookup({ id => $ed->get_element__id });

    unless (chk_authz($elem, EDIT, 1)) {
        # If we're in here, the user doesn't have permission to do what
        # s/he's trying to do.
        add_msg("Changes not saved: permission denied.");
        $self->set_redirect(last_page());
        $self->has_perms(0);
        return;
    }

    my $name = $param->{disp};
    if ($param->{delete}) {
        # Deactivate it.
        $ed->deactivate;
        $ed->set_required(0);
        log_event("$type\_rem", $elem, { Name => $name });
        log_event("$type\_deact", $ed);
        add_msg("$disp_name profile \"[_1]\" deleted.", $name);
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

        # HACK: Size goes in twice. Don't ask me why!
        $param->{length} = $param->{size};
        for my $f (qw(size maxlength rows cols length)) {
            $set_meta_number->($ed, $f, $param);
        }

        for my $f (qw(disp value vals precision)) {
            $set_meta_string->($ed, $f, $param);
        }

        $set_meta_boolean->($ed, 'multiple', $param);

        add_msg("$disp_name profile \"[_1]\" saved.", $name);
        log_event("$type\_save", $ed);
    }

    # Save changes and redirect back to the manager.
    $ed->save();
    $self->set_redirect(last_page());
}

1;
