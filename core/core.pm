package core::core;

use strict; use warnings;

# add include directories
push ( @INC,"../connection");

# invoke modules
use connection::irc;
use core::pluginmanager;

sub new
{
	print "hello world!\n";
	connection::irc::connect();
	connection::irc::readText();
	return 1;
}

1;
