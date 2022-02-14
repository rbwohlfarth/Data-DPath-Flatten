use strict;
use warnings;

use Data::DPath qw/dpath/;
use List::AllUtils qw/pairs pairmap/;
use Test::More;


BEGIN { use_ok( 'Data::DPath::Flatten', qw/flatten/ ); }

my $got1 = flatten( {A => 1} );
my $got2 = flatten( {A => 1}, undef );
is_deeply( $got2, $got1, 'undef same as no aliases' );

sub compare {
	my ($test, $data, $expected, $aliases) = @_;

	subtest $test => sub {
		my $got = flatten( $data, $aliases );
		
		sort_pairs( $expected );
		sort_pairs( $got      );
		is_deeply( $got, $expected, 'Flattened' );

		unless (defined $aliases) {
			foreach my $pair (pairs @$got) {
				my ($path, $value) = @$pair;
	
				my @actual = dpath( $path )->match( $data );
				is( $actual[0], $value, 'Valid path' );
				is( scalar( @actual ), 1, 'Path is unique' );
			}
		}
	};
}

compare( 'Hash reference',
	{
		A => 1,
		B => 2,
		C => {D => 3, E => 4},
		F => [5, 6],
		G => [{H => 7}, {I => 8}],
		J => {K => [9, {L => 10}]},
	}, [
		'/A'          => 1,
		'/B'          => 2,
		'/C/D'        => 3,
		'/C/E'        => 4,
		'/F/*[0]'     => 5,
		'/F/*[1]'     => 6,
		'/G/*[0]/H'   => 7,
		'/G/*[1]/I'   => 8,
		'/J/K/*[0]'   => 9,
		'/J/K/*[1]/L' => 10,
	]
);
compare( 'Array reference',
	[
		1,
		{A => 2},
		{B => {C => 3, D => 4}},
		[5, 6],
		[{E => 7}, {F => 8}],
		{G => [9, {H => 10}]},
	], [
		'/*[0]'          => 1,
		'/*[1]/A'        => 2,
		'/*[2]/B/C'      => 3,
		'/*[2]/B/D'      => 4,
		'/*[3]/*[0]'     => 5,
		'/*[3]/*[1]'     => 6,
		'/*[4]/*[0]/E'   => 7,
		'/*[4]/*[1]/F'   => 8,
		'/*[5]/G/*[0]'   => 9,
		'/*[5]/G/*[1]/H' => 10,
	]
);
compare( 'With alias array',
	{
		A => 1,
		B => 2,
		C => {D => 3, E => 4},
		F => [5, 6],
		G => [{H => 7}, {I => 8}],
		J => {K => [9, {L => 10}]},
	}, [
		'/A'          => 1,
		'/B'          => 2,
		'/C/D'        => 3,
		'/C/E'        => 4,
		'/F/*[0]'     => 5,
		'/F/*[1]'     => 6,
		'/G/*[0]/H'   => 7,
		'/G/*[1]/I'   => 8,
		'/J/K/*[0]'   => 9,
		'/J/K/*[1]/L' => 10,
		One           => 2,
		Two           => 8,
		Three         => undef,
	], [
		One   => '/B',
		Two   => '/G/*[1]/I',
		Three => '/Z',
	]
);
compare( 'With alias hash',
	{
		A => 1,
		B => 2,
		C => {D => 3, E => 4},
		F => [5, 6],
		G => [{H => 7}, {I => 8}],
		J => {K => [9, {L => 10}]},
	}, [
		'/A'          => 1,
		'/B'          => 2,
		'/C/D'        => 3,
		'/C/E'        => 4,
		'/F/*[0]'     => 5,
		'/F/*[1]'     => 6,
		'/G/*[0]/H'   => 7,
		'/G/*[1]/I'   => 8,
		'/J/K/*[0]'   => 9,
		'/J/K/*[1]/L' => 10,
		One           => 2,
		Two           => 8,
		Three         => undef,
	], {
		One   => '/B',
		Two   => '/G/*[1]/I',
		Three => '/Z',
	}
);
compare( 'Aliases with same name',
	{
		A => 1,
		B => 2,
		C => {D => 3, E => 4},
		F => [5, 6],
		G => [{H => 7}, {I => 8}],
		J => {K => [9, {L => 10}]},
	}, [
		'/A'          => 1,
		'/B'          => 2,
		'/C/D'        => 3,
		'/C/E'        => 4,
		'/F/*[0]'     => 5,
		'/F/*[1]'     => 6,
		'/G/*[0]/H'   => 7,
		'/G/*[1]/I'   => 8,
		'/J/K/*[0]'   => 9,
		'/J/K/*[1]/L' => 10,
		One           => 1,
		One           => 2,
		Two           => 8,
	], [
		One => '/A',
		One => '/B',
		Two => '/G/*[1]/I',
	]
);
compare( 'Aliases overwrites field',
	{
		A => 1,
		B => 2,
		C => {D => 3, E => 4},
		F => [5, 6],
		G => [{H => 7}, {I => 8}],
		J => {K => [9, {L => 10}]},
	}, [
		'/A'          => 1,
		'/A'          => 3,
		'/B'          => 2,
		'/C/D'        => 3,
		'/C/E'        => 4,
		'/F/*[0]'     => 5,
		'/F/*[1]'     => 6,
		'/G/*[0]/H'   => 7,
		'/G/*[1]/I'   => 8,
		'/J/K/*[0]'   => 9,
		'/J/K/*[1]/L' => 10,
	], ['/A' => '/C/D']
);

subtest 'Infinite loop' => sub {
	my (@a, @b);
	@a = (1, \@b);
	@b = (2, \@a);
	compare( 'Array', \@a, [
		'/*[0]'      => 1,
		'/*[1]/*[0]' => 2,
	] );

	my (%a, %b);
	%a = (A => 1, B => \%b);
	%b = (C => 2, D => \%a);
	compare( 'Hash', \%a, [
		'/A'   => 1,
		'/B/C' => 2,
	] );
};

done_testing();


sub sort_pairs {
	my $list = shift;
	
	my @work = pairmap { [$a, $b] } @$list;
	@work = sort {
		$a->[0] cmp $b->[0]
		|| $a->[1] cmp $b->[1]
	} @work;
	@$list = map { ($_->[0], $_->[1]) } @work;
}
