my $template = $burner->new_template;
$template->param(cover_date => $story->get_cover_date('%Y.%m.%d'));
return $template->output;
