package Bric::Test::TieOut;

# This module is swiped and adapted from ExtUtils::MakeMaker.

sub TIEHANDLE { bless [], ref $_[0] || $_[0] }

sub PRINT {
    my $self = shift;
    push @$self, join '', @_;
}

sub PRINTF {
    my $self = shift;
    push @$self, sprintf @_;
}

sub READLINE {
    my $self = shift;
    return shift @$self;
}

sub read {
    my $self = shift;
    my $ret = join '', @$self;
    @$self = ();
    return $ret;
}

1;
