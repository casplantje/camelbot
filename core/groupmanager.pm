#** @file groupmanager.pm
# @brief Group management module that makes use of an sqlite database
#
#*
package core::groupmanager;

use List::MoreUtils qw(zip);
use strict;
use DBI;
use threads ('yield','stack_size' => 64*4096,'exit' => 'threads_only','stringify');		
use Thread::Semaphore;

#** @var private $tid the id of the database thread
#*
my $tid = threads->tid();

#** @var private $dbSemaphore semaphore for database access
#*
my $dbSemaphore =  Thread::Semaphore->new();

#** @var private $dbh Root DBI handle
#*
my $dbh;

#** @var private @dbHandlers Array of all db handlers
# @brief This array links thread ids to database handlers because DBI requires a separate one for each thread
#*
my @dbHandlers;

#** @method private getDatabaseHandler() Returns DBI handle that belongs to the current thread
# @brief Looks in $dbHandlers whether there's already a handler in use for the current thread
# and makes a new one if not.
#
# @return the database handler belonging to the current thread
#*
sub getDatabaseHandler
{
	my $tid = threads->tid();
	
	if (!defined($dbHandlers[$tid]))
	{
		$dbHandlers[$tid] = DBI->connect("dbi:SQLite:dbname=groupmanagement.db","","")
							or sqlError $DBI::errstr and return ();
	}
	return $dbHandlers[$tid];
}

#** @var private $superUserGroupName superuser group which is granted all rights
#*
my $superUserGroupName = "superuser";

# This module contains functions to manage user and group privileges


#** @method private sqlError ($errorMessage)
# @brief General error reporting function
#
# Camelbot should not die because of a single sql failure, this 
# function handles it quietly.
#
# @param errorMessage The errormesage thrown by DBI
#*
sub sqlError
{
	my ($errorMessage) = @_;
	if ($errorMessage =~ /UNIQUE/)
	{
		return;
	}
	
	getDatabaseHandler()->rollback();
	print "$errorMessage\n";
}
	
# ----------------------------------------
# Public Methods
# ----------------------------------------

#** @method public getGroupUsers ($groupname)
# @brief returns an array containing all users in a group
#
# @param groupname The groupname to retrieve the users from
#
# @return an array of all usernames in the group
#*
sub getGroupUsers
{
	my ($groupname) = @_;
	my $stmt = qq(SELECT DISTINCT users.name FROM groups 
					INNER JOIN usergroups ON groups.id = usergroups.groupid
					INNER JOIN users ON users.id = usergroups.userid 
					WHERE groups.name="$groupname");
	
	my $sth = getDatabaseHandler()->prepare($stmt);
	my $rv = $sth->execute() or sqlError $DBI::errstr and return ();
	
	my @result;
	
	while(my @row = $sth->fetchrow_array()) {
		push @result, $row[0];
	}
	return @result;
}

#** @method public getUserGroups ($username)
# @brief returns an array containing all groups an user is in
#
# @param username The username to retrieve the groups from
#
# @return an array of all groupnames the user is in 
#*
sub getUserGroups
{
	my ($username) = @_;
	my $stmt = qq(SELECT DISTINCT groups.name FROM users 
					INNER JOIN usergroups ON users.id = usergroups.userid 
					INNER JOIN groups ON groups.id = usergroups.groupid 
					WHERE users.name="$username");
	
	my $sth = getDatabaseHandler()->prepare($stmt);
	my $rv = $sth->execute() or sqlError $DBI::errstr and return ();
	
	my @result;
	
	while(my @row = $sth->fetchrow_array()) {
		push @result, $row[0];
	}
	return @result;
}

#** @method public getUserUserPrivileges ($username)
# @brief returns an array containing all privileges the user has been assigned to exclusively
#
# @param username The username to retrieve the privileges from
#
# @return an array of all privilege names the user has been assigned directly
#*
sub getUserUserPrivileges
{
	my ($username) = @_;
	my $stmt = qq(SELECT DISTINCT privileges.name FROM users
					INNER JOIN userprivileges ON userprivileges.userid = users.id 
					INNER JOIN privileges ON userprivileges.privilegeid = privileges.id
					WHERE users.name="$username");
					
	my $sth = getDatabaseHandler()->prepare($stmt);
	my $rv = $sth->execute() or sqlError $DBI::errstr and return ();
	
	my @result;
	
	while(my @row = $sth->fetchrow_array()) {
		push @result, $row[0];
	}
	return @result;
}

#** @method public getUserGroupPrivileges($username)
# @brief returns an array containing all privileges the user has been assigned to through groups
#
# @param username The username to retrieve the privileges from
#
# @return an array of all privilege names the user has been assigned through groups
#*
sub getUserGroupPrivileges
{
	my ($username) = @_;
	my $stmt = qq(SELECT DISTINCT privileges.name FROM users 
					INNER JOIN usergroups ON users.id = usergroups.userid 
					INNER JOIN groups ON groups.id = usergroups.groupid 
					INNER JOIN groupprivileges ON groups.id = groupprivileges.groupid 
					INNER JOIN privileges ON privileges.id = groupprivileges.privilegeid 
					WHERE users.name="$username");
					
	my $sth = getDatabaseHandler()->prepare($stmt);
	my $rv = $sth->execute() or sqlError $DBI::errstr and return ();
	
	my @result;
	
	while(my @row = $sth->fetchrow_array()) {
		push @result, $row[0];
	}
	return @result;
}

#** @method public getUserPrivileges($username)
# @brief returns an array containing all privileges the user has been assigned to
#
# @param username The username to retrieve the privileges from
#
# @return an array of all privilege names the user has been assigned to
#*
sub getUserPrivileges
{
	my ($username) = @_;
	my @userPrivileges = getUserUserPrivileges($username);
	my @groupPrivileges = getUserGroupPrivileges($username);
	return zip(@userPrivileges, @groupPrivileges);
}

#** @method public getGroupPrivileges($groupname)
# @brief returns an array containing all privileges the group has been assigned to
#
# @param groupname The groupname to retrieve the privileges from
#
# @return an array of all privilege names the group has been assigned to
#*
sub getGroupPrivileges
{
	my ($groupname) = @_;
	my $stmt = qq(SELECT DISTINCT privileges.name FROM groups
					INNER JOIN groupprivileges ON groups.id = groupprivileges.groupid 
					INNER JOIN privileges ON privileges.id = groupprivileges.privilegeid 
					WHERE groups.name="$groupname");
					
	my $sth = getDatabaseHandler()->prepare($stmt);
	my $rv = $sth->execute() or sqlError $DBI::errstr and return ();
	
	my @result;
	
	while(my @row = $sth->fetchrow_array()) {
		push @result, $row[0];
	}
	return @result;
}

#** @method public listUsers()
# @brief returns an array containing all users in the database
#
# @return an array of all users in the database
#*
sub listUsers
{
	my $stmt = qq(SELECT name FROM users);
	
	my $sth = getDatabaseHandler()->prepare($stmt);
	my $rv = $sth->execute() or sqlError $DBI::errstr and return ();
	
	my @result;
	
	while(my @row = $sth->fetchrow_array()) {
		push @result, $row[0];
	}
	return @result;	
}

#** @method public listGroups()
# @brief returns an array containing all groups in the database
#
# @return an array of all groups in the database
#*
sub listGroups
{
	my $stmt = qq(SELECT name FROM groups);
	
	my $sth = getDatabaseHandler()->prepare($stmt);
	my $rv = $sth->execute() or sqlError $DBI::errstr and return ();
	
	my @result;
	
	while(my @row = $sth->fetchrow_array()) {
		push @result, $row[0];
	}
	return @result;	
}

#** @method public listPrivileges()
# @brief returns an array containing all privileges in the database
#
# @return an array of all privileges in the database
#*
sub listPrivileges
{
	my $stmt = qq(SELECT name FROM privileges);
	
	my $sth = getDatabaseHandler()->prepare($stmt);
	my $rv = $sth->execute() or sqlError $DBI::errstr and return ();
	
	my @result;
	
	while(my @row = $sth->fetchrow_array()) {
		push @result, $row[0];
	}
	return @result;	
}

#** @method public deleteUser($username)
# @brief removes the user with name $username from the database
#
# @param username The name of the user to remove
#
# @return number of rows deleted from the table. This should be either 0 or 1 where 0 means failure and 1 means succes.
#*
sub deleteUser
{
	my ($username) = @_;
	my $stmt = qq(DELETE FROM users WHERE name="$username");
	
	my $rv = getDatabaseHandler()->do($stmt) or sqlError $DBI::errstr and return ();
	
	if( $rv < 0 ){
	   print $DBI::errstr;
	}
	
	return $rv;	
}

#** @method public deleteGroup($groupname)
# @brief removes the user with name $groupname from the database
#
# @param groupname The name of the group to remove
#
# @return number of rows deleted from the table. This should be either 0 or 1 where 0 means failure and 1 means succes.
#*
sub deleteGroup
{
	my ($groupname) = @_;
	my $stmt = qq(DELETE FROM groups WHERE name="$groupname");
	
	my $rv = getDatabaseHandler()->do($stmt) or sqlError $DBI::errstr and return ();
	
	if( $rv < 0 ){
	   print $DBI::errstr;
	}
	
	return $rv;
}

#** @method public deletePrivilege($privilegename)
# @brief removes the privilege with name $privilegename from the database
#
# @param privilegename The name of the privilege to remove
#
# @return number of rows deleted from the table. This should be either 0 or 1 where 0 means failure and 1 means succes.
#*
sub deletePrivilege
{
	my ($privilegename) = @_;
	my $stmt = qq(DELETE FROM users WHERE name="$privilegename");
	
	my $rv = getDatabaseHandler()->do($stmt) or sqlError $DBI::errstr and return ();
	
	if( $rv < 0 ){
	   print $DBI::errstr;
	}
	
	return $rv;	
}

#** @method public addUser($username)
# @brief adds the user with name $username to the database
#
# @param username The name of the user to add
#
# @return number of rows added to the table. This should be either 0 or 1 where 0 means failure and 1 means succes.
#*
sub addUser
{
	my ($username) = @_;
	my $stmt = qq(INSERT INTO users (name)
					SELECT "$username"
					WHERE NOT EXISTS (SELECT * FROM users WHERE name = "$username"));			
	
	my $rv = getDatabaseHandler()->do($stmt) or sqlError $DBI::errstr;
	
	return $rv;
}

#** @method public addGroup($groupname)
# @brief adds the group with name $groupname to the database
#
# @param groupname The name of the group to add
#
# @return number of rows added to the table. This should be either 0 or 1 where 0 means failure and 1 means succes.
#*
sub addGroup
{
	my ($groupname) = @_;	
	my $stmt = qq(INSERT INTO groups (name)
					SELECT "$groupname"
					WHERE NOT EXISTS (SELECT * FROM groups WHERE name = "$groupname"));
					
	my $rv = getDatabaseHandler()->do($stmt) or sqlError $DBI::errstr;
	
	return $rv;
}

#** @method public addPrivilege($privilegename)
# @brief adds the privilege with name $privilegename to the database
#
# @param privilegename The name of the privilege to add
#
# @return number of rows added to the table. This should be either 0 or 1 where 0 means failure and 1 means succes.
#*
sub addPrivilege
{
	my ($privilegename) = @_;
	my $stmt = qq(INSERT INTO privileges (name)
					SELECT "$privilegename"
					WHERE NOT EXISTS (SELECT * FROM privileges WHERE name = "$privilegename"));
					
	my $rv = getDatabaseHandler()->do($stmt) or sqlError $DBI::errstr;
	
	return $rv;
}

#** @method public addUserToGroup($username, $groupname)
# @brief adds the user with name $username to group with name $groupname
#
# @param username The name of the user to add
# @param groupname The name of the group to add the user to
#
# @return number of rows added to the table. This should be either 0 or 1 where 0 means failure and 1 means succes.
#*
sub addUserToGroup
{
	my ($username, $groupname) = @_;
	my $stmt = qq(INSERT INTO usergroups (userid, groupid)
					SELECT users.id, groups.id  FROM users, groups 
					WHERE users.name = "$username" AND groups.name = "$groupname");
					
	my $rv = getDatabaseHandler()->do($stmt) or sqlError $DBI::errstr;
	
	return $rv;
}

#** @method public addPrivilegeToUser($privilegename, $username)
# @brief adds the privilege with the name $privilegename to the user with name $username
#
# @param privilegename The name of the privilege
# @param username The name of the user to add the privilege to
#
# @return number of rows added to the table. This should be either 0 or 1 where 0 means failure and 1 means succes.
#*
sub addPrivilegeToUser
{
	my ($privilegename, $username) = @_;
	my $stmt = qq(INSERT INTO userprivileges (userid, privilegeid)
					SELECT users.id, privileges.id  FROM users, privileges
					WHERE users.name = "$username" AND privileges.name = "$privilegename");
					
	my $rv = getDatabaseHandler()->do($stmt) or sqlError $DBI::errstr;
	
	return $rv;
}

#** @method public addPrivilegeToGroup($privilegename, $groupname)
# @brief adds the privilege with the name $privilegename to the group with name $groupname
#
# @param privilegename The name of the privilege
# @param groupname The name of the group to add the privilege to
#
# @return number of rows added to the table. This should be either 0 or 1 where 0 means failure and 1 means succes.
#*
sub addPrivilegeToGroup
{
	my ($privilegename, $groupname) = @_;
	my $stmt = qq(INSERT INTO groupprivileges (groupid, privilegeid)
					SELECT groups.id, privileges.id  FROM groups, privileges
					WHERE groups.name = "$groupname" AND privileges.name = "$privilegename");
					
	my $rv = getDatabaseHandler()->do($stmt) or sqlError $DBI::errstr;
	
	return $rv;
}

#** @method public userHasPrivilege($username, $privilegename)
# @brief checks whether user with name $username has privilege with name $privilegename
#
# @param username The name of the user to check
# @param privilegename The name of the privilege to check on
#
# @return 1 if the user has the privilege or 0 if the user doesn't.
#*
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

#** @method public deleteUserFromGroup($username, $groupname)
# @brief removes the user with name $username from group with name $groupname
#
# @param username The name of the user to remove
# @param groupname The name of the group to remove the user from
#
# @return number of rows deleted from the table. This should be either 0 or 1 where 0 means failure and 1 means succes.
#*
sub deleteUserFromGroup
{
	my ($username, $groupname) = @_;
	my $stmt = qq(DELETE FROM usergroups
					WHERE userid = (SELECT id FROM users WHERE name="$username") AND groupid = (SELECT id FROM groups WHERE name="$groupname"));
					
	my $rv = getDatabaseHandler()->do($stmt) or sqlError $DBI::errstr;
	
	return $rv;
}

#** @method public deletePrivilegeFromGroup($privilegename, $groupname)
# @brief removes the privilege with name $privilegename from group with name $groupname
#
# @param privilegename The name of the privilege to remove
# @param groupname The name of the group to remove the privilege from
#
# @return number of rows deleted from the table. This should be either 0 or 1 where 0 means failure and 1 means succes.
#*
sub deletePrivilegeFromGroup
{
	my ($privilegename, $groupname) = @_;
	my $stmt = qq(DELETE FROM groupprivileges
					WHERE privilegeid = (SELECT id FROM privileges WHERE name="$privilegename") AND groupid = (SELECT id FROM groups WHERE name="$groupname"));
					
	my $rv = getDatabaseHandler()->do($stmt) or sqlError $DBI::errstr;
	
	return $rv;
}

#** @method public deletePrivilegeFromUser($privilegename, $username)
# @brief removes the privilege with name $privilegename from user with name $username
#
# @param privilegename The name of the privilege to remove
# @param username The name of the user to remove the privilege from
#
# @return number of rows deleted from the table. This should be either 0 or 1 where 0 means failure and 1 means succes.
#*
sub deletePrivilegeFromUser
{
	my ($privilegename, $username) = @_;
	my $stmt = qq(DELETE FROM userprivileges
					WHERE privilegeid = (SELECT id FROM privileges WHERE name="$privilegename") AND userid = (SELECT id FROM users WHERE name="$username"));
					
	my $rv = getDatabaseHandler()->do($stmt) or sqlError $DBI::errstr;
	
	return $rv;
}

# test code
#	my @users = getUserGroups("casplantje");
#
#	my @groups = listGroups();
#	print "Groups:\n".join("\n", @groups)."\n";
#
#	my @privileges = listPrivileges();
#	print "Privileges:\n".join("\n", @privileges)."\n";

1;
