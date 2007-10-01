package Bric::Util::ApacheConst;

=head1 NAME

Bric::Util::ApacheConst - wrapper around Apache 1 and 2 constants classes

=head1 VERSION

$LastChangedRevision$

=cut

require Bric; our $VERSION = Bric->VERSION;

=head1 DATE

$LastChangedDate: 2006-03-18 02:10:10 +0100 (Sat, 18 Mar 2006) $

=head1 SYNOPSIS

  use Bric::Util::ApacheConst qw(:common);
  use Bric::Util::ApacheConst qw(DECLINED OK);

=head1 DESCRIPTION

This package encapsulates the C<Apache::Constants> and C<Apache2::Const>
classes so that Bricolage doesn't have to care about which version of Apache is running.
It should work as a drop-in replacement for either of those modules.

=head1 AUTHOR

Scott Lanning <slanning@cpan.org>

=cut

use strict;

require Exporter;
our @ISA = qw(Exporter);

use Bric::Config qw(:mod_perl);
BEGIN {
    if (MOD_PERL) {
        if (MOD_PERL_VERSION < 2) {
            require Apache::Constants;
            Apache::Constants->import();
            *EXPORT_TAGS = \%Apache::Constants::EXPORT_TAGS;
            *EXPORT_OK = \@Apache::Constants::EXPORT_OK;
            *EXPORT = \@Apache::Constants::EXPORT;
        }
        else {
            require Apache2::Const;
            Apache2::Const->import();
            *EXPORT_TAGS = \%Apache2::Const::EXPORT_TAGS;
            *EXPORT_OK = \@Apache2::Const::EXPORT_OK;
            *EXPORT = \@Apache2::Const::EXPORT;
        }
    }
}


1;
