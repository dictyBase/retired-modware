package Test::Chado;

use version; our $VERSION = qv('1.0.0');

# Other modules:
use Moose;
use Carp;
use YAML qw/LoadFile/;
use FindBin qw/$Bin/;
use File::Spec::Functions;
use Test::Chado::Handler;
use Test::Chado::Config::Database;
use Test::Chado::Config::Fixture;
use namespace::autoclean;

# Module implementation
#
with 'Test::Chado::Role::Config';

has 'fixture' => (
    is        => 'rw',
    isa       => 'Str',
    predicate => 'has_fixture'
);

has 'handler' => (
    is         => 'rw',
    isa        => 'Test::Chado::Handler',
    lazy_build => 1
);

before '_build_handler' => sub {
	my $self = shift;
	confess "fixture config file is not set\n" if !$self->has_fixture;
};

sub _build_handler {
    my ($self) = @_;
    my $fixture_conf
        = Test::Chado::Config::Fixture->new( base_path => $self->base_path );
    $fixture_conf->config( $self->fixture );
    my $handler = Test::Chado::Handler->new( fixture => $fixture_conf );
    $handler;
}

sub handlers_from_profile {
    my ($self) = @_;
    my @handlers;
    for my $name ( $self->sections ) {
        push @handlers, $self->_build_from_config($name);
    }
    @handlers;
}

sub handler_from_profile {
    my ( $self, $name ) = @_;
    if ( !$name ) {
        return $self->default_handler;
    }
    $self->_build_from_profile($name);
}

has 'default_handler' => (
    is      => 'ro',
    isa     => 'Test::Chado::Handler',
    lazy    => 1,
    builder => '_build_from_profile'
);

before '_build_from_profile' => sub {
    my $self = shift;
    for my $conf (qw/config fixture/) {
        my $method = 'has_' . $conf;
        if ( !$self->$method ) {
            confess "config file location is not set\n";
        }
    }
};

sub _build_from_profile {
    my ( $self, $name ) = @_;
    $name ||= 'fallback';

#There could be multiple databases configured in the default configuration file
#so we load the yaml file first and then later pass the each section to the database
#configuration handling class.
    my $db_str = $self->config;
    my $db_conf
        = Test::Chado::Config::Database->new( base_path => $self->base_path );
    $db_conf->config( $db_str->{$name} );

    #Here we directly pass the yaml configuration file to the class
    my $fixture_conf
        = Test::Chado::Config::Fixture->new( base_path => $self->base_path );
    $fixture_conf->config( $self->fixture );

    my $handler = Test::Chado::Handler->new(
        name    => $name,
        section => $db_conf,
        fixture => $fixture_conf,
        loader  => $db_str->{$name}->{loader}
    );
    $handler;
}


1;    # Magic true value required at end of module

__END__

=head1 NAME

B<Test::Chado> - [Module for handling test chado databases]


=head1 VERSION

This document describes B<Test::Chado> version 0.1


=head1 SYNOPSIS

use Test::Chado;

 my $handler = Test::Chado->new->default_handler; #default handler for test Sqlite database

 my $dbh = $handler->dbh; #DBI connection object
 $handler->create_db;
 $handler->deploy_schema;
 $handler->load_fixture;

 .... run your tests,  then

 $handler->purge_fixture;
 $handler->drop_schema;
 $handler->drop_db;



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

<Test::Chado> requires no configuration files or environment variables.


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



