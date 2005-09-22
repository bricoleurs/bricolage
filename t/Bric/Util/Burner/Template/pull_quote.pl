my $template = $burner->new_template;
$template->param(date => $element->get_value('date', 1, '%Y.%m.%d'));
return $template->output;
