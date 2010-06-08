package Test::Chado::Handler;

use version; our $VERSION = qv('1.0.0');

# Other modules:
use Moose;
use Moose::Util qw/apply_all_roles/;
use Moose::Util::TypeConstraints;
use Path::Class::File;
use DBI;
use Try::Tiny;
use Carp;
use FindBin qw/$Bin/;
use File::Spec::Functions;

# Module implementation
#
with 'MooseX::LogDispatch::Levels';

has 'name' => ( is => 'rw', isa => 'Str' );
has 'loader' => ( is => 'rw', isa => 'Str', default => 'bcs' );
has 'section' => (
    is        => 'rw',
    isa       => 'Test::Chado::Config::Database',
    predicate => 'has_section',
    trigger   => \&_setup_values
);

sub _setup_values {
    my ( $self, $obj ) = @_;
    for my $param (qw/dsn user password ddl/) {
        $self->$param( $obj->get_value($param) ) if $obj->has_value($param);
    }
    my $superuser
        = $obj->has_value('superuser') ? $obj->get_value('superuser')
        : $obj->has_value('user')      ? $obj->get_value('user')
        :                                undef;
    return if !$superuser;
    $self->superuser($superuser);
    $self->superpass(
          $obj->has_value('superpass')
        ? $obj->get_value('superpass')
        : $obj->get_value('password')
    );

}

has 'fixture' => (
    is        => 'rw',
    isa       => 'Test::Chado::Config::Fixture',
    predicate => 'has_fixture',
);

for my $attr (qw/dsn driver user password superuser superpass driver_dsn database/) {
    has $attr => 
    		( is => 'rw', isa => 'Str',  predicate => 'has_'.$attr );
}

after 'user' => sub {
	my ($self,  $user) = @_;
	if (!$self->has_superuser) {
		$self->superuser($user);
	}
};

after 'password' => sub {
	my ($self,  $pass) = @_;
	if (!$self->has_superpass) {
		$self->superpass($pass);
	}
};

after 'dsn' => sub {
    my ( $self, $value ) = @_;
    return if !$value;
    my ( $scheme, $driver, $attr_string, $attr_hash, $driver_dsn )
        = DBI->parse_dsn($value)
        or confess "cannot parse dsn:$DBI::errstr\n";
    $self->driver($driver);
    $self->driver_dsn($driver_dsn);
    apply_all_roles($self,  'Test::Chado::Role::Loader::'. uc $self->loader );
};

after 'driver' => sub {
    my ( $self, $driver ) = @_;
    return if !$driver;
    $driver = lc $driver;
    apply_all_roles( $self,
        'Test::Chado::Role::Handler::' . ucfirst $driver);
};

subtype 'FileClass' => as 'Object' => where { $_->isa('Path::Class::File') };
coerce 'FileClass' => from 'Str' =>
    via { Path::Class::File->new($_)->absolute };

has 'ddl' => (
    is      => 'rw',
    isa     => 'FileClass',
    lazy => 1, 
    default => sub {
        my ($self) = @_;
        Path::Class::File->new(
        	catfile( $Bin, 't', 'data', 'ddl', 'chado.' . lc $self->driver ));
    }
);

has 'attr_hash' => (
    is      => 'rw',
    isa     => 'HashRef',
    traits => ['Hash'], 
    default => sub { { AutoCommit => 0 } }, 
    handles => {
    	add_dbh_attribute => 'set'
    }
);


no Moose;

1;    # Magic true value required at end of module

__END__

=head1 NAME

<MODULE NAME> - [One line description of module's purpose here]


=head1 VERSION

This document describes <MODULE NAME> version 0.0.1


=head1 SYNOPSIS

use <MODULE NAME>;

=for author to fill in:
Brief code example(s) here showing commonest usage(s).
This section will be as far as many users bother reading
so make it as educational and exeplary as possible.


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



