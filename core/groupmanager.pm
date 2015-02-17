package core::groupmanager;

use List::MoreUtils qw(zip);
use strict;
use DBI;

# Will contain the code to manage groups
#   there will also be functions to allow plugins to inject user/group properties (for example to use the twitch api)

my $database = DBI->connect("dbi:SQLite:dbname=groupmanagement.db","","")
	or die $DBI::errstr;

sub getUserGroups
{
	my ($username) = @_;
	my $stmt = qq(SELECT DISTINCT groups.name FROM users 
					INNER JOIN usergroups ON users.id = usergroups.userid 
					INNER JOIN groups ON groups.id = usergroups.groupid 
					WHERE users.name="$username");
	my $sth = $database->prepare( $stmt);
	my $rv = $sth->execute() or die $DBI::errstr;
	my @result;
	
	while(my @row = $sth->fetchrow_array()) {
		push @result, $row[0];
	}
	return @result;
}

sub getUserUserPrivileges
{
	my ($username) = @_;
	my $stmt = qq(SELECT DISTINCT privileges.name FROM users
					INNER JOIN userprivileges ON userprivileges.userid = users.id 
					INNER JOIN privileges ON userprivileges.privilegeid = privileges.id
					WHERE users.name="$username");
	my $sth = $database->prepare( $stmt);
	my $rv = $sth->execute() or die $DBI::errstr;
	my @result;
	
	while(my @row = $sth->fetchrow_array()) {
		push @result, $row[0];
	}
	return @result;
}

sub getUserGroupPrivileges
{
	my ($username) = @_;
	my $stmt = qq(SELECT DISTINCT privileges.name FROM users 
					INNER JOIN usergroups ON users.id = usergroups.userid 
					INNER JOIN groups ON groups.id = usergroups.groupid 
					INNER JOIN groupprivileges ON groups.id = groupprivileges.groupid 
					INNER JOIN privileges ON privileges.id = groupprivileges.privilegeid 
					WHERE users.name="$username");
	my $sth = $database->prepare( $stmt);
	my $rv = $sth->execute() or die $DBI::errstr;
	my @result;
	
	while(my @row = $sth->fetchrow_array()) {
		push @result, $row[0];
	}
	return @result;
}

sub getUserPrivileges
{
	my ($username) = @_;
	my @userPrivileges = getUserUserPrivileges($username);
	my @groupPrivileges = getUserGroupPrivileges($username);
	return zip(@userPrivileges, @groupPrivileges);
}


# test code
	my @groups = getUserPrivileges("casplantje");
	print "Casplantje's privileges:\n";
	foreach my $group (@groups)
	{
			print "$group\n";
	}

1;
