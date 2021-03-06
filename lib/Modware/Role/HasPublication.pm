package Modware::Role::HasPublication;

# Other modules:
use Moose::Role;
use namespace::autoclean;

#module implementation

requires '_build_abstract','_build_title', '_build_year','_build_source';
requires '_build_status',  '_build_keywords_stack', '_build_id';

has 'abstract' => (
    is         => 'rw',
    isa        => 'Maybe[Str]',
    lazy_build => 1
);

has 'title' => (
    is         => 'rw',
    isa        => 'Maybe[Str]',
    lazy_build => 1
);

has 'year' => (
    is         => 'rw',
    isa        => 'Maybe[Str]',
    lazy_build => 1
);

has 'keywords_stack' => (
    is         => 'rw',
    isa        => 'ArrayRef',
    traits     => [qw/Array/],
    lazy_build => 1,
    handles    => {
        add_keyword => 'push',
        keywords    => 'elements', 
        keywords_sorted => 'sort'
    }
);

has 'source' => (
    is         => 'rw',
    isa        => 'Maybe[Str]',
    lazy_build => 1
);

has 'status' => (
    is         => 'rw',
    isa        => 'Maybe[Str]',
    lazy_build => 1
);

has 'type' => (
    is      => 'rw',
    isa     => 'Str',
    lazy    => 1,
    default => 'paper'
);

has 'id' => (
	isa => 'Maybe[Int]|Maybe[Str]', 
	is => 'rw', 
	lazy_build => 1
);


1;    # Magic true value required at end of module

__END__

=head1 NAME

<Modware::Role::Publication> - [Moose role for publication module]


=head1 VERSION

This document describes B<Modware::Role::Publication> version 0.1.0


=head1 SYNOPSIS

use Moose;
with Modware::Role::Publication;


=head1 DESCRIPTION

The role in intended to be consumed by B<Modware::Publication> class. 

=head1 INTERFACE 

=for author to fill in:
Only role specific but non-public internal methods will be documented here, meant for API
developer.

=head1 DIAGNOSTICS

=for author to fill in:
List every single error and warning message that the module can
generate (even the ones that will "never happen"), with a full
explanation of each problem, one or more likely causes, and any
suggested remedies.


=head1 CONFIGURATION AND ENVIRONMENT

=for author to fill in:
A full explanation of any configuration system(s) used by the
module, including the names and locations of any configuration
files, and the meaning of any environment variables or properties
that can be set. These descriptions must also include details of any
configuration language used.


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



