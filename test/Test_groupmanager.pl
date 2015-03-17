#!/usr/bin/perl -w

# Modules required for testing
use strict; use warnings;
use File::Copy;
use FindBin;                 		# locate this script
use lib "$FindBin::Bin/../core";	# use the parent directory

# The module that will be tested
use groupmanager;

use Test::Most tests => 7;

my $testUserName = "unitTestUser";
my $testGroupName = "unitTestGroup";
my $testPrivilegeName = "unitTestPrivilege";


# Copy the database in this directory for testing
ok(copy("$FindBin::Bin/../groupmanagement.db","groupmanagement.db"), "Copied database for testing");

# The actual test actions

# Test case set 1: simple adding and removal of everything

# User adding
ok(core::groupmanager::addUser($testUserName), "Added test user");
ok(core::groupmanager::addUser($testUserName) ==  0, "Tries to add same test user a second time");

# Group adding
ok(core::groupmanager::addGroup($testGroupName), "Added test group");
ok(core::groupmanager::addGroup($testGroupName) == 0, "Tries to add same test group a second time");

# Privilege adding
ok(core::groupmanager::addPrivilege($testPrivilegeName), "Added test privilege");
ok(core::groupmanager::addPrivilege($testPrivilegeName) == 0, "Tries to add same test privilege a second time");

# Add user to group
ok(core::groupmanager::addUserToGroup($testUserName, $testGroupName), "Added test user to test group");
ok(core::groupmanager::addUserToGroup($testUserName, $testGroupName) == 0, "Tries to add test user to test group a second time");

# Add privilege to user
ok(core::groupmanager::addPrivilegeToUser($testPrivilegeName, $testUserName), "Added test privilege to test user");
ok(core::groupmanager::addPrivilegeToUser($testPrivilegeName, $testUserName) == 0, "Tries to add test privilege to test user a second time");

# Add privilege to group
ok(core::groupmanager::addPrivilegeToGroup($testPrivilegeName, $testGroupName), "Added test privilege to test group");
ok(core::groupmanager::addPrivilegeToGroup($testPrivilegeName, $testGroupName) == 0, "Tries to add test privilege to test user a second time");

# Check the privileges of the user
ok(eq_array(core::groupmanager::getUserPrivileges($testUserName), ($testPrivilegeName,$testPrivilegeName)), "User privileges are correct");

# Remove Privileges from group
ok(core::groupmanager::deletePrivilegeFromGroup($testPrivilegeName, $testGroupName), "Removed test privilege from test group");
ok(core::groupmanager::deletePrivilegeFromGroup($testPrivilegeName, $testGroupName) == 0, "Tries to remove test privilege from test group a second time");

# Remove Privileges from user
ok(core::groupmanager::deletePrivilegeFromUser($testPrivilegeName, $testUserName), "Removed test privilege from test user");
ok(core::groupmanager::deletePrivilegeFromUser($testPrivilegeName, $testUserName) == 0, "Tries to remove test privilege from test user a second time");

# Remove user from group
ok(core::groupmanager::deleteUserFromGroup($testUserName, $testGroupName), "Removed test user from test group");
ok(core::groupmanager::deleteUserFromGroup($testUserName, $testGroupName) == 0, "Tries to remove test user from test group a second time");

# Privilege removal
ok(core::groupmanager::deletePrivilege($testPrivilegeName), "Removed test privilege");
ok(core::groupmanager::deletePrivilege($testPrivilegeName) == 0, "Tries to remove same test privilege a second time");

# Group removal
ok(core::groupmanager::deleteGroup($testGroupName), "Removed test group");
ok(core::groupmanager::deleteGroup($testGroupName) == 0, "Tries to remove same test group a second time");

# User removal
ok(core::groupmanager::deleteUser($testUserName), "Removed test user");
ok(core::groupmanager::deleteUser($testUserName) == 0, "Removed same test user");

# Test case set 2: user removal with group and privilege connection in place
ok(core::groupmanager::addUser($testUserName), "Added test user");
ok(core::groupmanager::addGroup($testGroupName), "Added test group");
ok(core::groupmanager::addUserToGroup($testUserName, $testGroupName), "Added test user to test group");
ok(core::groupmanager::addPrivilege($testPrivilegeName), "Added test privilege");
ok(core::groupmanager::addPrivilegeToUser($testPrivilegeName, $testUserName), "Added test privilege to test user");
ok(core::groupmanager::deleteUser($testUserName), "Removed test user");
ok(core::groupmanager::deleteGroup($testGroupName), "Removed test group");
ok(core::groupmanager::deletePrivilege($testPrivilegeName), "Removed test privilege");

# Test case set 3: group removal with user and privilege connection in place
ok(core::groupmanager::addUser($testUserName), "Added test user");
ok(core::groupmanager::addGroup($testGroupName), "Added test group");
ok(core::groupmanager::addUserToGroup($testUserName, $testGroupName), "Added test user to test group");
ok(core::groupmanager::addPrivilege($testPrivilegeName), "Added test privilege");
ok(core::groupmanager::addPrivilegeToGroup($testPrivilegeName, $testGroupName), "Added test privilege to test group");
ok(core::groupmanager::deleteGroup($testGroupName), "Removed test group");
ok(core::groupmanager::deleteUser($testUserName), "Removed test user");

# Test case set 3: privilege removal with user connection in place
ok(core::groupmanager::addUser($testUserName), "Added test user");
ok(core::groupmanager::addPrivilege($testPrivilegeName), "Added test privilege");
ok(core::groupmanager::addPrivilegeToUser($testPrivilegeName, $testUserName), "Added test privilege to test user");
ok(core::groupmanager::deletePrivilege($testPrivilegeName), "Removed test privilege");
ok(core::groupmanager::deleteUser($testUserName), "Removed test user");

# Test case set 4: privilege removal with group connection in place
ok(core::groupmanager::addGroup($testGroupName), "Added test group");
ok(core::groupmanager::addPrivilege($testPrivilegeName), "Added test privilege");
ok(core::groupmanager::addPrivilegeToGroup($testPrivilegeName, $testGroupName), "Added test privilege to test group");
ok(core::groupmanager::deletePrivilege($testPrivilegeName), "Removed test privilege");
ok(core::groupmanager::deleteGroup($testGroupName), "Removed test group");
