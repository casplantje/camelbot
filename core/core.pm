package core::core;

use strict; use warnings;

# add include directories
push ( @INC,"../connection");

# invoke modules
use connection::chatconnection;
use core::pluginmanager;
use core::groupmanager;

sub new
{
	print "hello world!\n";
	core::pluginmanager::loadPluginList;
	core::pluginmanager::loadPlugins();
	core::pluginmanager::unloadPlugins();
	core::pluginmanager::loadPlugins();
	connection::chatconnection::connect();
	my @polls = core::pluginmanager::listPolls;
	print "Polls:\n";
	foreach my $poll (@polls)
	{
			print "$poll\n";
	}

	while (1)
	{
		#todo: limit poll handling interval
		core::pluginmanager::handlePolls;
	};
	return 1;
}

1;
