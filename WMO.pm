package Weather::WMO;
require 5.004;
require Exporter;

=head1 NAME

Weather::WMO - routines for parsing WMO abbreviated header lines

=head1 DESCRIPTION

Weather::WMO is a module for parsing WMO abbreviated header lines
in World Meterological Organization-formatted weather products.

For more information, see http://www.nws.noaa.gov/oso/head.shtml

=head1 EXAMPLE

    require Weather::WMO;

    $line = "FPUS61 KOKX 171530";

    unless (Weather::WMO::valid($line)) {
        die "\'$line\' is not a valid header.\n";
    }

    $WMO = new Weather::WMO($line);

    print "WMO\t", $WMO->WMO, "\n";
    print "product\t", $WMO->product, "\n";     # FPUS61
    print "station\t", $WMO->station, "\n";     # KOKX
    print "time\t", $WMO->time, "\n";           # "171530"

    # other constructors
    $WMO = new Weather::WMO qw(FPUS51 KNYC 041200 PAA);

    $WMO = new Weather::WMO;
    $WMO->WMO="FPUS51 KNYC 041200 (PAA)";

=head1 AUTHOR

Robert Rothenberg <wlkngowl@unix.asb.com>

=cut

use constant PRODUCT => 'PRODUCT';

@ISA = qw(Exporter);
@EXPORT = qw(PRODUCT);

use vars qw($VERSION $AUTOLOAD);
$VERSION = "1.1.0";

use Carp;

sub initialize {
    my $self = shift;
    $self->{WMO} = undef;
}

sub new {
    my $this = shift;
    my $class = ref($this) || $this;
    my $self = {};
    bless $self, $class;
    $self->initialize();
    $self->import(@_);
    return $self;
}

sub import {
    my $self = shift;
    export $self;

    my $WMO, $product, $station, $time, $addendum;

    if (defined($self{WMO})) {
        croak "WMO already created";
    }

    if (@_) {
        if (@_==1) {
            $WMO = shift;
            ($product, $station, $time, $addendum) = split(/ /, $WMO);
            $addendum =~ s/\(((AA|CC|RR|P[A-X])[A-X])\)/$1/;
        } else {
            ($product, $station, $time, $addendum)=@_;
            $WMO = "$product $station $time";
            if (defined($addendum)) {
                $WMO .= " ($addendum)";
            }
        }
    }    

    if (defined($WMO)) {
        $self->{WMO} = $WMO;
        unless (valid($WMO)) {
            croak "Invalid WMO: $WMO";
        }
    }

    $self->{product} = $product;
    $self->{T1} = substr($product, 0, 1);
    $self->{T2} = substr($product, 1, 1);
    $self->{T1T2} = $self->{T1}.$self->{T2};
    $self->{TT} = $self->{T1T2};
    $self->{A1} = substr($product, 2, 1);
    $self->{A2} = substr($product, 3, 1);
    $self->{A1A2} = $self->{A1}.$self->{A2};
    $self->{ii} = substr($product, 4, 2);
    if ($self->{T1} =~ m/[ABCEFMNRSWV]/) {
        $self->{region} = $self->{A1A2};
    } else {
        $self->{region} = undef;
    }
    $self->{station} = $station;
    $self->{time} = $time;
    $self->{addendum} = $addendum;
}

sub valid {
    my $arg = shift;
    if ($arg =~ m/^[A-Z]{4}\d{2} [A-Z]{3,4} \d{4,6}( \((AA|CC|RR|P[A-X])[A-X]\))?$/) {
        return 1;
    } else {
        return 0;
    }
}

sub cmp {
    my $self = shift;
    my $another = shift;

    my $type = ref($another) or croak "$another is not an object";
    return ($self->code eq $another->code);
}


sub AUTOLOAD {
    my $self = shift;
    my $type = ref($self) or croak "$self is not an object";

    my $name = $AUTOLOAD;
    $name =~ s/.*://;   # strip fully-qualified portion

    if (grep(/^$name$/,
        qw(WMO product station time addendum region
           T1 T2 T1T2 TT A1 A2 A1A2 ii)
    )) {
        if (@_) {
            if ($name eq "WMO") {
                $self->import(@_);
            } else {
                croak "`$name' field in class $type is read-only"
            }
        } else {
            return $self->{$name};
        }
    } else {
        croak "Can't access `$name' field in class $type"
    }

}

1;
