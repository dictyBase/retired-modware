package Modware::Collection::Iterator::BCS::ResultSet;

# Other modules:

use namespace::autoclean;
use Moose;
use Class::MOP;
use MooseX::Params::Validate;
use Carp;
use Regexp::Common qw/whitespace/;

# Module implementation
#

has 'collection' => (
    is        => 'rw',
    isa       => 'DBIx::Class::ResultSet',
    predicate => 'has_collection'
);

has 'count' => (
    is      => 'ro',
    isa     => 'Int',
    lazy    => 1,
    default => sub {
        my $self = shift;
        $self->collection->count;
    }
);

before [qw/count order/] => sub {
    my $self = shift;
    confess "no collection is defined for counting\n"
        if !$self->has_collection;
};

has 'data_access_class' => (
    is        => 'rw',
    isa       => 'Str',
    predicate => 'has_data_access_class'
);

has 'search_class' => (
    is        => 'rw',
    isa       => 'Str',
    predicate => 'has_search_class'
);

before 'next' => sub {
    my $self = shift;
    confess "data access class name is not set\n"
        if !$self->has_data_access_class;
};

sub next {
    my ($self) = @_;
    if ( my $next = $self->collection->next ) {
        Class::MOP::load_class( $self->data_access_class );
        $self->data_access_class->new( dbrow => $next );
    }

}

sub slice {
    my ( $self, $start, $end ) = @_;
    my $rs = $self->collection->slice( $start, $end );
    return if $rs->count == 0;
    if ( wantarray() ) {
        Class::MOP::load_class( $self->data_access_class );
        return map { $self->data_access_class->new( dbrow => $_ ) } $rs->all;
    }
    my $class = $self->meta->name;
    return $class->new(
        collection        => $rs,
        data_access_class => $self->data_access_class,
        search_class      => $self->search_class
    );
}

sub order {
    my ( $self, $arg ) = @_;

    ## -- transform and validate if the column(s) for ordering are allowed
    my $options = $self->transform($arg);
    my $rs = $self->collection->search( {}, { order_by => $options } );

    if ( wantarray() ) {
        Class::MOP::load_class( $self->data_access_class );
        return map { $self->data_access_class->new( dbrow => $_ ) } $rs->all;
    }

    my $class = $self->meta->name;
    return $class->new(
        collection        => $rs,
        data_access_class => $self->data_access_class,
        search_class      => $self->search_class
    );
}

sub search {
    my ( $self, %arg ) = @_;
    $self->search_class->search(%arg);
}

sub transform {
    my ( $self, $arg ) = @_;
    my $search_class = $self->search_class;

    my $array;
    if ( $arg =~ /\,/ ) {
        my @cond = split /\,/, $arg;
        for my $c (@cond) {
            $c =~ s/$RE{ws}{crop}//g;
            if ( $c =~ /^(\w+)\s+(\w+)$/ ) {
                croak "given column $1 in not included for ordering\n"
                    if !$search_class->has_param_value($1);
                push @$array, { '-' . lc $2 => $search_class->param2col($1) };
            }
            else {
                croak "given column $c in not included for ordering\n"
                    if !$search_class->has_param_value($c);
                push @$array, $search_class->param2col($c);
            }
        }
    }
    else {
        $arg =~ s/$RE{ws}{crop}//g;
        if ( $arg =~ /^(\w+)\s+(\w+)$/ ) {
            croak "given column $1 in not included for ordering\n"
                if !$search_class->has_param_value($1);
            push @$array, { '-' . lc $2 => $search_class->param2col($1) };
        }
        else {
            croak "given column $arg in not included for ordering\n"
                if !$search_class->has_param_value($arg);
            push @$array, $search_class->param2col($arg);
        }
    }
    return $array;
}

1;    # Magic true value required at end of module

__END__

=head1 NAME

B<Modware::Collection::Iterator::BCS::ResultSet> - [Generic iterator module for search
resultset using BCS]


=head1 SYNOPSIS

 use aliased 'Modware::Collection::Iterator::BCS::ResultSet';

 #get a BCS resultset somehow

 my $rs = ....

 my $itr = ResultSet->new(
        collection        => $rs,
        data_access_class => $class->data_class,
        search_class      => $class
  );



=head1 DESCRIPTION

=for author to fill in:
Write a full description of the module and its features here.
Use subsections (=head2, =head3) as appropriate.


=head1 INTERFACE 

=for author to fill in:
Write a separate section listing the public components of the modules
interface. These normally consist of either subroutines that may be
exported, or methods that may be called on objects belonging to the
classes provided by the module.

=head2 <METHOD NAME>

=over

=item B<Use:> <Usage>

[Detail text here]

=item B<Functions:> [What id does]

[Details if neccessary]

=item B<Return:> [Return type of value]

[Details]

=item B<Args:> [Arguments passed]

[Details]

=back

=head2 <METHOD NAME>

=over

=item B<Use:> <Usage>

[Detail text here]

=item B<Functions:> [What id does]

[Details if neccessary]

=item B<Return:> [Return type of value]

[Details]

=item B<Args:> [Arguments passed]

[Details]

=back


=head1 DIAGNOSTICS

=for author to fill in:
List every single error and warning message that the module can
generate (even the ones that will "never happen"), with a full
explanation of each problem, one or more likely causes, and any
suggested remedies.

=over

=item C<< Error message here, perhaps with %s placeholders >>

[Description of error here]

=item C<< Another error message here >>

[Description of error here]

[Et cetera, et cetera]

=back


=head1 CONFIGURATION AND ENVIRONMENT

=for author to fill in:
A full explanation of any configuration system(s) used by the
module, including the names and locations of any configuration
files, and the meaning of any environment variables or properties
that can be set. These descriptions must also include details of any
configuration language used.

<MODULE NAME> requires no configuration files or environment variables.


=head1 DEPENDENCIES

=for author to fill in:
A list of all the other modules that this module relies upon,
  including any restrictions on versions, and an indication whether
  the module is part of the standard Perl distribution, part of the
  module's distribution, or must be installed separately. ]

  None.


  =head1 INCOMPATIBILITIES

  =for author to fill in:
  A list of any modules that this module cannot be used in conjunction
  with. This may be due to name conflicts in the interface, or
  competition for system or program resources, or due to internal
  limitations of Perl (for example, many modules that use source code
		  filters are mutually incompatible).

  None reported.


  =head1 BUGS AND LIMITATIONS

  =for author to fill in:
  A list of known problems with the module, together with some
  indication Whether they are likely to be fixed in an upcoming
  release. Also a list of restrictions on the features the module
  does provide: data types that cannot be handled, performance issues
  and the circumstances in which they may arise, practical
  limitations on the size of data sets, special cases that are not
  (yet) handled, etc.

  No bugs have been reported.Please report any bugs or feature requests to
  dictybase@northwestern.edu



  =head1 TODO

  =over

  =item *

  [Write stuff here]

  =item *

  [Write stuff here]

  =back


  =head1 AUTHOR

  I<Siddhartha Basu>  B<siddhartha-basu@northwestern.edu>


  =head1 LICENCE AND COPYRIGHT

  Copyright (c) B<2003>, Siddhartha Basu C<<siddhartha-basu@northwestern.edu>>. All rights reserved.

  This module is free software; you can redistribute it and/or
  modify it under the same terms as Perl itself. See L<perlartistic>.


  =head1 DISCLAIMER OF WARRANTY

  BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
  FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
  OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
  PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
  EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
  ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
  YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
  NECESSARY SERVICING, REPAIR, OR CORRECTION.

  IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
  WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
  REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
  LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
  OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
  THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
		  RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
		  FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
  SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
  SUCH DAMAGES.



