%#--- Documentation ---#

<%doc>

=head1 NAME

debug - Output some debuging information

=head1 VERSION

$Revision: 1.1 $

=head1 DATE

$Date: 2001-09-06 21:52:04 $

=head1 SYNOPSIS

<& '/widgets/debug/debug.mc' &>

=head1 DESCRIPTION

Output the session data as well as the environment.

=cut

</%doc>

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
foreach my $id ($$c->get_identifiers) {
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

<%doc>
$Log: debug.mc,v $
Revision 1.1  2001-09-06 21:52:04  wheeler
Initial revision

</%doc>
