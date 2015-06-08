package plugins::twitchconnection;

use core::pluginmanager;
use strict; use warnings;
use WWW::Curl::Easy;
use connection::credentials;
use JSON;
use Time::HiRes qw(time);

use Data::Dumper;

my $curl = WWW::Curl::Easy->new;

#TODO: add threaded mechanism that retrieves polls
# The polls can be added to a list and will be retrieved on interval and stored in a hash array.
# The retrieved information can then be requested from the hash array for immediate access.

my @polls;

#** @method private pollThread()
# @brief executes polling operations, contains own curl handler
#*
sub pollThread
{
	
}

#** @method public registerPoll($poll)
# @brief adds poll to the list
#
# @param poll hash containing all settings for the poll
#*
sub registerPoll
{
	my ($poll) = @_;
	$poll->{lastTrigger} = time;
	$core::semaphore::coreSemaphore->down();
	push @polls, $poll;
	$core::semaphore::coreSemaphore->up();
}

#** @method public unregisterPoll($poll)
# @brief removes poll from the list
#
# @param poll string identifier of the poll
#*
sub unregisterPoll
{
	
}

#** @method getPollData($poll)
# @brief returns the information belonging to $poll
#
# @param poll string identifier of the poll
#
# @return hash with the poll information as returned by curl
#*
sub getPollData
{
	
}

#** @method private getToken ()
# @brief retrieves the twitch API token from the irc credentials
#*
sub getToken
{
	my $oauth = connection::credentials::ircSetting("login");
	my ($sink, $token) = split(":", $oauth);
	return $token
}

sub apiQuery
{
	my ($query) = @_;
	$curl->setopt(CURLOPT_URL, 'https://api.twitch.tv/kraken/'.$query);	
	
	my @headers=();
	$headers[0] = "Authorization: OAuth " . getToken();
	$headers[1] = "Accept: application/vnd.twitchtv.v3+json"; 
	
	$curl->setopt(CURLOPT_HTTPHEADER, \@headers); 
	
	# A filehandle, reference to a scalar or reference to a typeglob can be used here.
	my $response_body;
	$curl->setopt(CURLOPT_WRITEDATA,\$response_body);

	# Starts the actual request
	my $retcode = $curl->perform;
	
	
	# Looking at the results...
	if ($retcode == 0) {
			return decode_json $response_body;
	} else {
			# Error code, type of error, error message
			return $retcode;
	}

}


#** @method public loadPlugin ()
# @brief function called when the plugin is loaded
#*
sub loadPlugin
{

}

#** @method public unloadPlugin ()
# @brief function called when the plugin is unloaded
#*
sub unloadPlugin
{

}

print Dumper(apiQuery("channels/garyfaceman"));
print "Loaded twitch API connection plugin!\n";


1;
