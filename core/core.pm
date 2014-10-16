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
	#connection::irc::readText();
	while (1){
		sleep(2);
		print "test \n";};
	return 1;
}

1;
