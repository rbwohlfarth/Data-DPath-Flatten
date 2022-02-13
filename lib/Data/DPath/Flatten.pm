=head1 NAME

Data::DPath::Flatten - Convert complex data structure into key/value pairs

=head1 SYNOPSIS

  use Data::DPath::Flatten qw/flatten/;
  
  # Data can be arrays or hashes.
  my $hash = flatten( \@record );
  my $hash = flatten( \%record );
  
  # Aliases add more human readable field names.
  my $hash = flatten( \@record, A => '/*[0]', B => '/*[1]' );
  my $hash = flatten( \%record, {A => '/*[0]', B => '/*[1]'} );

=head1 DESCRIPTION

B<Data::DPath::Flatten> transforms an arbitrary data structure into a hash of
key/value pairs. 

Why? L<ETL::Pipeline::Input> returns arbitrary data structures. For example, 
Excel files return an array but XML files a hash. B<Data::DPath::Flatten> 
converts both of these into a standardized structure. I can query these records 
later based on the XML tags or column headers from Excel.

Use B<Data::DPath::Flatten> where you need key/value pairs from arbitrary data.
The module traverses nested data structures of any depth and converts into a 
single dimension hash.

=cut

package Data::DPath::Flatten;

use 5.14.0;
use Carp;
use Data::DPath qw/dpath/;
use Exporter qw/import/;
use List::AllUtils qw/pairs/;


our @EXPORT = (qw/flatten/);
our $VERSION = '1.00';


=head1 FUNCTIONS

=head3 flatten( $data[, @aliases] )

B<flatten> takes an arbitrary data structure and converts into a one level array
reference. Essentially, it flattens out nested data structures.

B<flatten> returns an array reference that can be processed as pairs. The first
element in each pair is either an alias name or L<Data::DPath> path into the 
original record. The second element is the value from the record.

The first parameter - C<$data> - is required. This is a reference to the input
data structure.

  # Recursively traverse arrays and hashes. 
  my $hash = flatten( \@fields );
  my $hash = flatten( \%record );
  
  # Scalars work, but it's kind of pointless. These come out the same.
  my $hash = flatten( $single );
  my $hash = flatten( \$single );

C<@aliases> are optional. This is an array, array reference, hash, or hash 
reference of field names and L<Data::DPath> paths. B<flatten> retrieves the 
values at each path and saves them with the field name. If a path returns more
than one value, B<flatten> adds each value to the output with the same name. 

  # In addition to all the DPaths, these also add keys for "One" and "Two".
  my $list = flatten( \@record, One => '/*[0]', Two => '/*[1]' );
  
  # A hash reference of aliases works the same.
  my $list = flatten( \@record, {One => '/*[0]', Two => '/*[1]'} );

  # A list of aliases can repeat names. There will be two "One" entries in
  # the output.
  my $list = flatten( \@record, One => '/*[0]', One => '/*[1]' );

=head4 References

When B<flatten> encounters a HASH or ARRAY reference, it recursively traverses
the nested structure.

SCALAR references are dereferenced and the value stored.

All other references and objects are stored as references.

=head4 Array vs. Hash

Why an array instead of a hash? This allows aliases to resolve to more than one
value. If you use file headers as aliases, there is a good chance of collisions.
Using an array allows B<flatten> to associate the same alias name with more than
one data value.

This also prevents an alias from overwriting a value from the original record.
They are both returned.
 
=cut

sub flatten {
	my $data = shift;
	
	# Flatten the original data into a one level hash. Make sure I get a new
	# reference for every call.
	my $new = [];
	_step( $data, $new, '' );

	# Add aliases. Data from files might have column headers. This way I can
	# look up data by it's path or column name.
	my @aliases;
	if (scalar( @_ ) == 1) {
		my $options = $_[0];
		if (defined $options) {
			if    (ref( $options ) eq 'ARRAY') { @aliases = @$options; }
			elsif (ref( $options ) eq 'HASH' ) { @aliases = %$options; }
			else { carp 'Aliases must be either an ARRAY reference or a HASH reference'; }
		}
	} elsif (scalar( @_ ) % 2) { carp 'Aliases ARRAY must have an even number of items'; }
	else { @aliases = @_; }

	foreach my $pair (pairs @aliases) {
		my ($key, $value) = @$pair;
		my @found = dpath( $value )->match( $data );

		if (scalar( @found ) == 0) { push @$new, $key, undef; } 
		else { push( @$new, $key, $_ ) foreach (@found); }
	}

	# Return the flattened hash reference.	
	return $new;
}


#-------------------------------------------------------------------------------
# Internal subroutines.

# Recursively traverse the data structure, building the path string as it goes.
# The initial path is an empty string. This code adds the leading "/".
sub _step {
	my ($from, $to, $path) = @_;

	if (!defined( $from )) { 
		# No op!
	} elsif (ref( $from ) eq '') { 
		if ($path eq '') { push @$to, '/'  , $from; }
		else             { push @$to, $path, $from; }
	} elsif (ref( $from) eq 'SCALAR') { 
		if ($path eq '') { push @$to, '/'  , $$from; }
		else             { push @$to, $path, $$from; }
	} elsif (ref( $from) eq 'HASH') {
		while (my ($key, $value) = each %$from) {
			$key = "\"$key\"" if m/\.\.|\*|::ancestor(-or-self)?|\/\/|\[|\]/;
			_step( $value, $to, "$path/$key" );
		}
	} elsif (ref( $from ) eq 'ARRAY') {
		while (my ($index, $value) = each @$from) {
			_step( $value, $to, "$path/*[$index]" );
		}
	} else {
		if ($path eq '') { push @$to, '/'  , $from; }
		else             { push @$to, $path, $from; }
	}
	return;
}


=head1 SEE ALSO

L<Data::DPath>

=head1 REPOSITORY

L<https://github.com/rbwohlfarth/Data-DPath-Flatten>

=head1 AUTHOR

Robert Wohlfarth <robert.j.wohlfarth@vumc.org>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2021  Robert Wohlfarth

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl 5.10.0. For more details, see the full text
of the licenses in the directory LICENSES.

This program is distributed in the hope that it will be useful, but
without any warranty; without even the implied

=cut

# Required by Perl to load the module.
1;
