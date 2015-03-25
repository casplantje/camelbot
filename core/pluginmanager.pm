package core::pluginmanager;

# The pluginmanager can load and unload plugins.
# There are "events", like a regex match, which plugins can
# subscribe to so the pluginmanager can call them when necessary.
# 
# TODO: add a queue for all functions that have to be called externally

use core::builtin;

use strict; use warnings;
use Module::Load;
use Symbol 'delete_package';
use Time::HiRes qw(time);
use XML::Simple;
use threads;
use Thread::Queue;
use Thread::Semaphore;
use core::semaphore;
use Switch;

# add include directories
push ( @INC,"../plugins");

my $plugindir = "plugins";
my @plugins;
my @pluginfiles;
my @regexes;
my @polls;

my $xs = new XML::Simple(keeproot => 1,searchpath => "."); #, forcearray => 1);
my $pluginsXML;

our $commandQueue = Thread::Queue->new();

# Polling management functions
sub registerPoll
{
	my ($poll) = @_;
	$poll->{lastTrigger} = time;
	$core::semaphore::coreSemaphore->down();
	push @polls, $poll;
	$core::semaphore::coreSemaphore->up();
}

sub unregisterPoll
{
	my ($poll) = @_;
	my $i = 0;

	$core::semaphore::coreSemaphore->down();
	foreach my $currentPoll (@polls)
	{
		if ($currentPoll == $poll)
		{
			splice @polls, $i, 1;
		}
		$i++;
	}	
	$core::semaphore::coreSemaphore->up();
}

sub listPolls
{
	my @result;
	$core::semaphore::coreSemaphore->down();
	foreach my $poll (@polls)
	{
		push @result, $poll->{name};
	}
	$core::semaphore::coreSemaphore->up();
	return @result;
}

sub handlePolls
{
	my $currentTime = time;
	
	$core::semaphore::coreSemaphore->down();
	foreach my $poll (@polls)
	{
		if (($poll->{lastTrigger} + $poll->{interval}) < $currentTime)
		{
			$poll->{lastTrigger} = $currentTime;
			$poll->{handler}();
		}
	}
	$core::semaphore::coreSemaphore->up();
}

# Regex management functions
sub registerRegex
{
	my ($regex) = @_;
	
	$core::semaphore::coreSemaphore->down();
	push @regexes, $regex;
	$core::semaphore::coreSemaphore->up();
}

sub unregisterRegex
{
	my ($regex) = @_;
	my $i = 0;
	
	$core::semaphore::coreSemaphore->down();
	foreach my $currentRegex (@regexes)
	{
		if ($currentRegex == $regex)
		{
			splice @regexes, $i, 1;
		}
		$i++;
	}
	$core::semaphore::coreSemaphore->up();
}

sub listRegexes
{
	$core::semaphore::coreSemaphore->down();
	foreach my $regex (@regexes)
	{
		print $regex->{name} . "\n";
		# todo: either return it as a string array
		#		or send the lines as a message
	}
	$core::semaphore::coreSemaphore->up();
}

sub handleMessageRegex
{
	my ($message) = @_;
		
	if (defined($message->{message}))
	{
		# Handle builtin messages
		# This function will tell whether other regexes should be parsed
		if (core::builtin::handleMessageRegex($message))
		{
			$core::semaphore::coreSemaphore->down();
			foreach my $regex (@regexes)
			{

				my $matchMessage = $message->{message};

				my @regexResults = ( $matchMessage =~ $regex->{regex});
				
				if (@regexResults)
				{
					print "Match: $matchMessage\n";
					if (defined($regex->{handler}))
					{
						print "executing handler\n";
						$regex->{handler}($message, \@regexResults);
					}
				}
			}
			$core::semaphore::coreSemaphore->up();
		}
	}
}

# Read hash reference $pluginsXML to load all enabled plugins
sub loadPlugins
{
	foreach my $xmlPlugin (@{$pluginsXML->{plugins}->{plugin}})
	{
		if ($xmlPlugin->{enabled})
		{
			print "Loading $xmlPlugin->{module}\n";
			my $module = "$plugindir::$xmlPlugin->{module}";
			my $modulepath = "$plugindir/$xmlPlugin->{module}.pm";
			load $module;
			# Call load function
			$module->loadPlugin;
			# add plugin to list
			$core::semaphore::coreSemaphore->down();
			push @plugins, $module;
			push @pluginfiles, $modulepath;
			$core::semaphore::coreSemaphore->up();
		}
	}
}

sub unloadPlugins
{
	foreach my $module (@plugins)
	{
		$module->unloadPlugin;
		# remove declarations
		delete_package $module;
	}
	
	$core::semaphore::coreSemaphore->down();
	
	foreach my $modulefile (@pluginfiles)
	{
		# unload module file
		delete $INC{$modulefile};
	}

	# Check and if necessary empty the regex and poll array
	# This is only to tidy up if plugins don't unregister
	# their regexes properly
	foreach my $regex (@regexes)
	{
		print "Warning! Regex " . $regex->{name} . " wasn't unloaded properly. Check the unloadPlugin of its module!\n";
	}
	@regexes = ();
	
	foreach my $poll (@polls)
	{
		print "Warning! poll " . $poll->{name} . " wasn't unloaded properly. Check the unloadPlugin of its module!\n";
	}
	@polls = ();

	$core::semaphore::coreSemaphore->up();
}

# Load the plugins xml into hash reference $pluginsXML
sub loadPluginList
{
	$core::semaphore::coreSemaphore->down();
	$pluginsXML = $xs->XMLin("plugins.xml");
	$core::semaphore::coreSemaphore->up();
}

# Write hash reference $pluginsXML back to the xml file
sub savePluginList
{
	$core::semaphore::coreSemaphore->down();
	open(my $fh, '>', 'plugins.xml');
	print $fh $xs->XMLout($pluginsXML);
	close $fh;
	$core::semaphore::coreSemaphore->up();
}

#** @method private handleQueue() handles a command queue for handling 
# @brief Clears up the queue, handling all commands in order
#
#*
sub handleQueue
{
	while (my $command = $commandQueue->dequeue())
	{
		switch ($command)
		{
			case "unloadPlugins" {
				unloadPlugins();
			}
			case "loadPlugins" {
				loadPlugins();
			}
			case "loadPluginList" {
				loadPluginList();
			}
		}
	}
}

print "loaded plugin manager module!\n";

1;
