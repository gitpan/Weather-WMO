package Weather::WMO;
require 5.004;
require Exporter;

=head1 NAME

Weather::WMO - routines for parsing WMO abbreviated header lines

=head1 DESCRIPTION

Weather::WMO is a module for parsing WMO abbreviated header lines
in World Meterological Organization-formatted weather products.

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

=head1 METHODS

=cut

=pod

=head2 PRODUCT

An exported text constant. C<PRODUCT = 'PRODUCT'>.

=cut

use constant PRODUCT => 'PRODUCT';

@ISA = qw(Exporter);
@EXPORT = qw(PRODUCT);

use vars qw($VERSION $AUTOLOAD);
$VERSION = "1.1.3";

use Carp;

=pod

=head2 new

The object constructor:

    $obj = new Weather::WMO SCALAR

where C<SCALAR> is the WMO header (without any trailing spaces, newlines or
carriage returns).

An alternative constructor may be used:

    $obj = new Weather::WMO LIST

where C<LIST> contains the individual parts of the WMO header (see the L<examples|"EXAMPLE"> above).

=cut

sub new {
    my $this = shift;
    my $class = ref($this) || $this;
    my $self = {};
    bless $self, $class;
    $self->initialize();
    $self->import(@_);
    return $self;
}

sub initialize {
    my $self = shift;
    $self->{WMO} = undef;
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
            $addendum =~ s/\(?((AA|CC|CO|RR|P[A-X])[A-X])\)?/$1/;
        } else {
            ($product, $station, $time, $addendum)=@_;
            $WMO = join " ", $product, $station, $time;
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
    $self->{BBB} = $addendum;
}

=pod

=head2 valid

    Weather::WMO::valid SCALAR

Returns C<true> if the header specified in C<SCALAR> looks like a valid WMO
header line. Otherwise C<false>.

=cut

sub valid {
    my $arg = shift;
    if ($arg =~ m/^[A-Z]{4}\d{1,2} [A-Z]{3,4} \d{4,6}( \(?((AA|CC|RR|P[A-X])[A-X]|COR)\)?)?$/) {
        return 1;
    } else {
        return 0;
    }
}

=pod

=head2 cmp

Compares two WMO objects.

    $obj1->cmp $obj2

Returns C<true> if C<obj2> is the same I<L<"product">> as C<obj1>.

=cut

sub cmp {
    my $self = shift;
    my $another = shift;

    my $type = ref($another) or croak "$another is not an object";
    return ($self->product eq $another->product);
}

=pod

=head2 WMO

When called without arguments it returns the WMO header as a string.

When called with arguments, it assigns a value to the WMO header
(if none has already been assigned).

=head2 product

Returns the "product" portion (C<T1T2A1A2ii>) of the WMO header.

=head2 station

Returns the "station" portion of the WMO header.

=head2 time

Returns the timestamp of the WMO header, in WMO format (C<DDHHMM> where
C<DD> is the day of the month and C<HHMM> is the time, in UGC).

This time can be converted to a Perl-friendly format using the
I<Weather::Product::int_time> function.

=head2 addendum

Returns the "addendum" (or C<BBB>) portion of the WMO header.

=head2 region

Returns the geographical region code of the weather product, if applicable.
Otherwise it returns C<undef>.

=cut

sub AUTOLOAD {
    my $self = shift;
    my $type = ref($self) or croak "$self is not an object";

    my $name = $AUTOLOAD;
    $name =~ s/.*://;   # strip fully-qualified portion

    if (grep(/^$name$/,
        qw(WMO product station time addendum region
           T1 T2 T1T2 TT A1 A2 A1A2 ii BBB)
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

__END__

=pod

=head2 T1, T2, T1T2, TT, A1, A2, A1A2, ii, BBB

Returns the equivalent portion of the WMO header.

=head1 KNOWN BUGS

This module only performs simple string validation and parsing of WMO header
lines.  It does not check if the product or station is actually valid, or
if the timestamp is valid.

"Non-standard" header lines used by a specific weather service may not be
handled properly.

=head1 SEE ALSO

F<Weather::Product> and F<Weather::Product::NWS>, which make use of this
module.

For more information about what WMO heading lines are, see
http://www.nws.noaa.gov/oso/head.shtml

=head1 DISCLAIMER

I am not a meteorologist nor am I associated with any weather service.
This module grew out of a hack which would fetch weather reports every
morning and send them to my pager. So I said to myself "Why not do this
the I<right> way..." and spent a bit of time surfing around the web
looking for documentation about this stuff....

=head1 AUTHOR

Robert Rothenberg <wlkngowl@unix.asb.com>

=cut
