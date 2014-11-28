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
	core::pluginmanager::loadPlugins();
	core::pluginmanager::unloadPlugins();
	core::pluginmanager::loadPlugins();
	connection::irc::connect();
	#connection::irc::readText();
	while (1){
		my $input =  readline(*STDIN);
		if ($input =~ "PING")
		{
			connection::irc::sendCommand("PING");
		}
		connection::irc::sendText($input);
		};
	return 1;
}

1;
