#** @file builtin.pm
# @brief module containing handlers for builtin functions
#*
package core::builtin;

use strict; use warnings;
use Switch;

use core::groupmanager;
use connection::chatconnection;

#** @method public handleMessageRegex (%message)
# @brief returns an array containing all privileges the user has been assigned to exclusively
#
# @param message a Hashlist 
#
# @return
# @retval 0 the caller isn't allowed to call any other message handling functions
# @retval 1 the caller is allowed to call any other message handling functions
#*
sub handleMessageRegex
{
	my ($message) = @_;
	
	my $messagestring = $message->{message};
	
	my @groupcommands = ($messagestring =~ "!groups\ ([a-zA-Z]*) ([a-zA-Z\ ]*)");
	if (@groupcommands)
	{
		if (core::groupmanager::userHasPrivilege($message->{nick}, "groupmanagement"))
		{
			my $command = lc $groupcommands[0];
			my $parameters = $groupcommands[1];
			switch ($command)
			{
				case "addgroup"
				{
					if (core::groupmanager::addGroup($parameters))
					{
						connection::chatconnection::sendMessage("Added group " . $parameters);
					} else 
					{
						connection::chatconnection::sendMessage("Could not add group " . $parameters);
					}
				}
				
				case "deletegroup"
				{
					
				}
			}
		}
	}
	
	return 1;
}

1;
