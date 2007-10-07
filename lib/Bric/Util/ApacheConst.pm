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

            # ok, let's try this another way....            
            Apache2::Const->import(qw(:common :http));

            # this sucks, but if you want to use a different constant,
            # you'll have to add it here
            @Bric::Util::ApacheConst::EXPORT = ();
            %Bric::Util::ApacheConst::EXPORT_TAGS = (
                common => [qw(DECLINED OK FORBIDDEN)],
                http   => [qw(HTTP_INTERNAL_SERVER_ERROR HTTP_FORBIDDEN
                              HTTP_NOT_FOUND HTTP_OK)],
            );
            @Bric::Util::ApacheConst::EXPORT_OK =
              map { ( $_, @{ $Bric::Util::ApacheConst::EXPORT_TAGS{$_} } ) }
                keys %Bric::Util::ApacheConst::EXPORT_TAGS;
        }
    }
}


1;
