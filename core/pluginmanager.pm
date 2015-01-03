package core::pluginmanager;

# The pluginmanager can load and unload plugins.
# There are "events", like a regex match, which plugins can
# subscribe to so the pluginmanager can call them when necessary.
# Todo: add polling list (with settable time)

use strict; use warnings;
use Module::Load;
use Symbol 'delete_package';
use Time::HiRes qw(time);
use XML::Simple;

  use Data::Dumper;

# add include directories
push ( @INC,"../plugins");

my $plugindir = "plugins";
my @plugins;
my @pluginfiles;
my @regexes;
my @polls;

my $xs = new XML::Simple(keeproot => 1,searchpath => "."); #, forcearray => 1);
my $pluginsXML;

# Polling management functions
sub registerPoll
{
	my ($poll) = @_;
	$poll->{lastTrigger} = time;
	push @polls, $poll;
}

sub unregisterPoll
{
	my ($poll) = @_;
	my $i = 0;

	foreach my $currentPoll (@polls)
	{
		if ($currentPoll == $poll)
		{
			splice @polls, $i, 1;
		}
		$i++;
	}	
}

sub listPolls
{
	foreach my $poll (@polls)
	{
		print $poll->{name} . "\n";
		# todo: either return it as a string array
		#		or send the lines as a message
	}
}

sub handlePolls
{
	my $currentTime = time;
	
	foreach my $poll (@polls)
	{
		if (($poll->{lastTrigger} + $poll->{interval}) < $currentTime)
		{
			$poll->{lastTrigger} = $currentTime;
			$poll->{handler}();
		}
	}
}

# Regex management functions
sub registerRegex
{
	my ($regex) = @_;
	push @regexes, $regex;
}

sub unregisterRegex
{
	my ($regex) = @_;
	my $i = 0;
	
	foreach my $currentRegex (@regexes)
	{
		if ($currentRegex == $regex)
		{
			splice @regexes, $i, 1;
		}
		$i++;
	}
}

sub listRegexes
{
	foreach my $regex (@regexes)
	{
		print $regex->{name} . "\n";
		# todo: either return it as a string array
		#		or send the lines as a message
	}
}

sub handleMessageRegex
{
	my ($message) = @_;
		
	foreach my $regex (@regexes)
	{
		if (defined($message->{message}))
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
			push @plugins, $module;
			push @pluginfiles, $modulepath;
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
}

# Load the plugins xml into hash reference $pluginsXML
sub loadPluginList
{
	$pluginsXML = $xs->XMLin("plugins.xml");
}

# Write hash reference $pluginsXML back to the xml file
sub savePluginList
{
	open(my $fh, '>', 'plugins.xml');
	print $fh $xs->XMLout($pluginsXML);
	close $fh;
}

print "loaded plugin manager module!\n";

1;
