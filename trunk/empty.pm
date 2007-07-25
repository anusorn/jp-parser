package empty;
use strict;
use warnings;

sub new {
	my ($class, $name) = @_;
	my $self = {
		_name => undef,
	};
	$self->{_name} = $name if defined($name);
	bless($self, $class);
}

sub getname {
	my $self = shift;
	return $self->{_name};
}





sub print {
	my $self = shift;
	print "--------------------------------------------\n\n";
	print "Name: ".$self->{_name}."\n\n";
}


1;
