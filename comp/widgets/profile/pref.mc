<%doc>
###############################################################################

=head1 NAME

/widgets/profile/preferences.mc - Processes submits from Preferences Profile.

=head1 VERSION

$Revision: 1.8 $

=head1 DATE

$Date: 2002-03-20 21:10:52 $

=head1 SYNOPSIS

  $m->comp('/widgets/profile/preferences.mc', %ARGS);

=head1 DESCRIPTION

This element is called by /widgets/profile/callback.mc when the data to be
processed was submitted from the Preferences Profile page.

</%doc>

%#-- Once Section --#
<%once>;
my $type = 'pref';
my $disp_name = get_disp_name($type);

my $handle_parse_format = sub {
  my ( $param, $name ) = @_;
  my @acceptable_tokens = qw( categories day month year slug );
  my ( @bad_tokens, @good_tokens );
  my $value = $param->{ 'value' };

  if( $value =~ /^\s*$/ ) {
    return "No &quot;$name&quot; value specified."
  } else {
    $value =~ s#/?(.+)/?#$1#;
    my @tokens = split( /\//, $value );
    foreach my $token ( @tokens ) {
      my $match = grep( $token eq $_ , @acceptable_tokens );

      unless( $match ) {
	push( @bad_tokens, $token );
      } else {
	push( @good_tokens, $token );
      }
    }

    $param->{ 'value' } = '/' . join( '/', @good_tokens ) . '/';

    return "The following invalid tokens were found: " . join( ", ", @bad_tokens )
      if( scalar( @bad_tokens ) >= 1 );
  }

  return undef;
};
</%once>

<%args>
$widget
$param
$field
$obj
</%args>

<%init>;
return unless( $field eq "$widget|save_cb" );
my $pref = $obj;
my $name = $pref->get_name;

# Validate URI Formats...
if( $name =~ /URI Format/ ) {
  if( my $err = &$handle_parse_format( $param, $name ) ) {
    add_msg( $err );
    return;
  }
}

$pref->set_value($param->{value});
$pref->save;
log_event('pref_save', $pref);
add_msg("$disp_name &quot;$name&quot; updated.");
set_redirect('/admin/manager/pref');
</%init>
