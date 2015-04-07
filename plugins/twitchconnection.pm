package plugins::twitchconnection;

use core::pluginmanager;
use strict; use warnings;
use WWW::Curl::Easy;
use connection::credentials;
use JSON;

use Data::Dumper;

my $curl = WWW::Curl::Easy->new;

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
