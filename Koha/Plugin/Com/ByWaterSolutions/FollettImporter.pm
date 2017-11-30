package Koha::Plugin::Com::ByWaterSolutions::FollettImporter;

## It's good practive to use Modern::Perl
use Modern::Perl;

## Required for all plugins
use base qw(Koha::Plugins::Base);

## We will also need to include any Koha libraries we want to access
use MARC::Batch;
use MARC::Record;

## Here we set our plugin version
our $VERSION = "{VERSION};

## Here is our metadata, some keys are required, some are optional
our $metadata = {
    name   => 'Follett MARC Importer',
    author => 'Kyle M Hall',
    description =>
'This plugin adds the ability to convert Follett MARC records into Koha compatible MARC records.',
    date_authored   => '2014-10-20',
    date_updated    => '2014-10-20',
    minimum_version => undef,
    maximum_version => undef,
    version         => $VERSION,
};

## This is the minimum code required for a plugin's 'new' method
## More can be added, but none should be removed
sub new {
    my ( $class, $args ) = @_;

    ## We need to add our metadata here so our base class can access it
    $args->{'metadata'} = $metadata;
    $args->{'metadata'}->{'class'} = $class;

    ## Here, we call the 'new' method for our base class
    ## This runs some additional magic and checking
    ## and returns our actual $self
    my $self = $class->SUPER::new($args);

    return $self;
}

sub uninstall { return 1; }

## The existiance of a 'to_marc' subroutine means the plugin is capable
## of converting some type of file to MARC for use from the stage records
## for import tool
##
## This example takes a text file of the arbtrary format:
## First name:Middle initial:Last name:Year of birth:Title
## and converts each line to a very very basic MARC record
sub to_marc {
    my ( $self, $args ) = @_;

    my $data = $args->{data};
    open( my $DATA, '<', \$data );    # Mock a file handle

    my $batch = MARC::Batch->new( 'USMARC', $DATA );
    my $modified_batch = q{};

    while ( my $record = $batch->next() ) {
        my @field_852 = $record->field('852');

        foreach my $field_852 (@field_852) {
            my $field_952 = MARC::Field->new(
                952, $field_852->indicator(1), $field_852->indicator(2),
                'a' => $field_852->subfield('a'),
                'b' => $field_852->subfield('b'),
                'o' => $field_852->subfield('h') . q{ } . $field_852->subfield('i'),
                'g' => $field_852->subfield('9'),
                'v' => $field_852->subfield('9'),
                'p' => $field_852->subfield('p'),
            );

            $record->append_fields($field_952);
        }

        $record->delete_fields(@field_852);

        $modified_batch .= $record->as_usmarc() . "\x1D";
    }

    return $modified_batch;
}

1;
