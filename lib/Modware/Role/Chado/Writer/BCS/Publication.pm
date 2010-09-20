package Modware::Role::Chado::Writer::BCS::Publication;

# Other modules:
use Moose::Role;
use aliased 'Modware::DataSource::Chado';
use aliased 'Modware::Publication::Author';
use Try::Tiny;
use Carp;
use Data::Dumper::Concise;
use namespace::autoclean;

# Module implementation
#

has 'chado' => (
    is         => 'rw',
    isa        => 'Bio::Chado::Schema',
    lazy_build => 1
);

sub _build_chado {
    my ($self) = @_;
    my $chado
        = $self->has_source
        ? Chado->handler( $self->source )
        : Chado->handler;
    $self->meta->make_mutable;
    $self->meta->add_attribute(
        'pub' => (
            is     => 'ro',
            traits => [
                'Modware::Role::Chado::Helper::BCS::ResultSet' => {
                    resultset => $chado->resultset('Pub::Pub')->new( {} ),
                    relationships => [qw/pubprops pubauthors pub_dbxrefs/],
                }
            ]
        )
    );
    $self->meta->make_immutable;
    $chado;
}

sub create {
    my ($self) = @_;
    my $chado  = $self->chado;
    my $pub    = $self->meta->get_attribute('pub');
    my $dbrow  = $chado->txn_do(
        sub {
            my $value = $chado->resultset('Pub::Pub')
                ->create( $pub->to_insert_hashref );
            $value;
        }
    );
    $self->dbrow($dbrow);
    $dbrow;
}

sub delete {
    my ( $self, $cascade ) = @_;
    if ( !$cascade ) {
        try {
            $self->chado->txn_do(
                sub {
                    $self->chado->resultset('Pub::Pub')
                        ->search( { pub_id => $self->dbrow->pub_id } )
                        ->delete_all;
                }
            );
        }
        catch { confess "Unable to delete $_" };
    }
    else {
        try {
            $self->chado->txn_do(
                sub {
                    my $pub = $self->dbrow;
                    $pub->pubprops->delete_all;
                    $pub->pubauthors->delete_all;
                    $pub->pub_dbxrefs->delete_all;
                    $pub->pub_relationship_objects->delete_all;
                    $pub->pub_relationship_subjects->delete_all;
                    $self->dbrow->delete;
                }
            );
        }
        catch { confess "Unable to delete $_" };
    }
    $self->_clear_dbrow;
}

sub update {
    my ($self) = @_;
    my $chado  = $self->chado;
    my $dbrow  = $self->dbrow;
    my $pub    = $self->meta->get_attribute('pub');
    $chado->txn_do(
        sub {
            $dbrow->update( $pub->to_update_hashref )
                if defined $pub->to_update_hashref;
            $dbrow->update_or_create_related( 'pubauthors', $_ )
                for $pub->pubauthors_to_hashrefs;
            $dbrow->update_or_create_related( 'pubprops', $_ )
                for $pub->pubprops_to_hashrefs;

            # -- for M2M relationship
        PUBDBXREF:
            for my $hashref ( $pub->pub_dbxrefs_to_hashrefs ) {
                if ( defined $hashref->{dbxref_id} ) {
                    my $id = $hashref->{dbxref_id};
                    delete $hashref->{dbxref_id};
                    $dbrow->pub_dbxrefs( { dbxref_id => $id }, { rows => 1 } )
                        ->single->update_or_create_related( 'dbxref',
                        $hashref );
                    next PUBDBXREF;

                }
                $dbrow->create_related( 'pub_dbxrefs',
                    { dbxref => $hashref } );
            }

        }
    );
    $dbrow;
}

before 'create' => sub {
    my $self = shift;

    # -- Data validation
    croak "No author given\n" if !$self->has_authors;

    #initialize chado handler first
    $self->chado if !$self->has_chado;

    my $pub = $self->meta->get_attribute('pub');
    while ( my $pubauthor = $self->next_author ) {
        $pub->add_to_pubauthors(
            {   rank       => $pubauthor->rank,
                editor     => $pubauthor->is_editor,
                surname    => $pubauthor->last_name,
                givennames => $pubauthor->given_name,
                suffix     => $pubauthor->suffix
            }
        );
    }

    $pub->uniquename( 'PUB' . int( rand(9999999) ) ) if !$pub->has_uniquename;
    $pub->type_id( $self->cvterm_id_by_name( $self->type ) );
    $pub->title( $self->title )
        if $self->has_title;
    $pub->pyear( $self->year )      if $self->has_year;
    $pub->pubplace( $self->source ) if $self->has_source;

    $pub->add_to_pubprops(
        {   type_id => $self->cvterm_id_by_name('status'),
            value   => $self->status
        }
    );
    $pub->add_to_pubprops(
        {   type_id => $self->cvterm_id_by_name('abstract'),
            value   => $self->abstract
        }
    );

    if ( $self->has_keywords_stack ) {
        for my $word ( $self->keywords ) {
            $pub->add_to_pubprops(
                {   type_id => $self->cvterm_id_by_name($word),
                    value   => 'true'
                }
            );
        }
    }
};

before 'delete' => sub {
    my $self = shift;
    confess "No data being fetched from storage: nothing to delete\n"
        if !$self->has_dbrow;
};

before 'update' => sub {
    my $self = shift;
    confess "No data being fetched from storage: nothing to update\n"
        if !$self->has_dbrow;

    my $pub   = $self->meta->get_attribute('pub');
    my $dbrow = $self->dbrow;

    $pub->title( $self->title )
        if $self->has_title and $dbrow->title ne $self->title;
    $pub->pyear( $self->year )
        if $self->has_year and $dbrow->pyear ne $self->year;
    $pub->pubplace( $self->source )
        if $self->has_source
            and $dbrow->pubplace ne $self->has_source;
    $pub->type_id( $self->cvterm_id_by_name( $self->type ) )
        if $dbrow->type_id != $self->cvterm_id_by_name( $self->type );

 #Did not check for changes in the value as it is a blob field in the database
    $pub->add_to_pubprops(
        {   type_id => $self->cvterm_id_by_name('abstract'),
            value   => $self->abstract,
            rank    => 0
        }
    ) if $self->has_abstract;
    $pub->add_to_pubprops(
        {   type_id => $self->cvterm_id_by_name('status'),
            value   => $self->status,
            rank    => 0
        }
    ) if $self->has_status;

    if ( $self->has_keywords_stack ) {
    KEY:
        for my $key ( $self->keywords ) {
            $pub->add_to_pubprops(
                {   type_id => $self->cvterm_id_by_name( $key->{name} ),
                    value   => 'true',
                    rank    => 0
                }
            );
        }
    }
    if ( $self->has_authors ) {
    AUTHOR:
        while ( my $pubauthor = $self->next_author ) {
            $pub->add_to_pubauthors(
                {   rank       => $pubauthor->rank,
                    editor     => $pubauthor->is_editor,
                    surname    => $pubauthor->last_name,
                    givennames => $pubauthor->given_name,
                    suffix     => $pubauthor->suffix
                }
            );
        }
    }

};

1;    # Magic true value required at end of module

__END__

=head1 NAME

B<Modware::Role::Chado::Reader::BCS::Publication> - [Moose role for persisting publication data to 
chado database]


=head1 VERSION

This document describes <Modware::Role::Chado::Reader::BCS::Publication> version 0.1


=head1 SYNOPSIS

with Modware::Role::Chado::Reader::BCS::Publication;


=head1 DESCRIPTION

=for author to fill in:
Write a full description of the module and its features here.
Use subsections (=head2, =head3) as appropriate.


=head1 INTERFACE 

=head2 where

=over

=item B<Use:> $obj->where(%conditions)

=item B<Functions:> Returns either a list/iterator with the given conditions. By default,
the conditions are expected to be joined together with ' AND
                    ' clause. However,  it could be
changed using the I<clause> options.

=item B<Return:> Depending on the context either an array of B<Modware::Publication>
object or an iteartor.

=item B<Args:> The following parameters could be passed as key value pairs.

=over

=item id : Database primary key of the reference

=item first_name

=item last_name

=item pubmed_id

=item doi

=item medline_id

=item title

=item journal

=item issue

=item publisher

=item mesh_terms : List of words

=back

=head3 Modifiers for the conditions search

=over

=item clause: B<AND> or B<OR>,  default is AND

=item partial: If set to true(1),  all the conditions matches will be partial. 

=back

=back


=head2 count

=over

=item B<Use:> count(%conditions)

=item B<Functions:> Fetches number of records with the given conditions.

=item B<Return:> Integer

=item B<Args:> Identical to L<where> method.

=back


=head2 first

=over

=item B<Use:> first(%conditions)

=item B<Functions:> Returns the first matching publiction.

=item B<Return:> Modware::Publication object.

=item B<Args:> Identical to L<where> method.

=back


=head2 last

=over

=item B<Use:> last(%conditions)

=item B<Functions:> Returns the last matching publiction.

=item B<Return:> Modware::Publication object.

=item B<Args:> Identical to L<where> method.

=back


=head2 exclude

Inverse of B<where> method.

=head2 find

Alias to B<where> method.



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

B<Modware::Chado::Reader::BCS::Publication> requires no configuration files or environment variables.


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



