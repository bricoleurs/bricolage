<dl class="viewmeta">
% if ($et) {
    <dt><% $lang->maketext('Key Name') %>:</dt>
    <dd><% $et->get_key_name  . $show_element_flags->($et) %></dd>
%   if (@{$et->get_field_types}) {
    <dt><% $lang->maketext('Field Elements') %>:</dt>
    <dd>
%       $m->print(join ', ', map { $_->get_key_name . $show_data_flags->($_) } $et->get_field_types);
    </dd>
%   }

%   if (@{$et->get_containers}) {
    <dt><% $lang->maketext('Container Elements') %>:</dt>
    <dd>
%       $m->print(join ', ', map { $_->get_key_name } $et->get_containers);
    </dd>
%   }
% }
% if ($button) {
  <dt>&nbsp;</dt>
  <dd><% $button %></dd>
% }
</dl>
<%args>
$et
$button => undef
</%args>
<%once>
my $show_element_flags = sub {
    my ($at) = @_;
    my @flags;

    push @flags, 'paginated'     if $at->is_paginated;
    push @flags, 'top level'     if $at->is_top_level;
    push @flags, 'fixed url'     if $at->is_fixed_uri;
    push @flags, 'media'         if $at->is_media;
    push @flags, 'related media' if $at->is_related_media;
    push @flags, 'related story' if $at->is_related_story;

    return unless @flags;
    return '&nbsp;<span class="orangeLink">('.join(', ', @flags).')</span>';
};

my $show_data_flags = sub {
    my ($dt) = @_;
    my @flags;

    if (my $min = $dt->get_min_occurrence) {
          push @flags, "Minimum: $min";
    }

    if(my $max = $dt->get_max_occurrence) {
          push @flags, "Maximum: $max";
    }

    return unless @flags;
    return '&nbsp;<span class="orangeLink">('.join(', ', @flags).')</span>';
};
</%once>
