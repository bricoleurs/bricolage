%#--- Documentation ---#

<%doc>

=head1 NAME

debug - Output some debuging information

=head1 VERSION

$Revision: 1.6 $

=head1 DATE

$Date: 2002-02-05 23:06:31 $

=head1 SYNOPSIS

<& '/widgets/debug/debug.mc' &>

=head1 DESCRIPTION

Output the session data as well as the environment.

=cut

</%doc>

<%once>;
my $keys_meth = $Cache::Cache::VERSION > 0.9 ? 'get_keys' : 'get_identifiers';
</%once>

%#--- Arguments ---#

<%args>
</%args>

%#--- Initialization ---#

<%init>

my $old_indent = $Data::Dumper::Indent;

$Data::Dumper::Indent = 1;

my $s = Data::Dumper::Dumper(\%HTML::Mason::Commands::session);
my $e = Data::Dumper::Dumper(\%ENV);
my $cache;
foreach my $id ($$c->$keys_meth) {
    $cache->{$id} = $$c->get($id);
}
$cache = Data::Dumper::Dumper($cache);
my %rcache = $rc->get_all;
my $rcache = Data::Dumper::Dumper(\%rcache);

$m->comp('/widgets/debug/agent.mc');
$m->comp('/widgets/debug/dump.mc', sess => $s, env => $e,
	 cache => $cache, rcache => $rcache);
$m->comp('/widgets/debug/data.mc', %ARGS);

# Reset the old indent value.
$Data::Dumper::Indent = $old_indent;

</%init>

%#--- Log History ---#


