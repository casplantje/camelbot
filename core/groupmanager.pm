package core::groupmanager;

use List::MoreUtils qw(zip);
use strict;
use DBI;

# TODO: make all functions that use the db connection threadsafe

# Will contain the code to manage groups
#   there will also be functions to allow plugins to inject user/group properties (for example to use the twitch api)

# General error reporting function
# Camelbot should not die because of a single sql failure
#
# TODO: add some error diagnosis and solving code to sqlError
#		only die if no solution works
#		The function causing the error will have to return
#		but it will do so gracefully.
sub sqlError
{
	my ($errorMessage) = @_;
	print "$errorMessage\n";
}

my $database = DBI->connect("dbi:SQLite:dbname=groupmanagement.db","","")
	or sqlError $DBI::errstr and return ();

sub getUserGroups
{
	my ($username) = @_;
	my $stmt = qq(SELECT DISTINCT groups.name FROM users 
					INNER JOIN usergroups ON users.id = usergroups.userid 
					INNER JOIN groups ON groups.id = usergroups.groupid 
					WHERE users.name="$username");
	my $sth = $database->prepare($stmt);
	my $rv = $sth->execute() or sqlError $DBI::errstr and return ();
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
	my $sth = $database->prepare($stmt);
	my $rv = $sth->execute() or sqlError $DBI::errstr and return ();
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
	my $sth = $database->prepare($stmt);
	my $rv = $sth->execute() or sqlError $DBI::errstr and return ();
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

sub getGroupPrivileges
{
	my ($groupname) = @_;
	my $stmt = qq(SELECT DISTINCT privileges.name FROM groups
					INNER JOIN groupprivileges ON groups.id = groupprivileges.groupid 
					INNER JOIN privileges ON privileges.id = groupprivileges.privilegeid 
					WHERE groups.name="$groupname");
	my $sth = $database->prepare($stmt);
	my $rv = $sth->execute() or sqlError $DBI::errstr and return ();
	my @result;
	
	while(my @row = $sth->fetchrow_array()) {
		push @result, $row[0];
	}
	return @result;
}

sub listUsers
{
	my $stmt = qq(SELECT name FROM users);
	my $sth = $database->prepare($stmt);
	my $rv = $sth->execute() or sqlError $DBI::errstr and return ();
	my @result;
	
	while(my @row = $sth->fetchrow_array()) {
		push @result, $row[0];
	}
	return @result;	
}

sub listGroups
{
	my $stmt = qq(SELECT name FROM groups);
	my $sth = $database->prepare($stmt);
	my $rv = $sth->execute() or sqlError $DBI::errstr and return ();
	my @result;
	
	while(my @row = $sth->fetchrow_array()) {
		push @result, $row[0];
	}
	return @result;	
}

sub listPrivileges
{
	my $stmt = qq(SELECT name FROM privileges);
	my $sth = $database->prepare($stmt);
	my $rv = $sth->execute() or sqlError $DBI::errstr and return ();
	my @result;
	
	while(my @row = $sth->fetchrow_array()) {
		push @result, $row[0];
	}
	return @result;	
}

sub deleteUser
{
	my ($username) = @_;
	my $stmt = qq(DELETE FROM users WHERE name="$username";);
	my $rv = $database->do($stmt) or sqlError $DBI::errstr and return ();
	if( $rv < 0 ){
	   print $DBI::errstr;
	}
	
	return $rv;	
}

sub deleteGroup
{
	my ($groupname) = @_;
	my $stmt = qq(DELETE FROM groups WHERE name="$groupname";);
	my $rv = $database->do($stmt) or sqlError $DBI::errstr and return ();
	if( $rv < 0 ){
	   print $DBI::errstr;
	}
	
	return $rv;
}

sub deletePrivilege
{
	my ($privilegename) = @_;
	my $stmt = qq(DELETE FROM users WHERE name="$privilegename";);
	my $rv = $database->do($stmt) or sqlError $DBI::errstr and return ();
	if( $rv < 0 ){
	   print $DBI::errstr;
	}
	
	return $rv;	
}

sub addUser
{
	my ($username) = @_;
	my $stmt = qq(INSERT INTO users (name)
					SELECT "$username"
					WHERE NOT EXISTS (SELECT * FROM users WHERE name = "$username"));
	my $rv = $database->do($stmt) or sqlError $DBI::errstr and return -1;
	
	return 0;
}

sub addGroup
{
	my ($groupname) = @_;
	my $stmt = qq(INSERT INTO groups (name)
					SELECT "$groupname"
					WHERE NOT EXISTS (SELECT * FROM groups WHERE name = "$groupname"));
	my $rv = $database->do($stmt) or sqlError $DBI::errstr and return -1;
	
	return 0;
}

sub addPrivilege
{
	my ($privilegename) = @_;
	my $stmt = qq(INSERT INTO privileges (name)
					SELECT "$privilegename"
					WHERE NOT EXISTS (SELECT * FROM privileges WHERE name = "$privilegename"));
	my $rv = $database->do($stmt) or sqlError $DBI::errstr and return -1;
	
	return 0;
}

# test code
	addPrivilege("testprivilege");
	my @users = listUsers();
	print "Users:\n".join("\n", @users)."\n";

	my @groups = listGroups();
	print "Groups:\n".join("\n", @groups)."\n";

	my @privileges = listPrivileges();
	print "Privileges:\n".join("\n", @privileges)."\n";

1;
