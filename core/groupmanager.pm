package core::groupmanager;

use List::MoreUtils qw(zip);
use strict;
use DBI;

use threads (	'yield',
				'stack_size' => 64*4096,
				'exit' => 'threads_only',
				'stringify');
				
use Thread::Semaphore;

my $dbSemaphore =  Thread::Semaphore->new();

my $database;

# Superuser group which is granted all rights
my $superUserGroupName = "superuser";

# This module contains functions to manage user and group privileges

# General error reporting function
# Camelbot should not die because of a single sql failure
sub sqlError
{
	$database->rollback();
	my ($errorMessage) = @_;
	print "$errorMessage\n";
}

$database = DBI->connect("dbi:SQLite:dbname=groupmanagement.db","","")
	or sqlError $DBI::errstr and return ();

sub getUserGroups
{
	my ($username) = @_;
	my $stmt = qq(SELECT DISTINCT groups.name FROM users 
					INNER JOIN usergroups ON users.id = usergroups.userid 
					INNER JOIN groups ON groups.id = usergroups.groupid 
					WHERE users.name="$username");
	
	$dbSemaphore->down();
	my $sth = $database->prepare($stmt);
	my $rv = $sth->execute() or sqlError $DBI::errstr and return ();
	$dbSemaphore->up();
	
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
					
	$dbSemaphore->down();
	my $sth = $database->prepare($stmt);
	my $rv = $sth->execute() or sqlError $DBI::errstr and return ();
	$dbSemaphore->up();
	
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
					
	$dbSemaphore->down();
	my $sth = $database->prepare($stmt);
	my $rv = $sth->execute() or sqlError $DBI::errstr and return ();
	$dbSemaphore->up();
	
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
					
	$dbSemaphore->down();
	my $sth = $database->prepare($stmt);
	my $rv = $sth->execute() or sqlError $DBI::errstr and return ();
	$dbSemaphore->up();
	
	my @result;
	
	while(my @row = $sth->fetchrow_array()) {
		push @result, $row[0];
	}
	return @result;
}

sub listUsers
{
	my $stmt = qq(SELECT name FROM users);
	
	$dbSemaphore->down();
	my $sth = $database->prepare($stmt);
	my $rv = $sth->execute() or sqlError $DBI::errstr and return ();
	$dbSemaphore->up();
	
	my @result;
	
	while(my @row = $sth->fetchrow_array()) {
		push @result, $row[0];
	}
	return @result;	
}

sub listGroups
{
	my $stmt = qq(SELECT name FROM groups);
	
	$dbSemaphore->down();
	my $sth = $database->prepare($stmt);
	my $rv = $sth->execute() or sqlError $DBI::errstr and return ();
	$dbSemaphore->up();
	my @result;
	
	while(my @row = $sth->fetchrow_array()) {
		push @result, $row[0];
	}
	return @result;	
}

sub listPrivileges
{
	my $stmt = qq(SELECT name FROM privileges);
	
	$dbSemaphore->down();
	my $sth = $database->prepare($stmt);
	my $rv = $sth->execute() or sqlError $DBI::errstr and return ();
	$dbSemaphore->up();
	
	my @result;
	
	while(my @row = $sth->fetchrow_array()) {
		push @result, $row[0];
	}
	return @result;	
}

sub deleteUser
{
	my ($username) = @_;
	my $stmt = qq(DELETE FROM users WHERE name="$username");
	
	$dbSemaphore->down();
	my $rv = $database->do($stmt) or sqlError $DBI::errstr and return ();
	$dbSemaphore->up();
	
	if( $rv < 0 ){
	   print $DBI::errstr;
	}
	
	return $rv;	
}

sub deleteGroup
{
	my ($groupname) = @_;
	my $stmt = qq(DELETE FROM groups WHERE name="$groupname");
	
	$dbSemaphore->down();
	my $rv = $database->do($stmt) or sqlError $DBI::errstr and return ();
	$dbSemaphore->up();
	
	if( $rv < 0 ){
	   print $DBI::errstr;
	}
	
	return $rv;
}

sub deletePrivilege
{
	my ($privilegename) = @_;
	my $stmt = qq(DELETE FROM users WHERE name="$privilegename");
	
	$dbSemaphore->down();
	my $rv = $database->do($stmt) or sqlError $DBI::errstr and return ();
	$dbSemaphore->up();
	
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
					
	$dbSemaphore->down();
	my $rv = $database->do($stmt) or sqlError $DBI::errstr and return -1;
	$dbSemaphore->up();
	
	return 0;
}

sub addGroup
{
	my ($groupname) = @_;
	my $stmt = qq(INSERT INTO groups (name)
					SELECT "$groupname"
					WHERE NOT EXISTS (SELECT * FROM groups WHERE name = "$groupname"));
					
	$dbSemaphore->down();
	my $rv = $database->do($stmt) or sqlError $DBI::errstr and return -1;
	$dbSemaphore->up();
	
	return 0;
}

sub addPrivilege
{
	my ($privilegename) = @_;
	my $stmt = qq(INSERT INTO privileges (name)
					SELECT "$privilegename"
					WHERE NOT EXISTS (SELECT * FROM privileges WHERE name = "$privilegename"));
					
	$dbSemaphore->down();
	my $rv = $database->do($stmt) or sqlError $DBI::errstr and return -1;
	$dbSemaphore->up();
	
	return 0;
}

sub addUserToGroup
{
	my ($username, $groupname) = @_;
	my $stmt = qq(INSERT INTO usergroups (userid, groupid)
					SELECT users.id, groups.id  FROM users, groups 
					WHERE users.name = "$username" AND groups.name = "$groupname");
					
	$dbSemaphore->down();
	my $rv = $database->do($stmt) or sqlError $DBI::errstr and return -1;
	$dbSemaphore->up();
	
	return 0;
}

sub addPrivilegeToUser
{
	my ($privilegename, $username) = @_;
	my $stmt = qq(INSERT INTO userprivileges (userid, privilegeid)
					SELECT users.id, privileges.id  FROM users, privileges
					WHERE users.name = "$username" AND privileges.name = "$privilegename");
					
	$dbSemaphore->down();
	my $rv = $database->do($stmt) or sqlError $DBI::errstr and return -1;
	$dbSemaphore->up();
	
	return 0;
}

sub addPrivilegeToGroup
{
	my ($privilegename, $groupname) = @_;
	my $stmt = qq(INSERT INTO groupprivileges (groupid, privilegeid)
					SELECT groups.id, privileges.id  FROM groups, privileges
					WHERE groups.name = "$groupname" AND privileges.name = "$privilegename");
					
	$dbSemaphore->down();
	my $rv = $database->do($stmt) or sqlError $DBI::errstr and return -1;
	$dbSemaphore->up();
	
	return 0;
}

sub userHasPrivilege
{
	my ($username, $privilegename) = @_;
	my @userprivileges = getUserPrivileges($username);
	my @groupprivileges = getUserGroupPrivileges($username);

	foreach my $currentprivilege (@userprivileges)
	{
		if ($privilegename == $currentprivilege)
		{return 1;}
	}

	foreach my $currentprivilege (@groupprivileges)
	{
		if ($privilegename == $currentprivilege)
		{return 1;}
	}
	
	# Hardcoded poweruser check; powerusers have all privileges
	my @usergroups = getUserGroups($username);

	foreach my $currentgroup (@usergroups)
	{
		if ($currentgroup == $superUserGroupName)
		{return 1;}
	}
	
	

	return 0;
}

sub deleteUserFromGroup
{
	my ($username, $groupname) = @_;
	my $stmt = qq(DELETE FROM usergroups
					WHERE userid = (SELECT id FROM users WHERE name="$username") AND groupid = (SELECT id FROM groups WHERE name="$groupname"));
					
	$dbSemaphore->down();
	my $rv = $database->do($stmt) or sqlError $DBI::errstr and return -1;
	$dbSemaphore->up();
	
	return 0;
}

sub deletePrivilegeFromGroup
{
	my ($privilegename, $groupname) = @_;
	my $stmt = qq(DELETE FROM groupprivileges
					WHERE privilegeid = (SELECT id FROM privileges WHERE name="$privilegename") AND groupid = (SELECT id FROM groups WHERE name="$groupname"));
					
	$dbSemaphore->down();
	my $rv = $database->do($stmt) or sqlError $DBI::errstr and return -1;
	$dbSemaphore->up();
	
	return 0;
}

sub deletePrivilegeFromUser
{
	my ($privilegename, $username) = @_;
	my $stmt = qq(DELETE FROM userprivileges
					WHERE privilegeid = (SELECT id FROM privileges WHERE name="$privilegename") AND userid = (SELECT id FROM users WHERE name="$username"));
					
	$dbSemaphore->down();
	my $rv = $database->do($stmt) or sqlError $DBI::errstr and return -1;
	$dbSemaphore->up();
	
	return 0;
}

# test code
	my @users = getUserGroups("casplantje");
	print "Casplantje's groups:\n".join("\n", @users)."\n";

	my @groups = listGroups();
	print "Groups:\n".join("\n", @groups)."\n";

	my @privileges = listPrivileges();
	print "Privileges:\n".join("\n", @privileges)."\n";

1;
