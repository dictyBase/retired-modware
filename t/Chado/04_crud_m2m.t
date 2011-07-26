use Test::Exception;
use aliased 'Modware::DataSource::Chado';
use Modware::Build;
use Test::More qw/no_plan/;
use Digest::MD5 qw/md5/;

my $build = Modware::Build->current;
Chado->connect( $build->connect_hash );

my $image;
use_ok('TestExpression');
subtest 'Test::Modware::Chado::Expression' => sub {
    lives_ok {
	$image = Test::Modware::Chado::Expression::Image->create(
                type => 'png',
                uri  => 'http://png.com',
                data => 'png_image_data'
            );
    }
    'creates a new instance';

    lives_ok {
        $image->expressions(
            Test::Modware::Chado::Expression->new(
            checksum   => md5('exp20'),
            name       => 'exp20',
            uniquename => 'exp20'
        );
    }
    'saved one expression';

    lives_ok {
        $image->expressions(
            Test::Modware::Chado::Expression->new(
            	checksum => md5('exp13')
                name  => 'exp13',
                uniquename  => 'exp13',
            )
        );
    }
    'saved another expression';


    is( $image->expressions->size, 2,
        'has two expressions through has_many associations' );
    is( $image->image_expressions->size, 2,
        'has two image expressions through has_many assoications' );
    isa_ok($_,  'Test::Modware::Chado::ExpressionImage') for $image->image_expressions;
    isa_ok($_,  'Test::Modware::Chado::Expression') for $image->expressions;
};

subtest 'Test::Modware::Chado::Expression::Image returns iterator in scalar context' => sub {
    my $itr = $image->expressions;
    isa_ok( $itr, 'Modware::Chado::BCS::Relation::Many2Many' );
    while ( my $row = $itr->next ) {
        isa_ok( $row, 'Test::Modware::Chado::Expression' );
        like($row->uniquename,  qr/^exp/,  'matches the name');
    }
};

subtest 'Test::Modware::Chado::Expression' => sub {
    my $image;
    lives_ok {
        $image = $expression->images->add_new(
            type => 'gif',
            uri  => 'http://gif.com',
            data => 'gif data'
        );
    }
    'adds a new image';
    isa_ok( $image, 'Test::Modware::Chado::Expression::Image' );
    is( $image->new_record, 1, 'image is not yet saved in the database' );
    lives_ok { $expression->save } 'is saved with the new image';
    is( $expression->images->size, 3, 'image is saved in the database' );
};

subtest 'Test::Modware::Chado::Expression' => sub {
    my $image2;
    lives_ok {
        $image2 = $expression->images->create(
            type => 'gif45',
            uri  => 'http://gif45.com',
            data => 'gif45 data'
        );
    }
    'creates a new image';
    isa_ok( $image2, 'Test::Modware::Chado::Expression::Image' );
    isnt( $image2->new_record, 1, 'image is saved in the database' );
    is( $expression->images->size, 4, 'has 4 images saved in the database' );
};
