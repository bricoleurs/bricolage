package Bric::Profile::Templates;
use base qw(HTML::Mason::Plugin);

use Bric::Config qw(TEMPLATE_BURN_PKG);
use Bric::Util::Burner qw(:modes);
use Bric::Util::DBI qw(prepare_c execute);
use Time::HiRes;

sub start_component_hook {
    my ($self, $context) = @_;
    push @{ $self->{timers} }, Time::HiRes::time;
}

sub end_component_hook {
    my ($self, $context) = @_;

    my $end_time = Time::HiRes::time;
    my $duration = $end_time - pop @{ $self->{timers} };

    my ($burner, $element) = do {
        no strict 'refs';
        ${TEMPLATE_BURN_PKG . '::burner'}, ${TEMPLATE_BURN_PKG .
'::element'};
    };
    my $story_element_id = ref $element ? $element->get_id : 0;
    my $comp_path = $context->comp->path;
    my $output_channel_id = $burner->get_oc->get_id;
    my $mode = $burner->get_mode;

    my $sql = q{
        INSERT INTO profile_comp
        (end_time, duration, story_element_id, comp_path,
         output_channel_id, mode)
        VALUES (to_timestamp(?), ?, ?, ?, ?, ?)};
    my $insert = prepare_c($sql);
    execute($insert, $end_time, $duration, $story_element_id, $comp_path,
                     $output_channel_id, $mode);
}

1;
