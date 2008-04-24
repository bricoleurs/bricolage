<%doc>

=head1 NAME

debug - Output some debugging information

=head1 VERSION

$LastChangedRevision$

=head1 DATE

$Id$

=head1 SYNOPSIS

<& '/widgets/debug/debug.mc' &>

=head1 DESCRIPTION

Output the session data as well as the environment.

=cut

</%doc>
<%once>;
my $keys_meth = $Cache::Cache::VERSION > 0.9 ? 'get_keys' : 'get_identifiers';
</%once>
<%args>
</%args>
<%init>
my $old_indent = $Data::Dumper::Indent;

$Data::Dumper::Indent = 1;

my $s = Data::Dumper::Dumper(\%HTML::Mason::Commands::session);
my $e = Data::Dumper::Dumper(\%ENV);
my $cache;
foreach my $id ($Bric::App::Cache::STORE->$keys_meth) {
    $cache->{$id} = $Bric::App::Cache::STORE->get($id);
}
$cache = Data::Dumper::Dumper($cache);
my $rcache = Data::Dumper::Dumper($r->pnotes());

$m->comp('/widgets/debug/dump.mc', sess => $s, env => $e,
	 cache => $cache, rcache => $rcache);
$m->comp('/widgets/debug/data.mc', %ARGS);

# Reset the old indent value.
$Data::Dumper::Indent = $old_indent;
</%init>
