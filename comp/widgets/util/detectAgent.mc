<%doc>
###############################################################################

=head1 NAME

detectAgent.mc - Detects the agent's browser, it's version, and the OS.

=head1 VERSION

$Revision: 1.3 $

=head1 DATE

$Date: 2001-11-20 00:04:08 $

=head1 SYNOPSIS

  my $agent = $m->comp('/widgets/util/detectAgent.mc');
  # my %agent = $m->comp('/lib/util/detectAgent.mc');
  print "Browser: $agent->{browser}\n";
  print "Version: $agent->{version}\n";
  print "OS:      $agent->{os}\n";
  print "Type:    $agent->{type}\n";

=head1 DESCRIPTION

Calling the element detectAgent.mc with no arguments will return an anonymous
hash containing the following keys:

=over 4

=item *

browser - The name of the browser.

=item *

version - The version of the browser.

=item *

os - The operating system.

=item *

type - One of:

=over 4

=item *

Browser - A regular user.

=item *

Robot - A robot.

=item *

Crud - An unidentifiable robot or user agent based on an HTTP library such as
Microsoft URL Control.

=back

=back

In the event that a field cannot be recognized, the string "Unknown" is
returned. This may occur in the browser, version, and os fields.

</%doc>

<%init>;
# Return it if we got it.
my $ua = get_state_data('util', 'user-agent');
return wantarray ? %$ua : $ua if $ua;

# We don't got it. So get it.
#(my $agent = lc $r->header_in('User-Agent')) =~ s/_/ /;
(my $agent = lc $ENV{HTTP_USER_AGENT}) =~ s/_/ /;
my ($browser, $os, $version, $type);

# Figure out the browser and its version.
if (index($agent, 'msie') > -1) {
    # It's Internet Explorer.
    $browser = 'Internet Explorer';
	($version) = $agent =~ /msie\s*(\d+(\.\d*)?)/;
} elsif (index($agent, 'mozilla') > -1) {
    # It's Netscape or Mozilla. Find out which.
    $browser = index($agent, 'gecko') > -1 ? 'Mozilla' : 'Netscape';
    ($version) = $agent =~ /^\w+\/(.*?)\s/;
} elsif (index($agent, 'opera') > -1) {
    # It's Opera.
    $browser = 'Opera';
    ($version) = $agent =~ /opera\s*(\d+(\.\d*)?)/;
} elsif (index($agent, 'lynx') > -1) {
    # It's Lynx.
    $browser = 'Lynx';
    ($version) = $agent =~ /^\w+\/(.*?)\s/;
} else {
    # Browser is unknown. Grab what we can.
    ($browser, $version) = $agent =~ /^(.*?)\/(.*?)\s/;

    # Isolate robots...
    if    ($agent =~ /sitesnagger/)                   { $type = 'Robot'; }
    elsif ($browser =~ /googlebot/)                   { $type = 'Robot'; }
    elsif ($browser =~ /slurp/)                       { $type = 'Robot'; }
    elsif ($browser =~ /nttdirectory/)                { $type = 'Robot'; }
    elsif ($browser =~ /fast-webcrawler/)             { $type = 'Robot'; }
    elsif ($browser =~ /spider/)                      { $type = 'Robot'; }

    # Isolate "crud"... I.E. "non-browsers"...
    if    ($agent =~ /frontpage/)                     { $type = 'Crud'; }
    elsif ($agent =~ /microsoft url control/)         { $type = 'Crud'; }
    elsif ($agent =~ /gazz/)                          { $type = 'Crud'; }
    elsif ($agent =~ /proxy/)                         { $type = 'Crud'; }
    elsif ($agent =~ /^-$/)                           { $type = 'Crud'; }
}

# Play "Guess the OS"...
if    ($agent =~ /windows\s*nt/)                  { $os = "Windows NT"; }
elsif ($agent =~ /windows\s*(\d+(\.\d+)?)/)       { $os = "Windows $1"; }
elsif ($agent =~ /win95/)                         { $os = "Windows 95"; }
elsif ($agent =~ /win98/)                         { $os = "Windows 98"; }
elsif ($agent =~ /winnt/)                         { $os = "Windows NT"; }
elsif ($agent =~ /(macos|macintosh|mac|powerpc)/) { $os = "MacOS";    }
elsif ($agent =~ /(linux|freebsd|sunos)/)         { $os = "SomeNix";    }

# Create the data hash.
$ua = { browser => $browser || 'Unknown',
	version => $version || 'Unknown',
	os      => $os || 'Unknown',
	type    => $type || 'Browser'
      };

# Cache it with the session data.
set_state_data('util', 'user-agent', $ua);

# Return it.
return wantarray ? %$ua : $ua;
</%init>

