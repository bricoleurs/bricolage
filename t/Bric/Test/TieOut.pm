package Bric::Test::TieOut;

# This module is swiped and adapted from ExtUtils::MakeMaker.

sub TIEHANDLE {
    my ($pkg, $fh) = @_;
    bless {fh => $fh, flush => 1}, ref $pkg || $pkg;
}

sub PRINT {
    my $self = shift;
    push @{$self->{out}}, join '', @_;
    $self->printit if $self->{flush};
}

sub PRINTF {
    my $self = shift;
    push @{$self->{out}}, sprintf @_;
    $self->printit if $self->{flush};
}

sub printit {
    my $self = shift;
    my $fh = $self->{fh};
    print $fh $self->read;
}

sub autoflush {
    my ($self, $flush) = @_;
    $self->{flush} = $flush;
}

sub READLINE {
    my $self = shift;
    return shift @{$self->{out}};
}

sub read {
    my $self = shift;
    my $out = delete $self->{out} or return;
    return join '', @$out;
}

1;
