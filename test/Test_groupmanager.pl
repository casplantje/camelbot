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

# Copy the database in this directory for testing
ok(copy("$FindBin::Bin/../groupmanagement.db","groupmanagement.db"), "Copied database for testing");

# The actual test actions

# User adding
ok(core::groupmanager::addUser($testUserName), "Added test user");
ok(core::groupmanager::addUser($testUserName) ==  0, "Tries to add same test user a second time");

# Group adding
ok(core::groupmanager::addGroup($testGroupName), "Added test group");
ok(core::groupmanager::addGroup($testGroupName) == 0, "Tries to add same test group a second time");

# Add user to group
ok(core::groupmanager::addUserToGroup($testUserName, $testGroupName), "Added test user to test group");
ok(core::groupmanager::addUserToGroup($testUserName, $testGroupName) == 0, "Tries to add test user to test group a second time");

# Group removal
ok(core::groupmanager::deleteGroup($testGroupName), "Removed test group");
ok(core::groupmanager::deleteGroup($testGroupName) == 0, "Tries to remove same test group a second time");

# User removal
ok(core::groupmanager::deleteUser($testUserName), "Removed test user");
ok(core::groupmanager::deleteUser($testUserName) == 0, "Removed same test user");

