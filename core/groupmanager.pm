package core::groupmanager;

use strict;
use DBI;

# Will contain the code to manage groups
#   there will also be functions to allow plugins to inject user/group properties (for example to use the twitch api)

my $database = DBI->connect("dbi:SQLite:dbname=groupmanagement.db","","")
	or die $DBI::errstr;

sub getUserGroups
{
	my ($username) = @_;
	my $stmt = qq(SELECT DISTINCT groups.name from users LEFT JOIN usergroups LEFT JOIN groups where users.name="$username");
	my $sth = $database->prepare( $stmt);
	my $rv = $sth->execute() or die $DBI::errstr;
	my @result;
	
	while(my @row = $sth->fetchrow_array()) {
		push @result, $row[0];
	}
	return @result;
}
	my @groups = getUserGroups("casplantje");
	print "Casplantje's groups:\n";
	foreach my $group (@groups)
	{
			print "$group\n";
	}

1;
