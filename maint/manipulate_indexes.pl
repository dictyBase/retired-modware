#!/usr/bin/perl -w

use strict;
use local::lib '~/dictyBase/Libs/modern-perl';
use YAML qw/LoadFile/;
use Pod::Usage;
use Getopt::Long;
use DBI;
use Log::Log4perl qw/:easy/;
use Log::Log4perl::Appender;
use Log::Log4perl::Layout::SimpleLayout;

my ( $dsn, $user, $pass );
my $verbose;
my $config;
my $action = 'deactivate';

GetOptions(
    'h|help'     => sub { pod2usage(1); },
    'dsn=s'      => \$dsn,
    'u|user=s'   => \$user,
    'p|pass=s'   => \$pass,
    'c|config:s' => \$config,
    'v|verbose'  => \$verbose,
    'a|action:s'   => \$action,
) or exit(1);

if ($config) {
    my $str = LoadFile($config);
    $action = $str->{trigger} || $action;
    my $db = $str->{database};
    if ($db) {
        $dsn  = $db->{dsn}      || $dsn;
        $user = $db->{user}     || $user;
        $pass = $db->{password} || $pass;
    }
}

pod2usage "no dsn is given" if !$dsn;

my $logger = setup_logger() if $verbose;
$action = 'unusable' if $action eq 'deactivate';
$action = 'rebuild' if $action eq 'activate';


my $dbh = DBI->connect(
    $dsn, $user, $pass,
    {   AutoCommit => 0,
        RaiseError => 1
    }
) or die DBI::errstr;


eval { $dbh->do(qq {alter session set skip_unusable_indexes = true }) };
if ($@) {
    $dbh->rollback;
    $logger->logdie($@) if $verbose;
}
$dbh->commit;

my $sith = $dbh->prepare(
    qq { select index_name,table_name FROM user_indexes where generated =
    'N'}
);
$sith->execute;

INDEX:
while ( my ( $index, $table ) = $sith->fetchrow_array() ) {
    if ( $action eq 'list' ) {
        print "$index\t$table\n";
        next INDEX;
    }
    eval { $dbh->do(qq { alter index $index $action }) };
    if ($@) {
        $dbh->rollback();
        $logger->warn($@) if $verbose;
        next INDEX;
    }
    $dbh->commit();
    $logger->info("index $index is $action");
}

$dbh->disconnect;

sub setup_logger {
    my $appender
        = Log::Log4perl::Appender->new(
        'Log::Log4perl::Appender::ScreenColoredLevels',
        stderr => 1 );

    my $layout = Log::Log4perl::Layout::SimpleLayout->new();

    my $log = Log::Log4perl->get_logger();
    $appender->layout($layout);
    $log->add_appender($appender);
    $log->level($DEBUG);
    $log;
}

=head1 NAME

B<Application name> - [One line description of application purpose]


=head1 SYNOPSIS

=for author to fill in:
Brief code example(s) here showing commonest usage(s).
This section will be as far as many users bother reading
so make it as educational and exeplary as possible.


=head1 REQUIRED ARGUMENTS

=for author to fill in:
A complete list of every argument that must appear on the command line.
when the application  is invoked, explaining what each of them does, any
restrictions on where each one may appear (i.e., flags that must appear
		before or after filenames), and how the various arguments and options
may interact (e.g., mutual exclusions, required combinations, etc.)
	If all of the application's arguments are optional, this section
	may be omitted entirely.


	=head1 OPTIONS

	B<[-h|-help]> - display this documentation.

	=for author to fill in:
	A complete list of every available option with which the application
	can be invoked, explaining what each does, and listing any restrictions,
	or interactions.
	If the application has no options, this section may be omitted entirely.


	=head1 DESCRIPTION

	=for author to fill in:
	Write a full description of the module and its features here.
	Use subsections (=head2, =head3) as appropriate.


	=head1 DIAGNOSTICS

	=head1 CONFIGURATION AND ENVIRONMENT

	=head1 DEPENDENCIES

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

	B<Siddhartha Basu>


	=head1 AUTHOR

	I<Siddhartha Basu>  B<siddhartha-basu@northwestern.edu>

	=head1 LICENCE AND COPYRIGHT

	Copyright (c) B<2010>, Siddhartha Basu C<<siddhartha-basu@northwestern.edu>>. All rights reserved.

	This module is free software; you can redistribute it and/or
	modify it under the same terms as Perl itself. See L<perlartistic>.



