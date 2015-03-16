package core::core;

use strict; use warnings;
use Time::HiRes qw(time usleep nanosleep gettimeofday);

# add include directories
push (@INC, "../connection");

# invoke modules
use connection::chatconnection;
use core::pluginmanager;
use core::groupmanager;

# TODO: move to separate module
sub getMicroSecondTime
{
	my ($seconds, $microseconds) = gettimeofday;
	return $microseconds + $seconds * 1000000;
}

sub new
{
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

	# camelbot handles polls exactly 10 times every second
	# There's exactly 1/10th second time to do polling
	# Time consuming tasks should be done in separate threads
	my $loopTimeOut = 100000; 
	while (1)
	{
		my $starttime = getMicroSecondTime();
		core::pluginmanager::handlePolls;
		my $sleeptime = ($loopTimeOut - (getMicroSecondTime() - $starttime));
		if ($sleeptime < 0)
		{
			$sleeptime = 0;
			print "Polling takes more than 1/10th second!\nPlease consider using threads for tasks that take longer!\n";
		}
		usleep($sleeptime);
	};
	return 1;
}

1;
