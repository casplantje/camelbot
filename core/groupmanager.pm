package core::groupmanager;

use strict;
use DBI;

# Will contain the code to manage groups
#   there will also be functions to allow plugins to inject user/group properties (for example to use the twitch api)

my $dbh = DBI->connect("dbi:SQLite:dbname=groupmanagement.db","","");


1;
