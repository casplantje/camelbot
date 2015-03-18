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
	
	my @groupcommands = ($messagestring =~ "!groups\ ?([a-zA-Z]*)\ ?([a-zA-Z0-9]*)\ ?([a-zA-Z0-9\ ]*)");
	if (@groupcommands)
	{
		if (core::groupmanager::userHasPrivilege($message->{nick}, "groupmanagement"))
		{
			my $command = lc $groupcommands[0];
			switch ($command)
			{
				case "list"
				{
					my @groups = core::groupmanager::listGroups();
					if ($#groups < 0)
					{
						connection::chatconnection::sendMessage("There are no groups");
					} else
					{
						connection::chatconnection::sendMessage(join(", ", @groups));
					}
				}
				
				case "add"
				{
					if ($groupcommands[1] ne "")
					{
						my $groupname = $groupcommands[1];
						if (core::groupmanager::addGroup($groupname) == 1)
						{
							connection::chatconnection::sendMessage("Added group " . $groupname);
						} else 
						{
							connection::chatconnection::sendMessage("Could not add group " . $groupname);
						}
					} else
					{
						connection::chatconnection::sendMessage("Usage: !groups add [groupname]");
					}
				}
				
				case "delete"
				{
					if ($groupcommands[1] ne "")
					{
						my $groupname = $groupcommands[1];
						if (core::groupmanager::deleteGroup($groupname) == 1)
						{
							connection::chatconnection::sendMessage("Removed group " . $groupname);
						} else 
						{
							connection::chatconnection::sendMessage("Could not remove group " . $groupname);
						}
					} else
					{
						connection::chatconnection::sendMessage("Usage: !groups delete [groupname]");
					}
				}
				
				case "addprivilege"
				{
					if ($groupcommands[1] ne "")
					{
						my $groupname = $groupcommands[1];
						my $privilegename = $groupcommands[2];
						if (core::groupmanager::addPrivilegeToGroup($privilegename, $groupname) == 1)
						{
							connection::chatconnection::sendMessage("Added privilege $privilegename to group $groupname");
						} else 
						{
							connection::chatconnection::sendMessage("Could not add privilege $privilegename to group $groupname");
						}
					} else
					{
						connection::chatconnection::sendMessage("Usage: !groups addprivilege [groupname] [privilegename]");
					}
				}
				
				case "deleteprivilege"
				{
					if ($groupcommands[1] ne "")
					{
						my $groupname = $groupcommands[1];
						my $privilegename = $groupcommands[2];
						if (core::groupmanager::deletePrivilegeFromGroup($privilegename, $groupname) == 1)
						{
							connection::chatconnection::sendMessage("Removed privilege $privilegename from group $groupname");
						} else 
						{
							connection::chatconnection::sendMessage("Could not remove privilege $privilegename from group $groupname");
						}
					} else
					{
						connection::chatconnection::sendMessage("Usage: !groups deleteprivilege [groupname] [privilegename]");
					}
				}
				
				case "listprivileges"
				{
					if ($groupcommands[1] ne "")
					{
						my @groupprivileges = core::groupmanager::getGroupPrivileges($groupcommands[1]);
						if ($#groupprivileges < 0)
						{
							connection::chatconnection::sendMessage("This group has no privileges");
						} else
						{
							connection::chatconnection::sendMessage(join(", ", @groupprivileges));
						}
					} else
					{
						connection::chatconnection::sendMessage("Usage: !groups listprivileges [groupname]");
					}
				}
				
				case "adduser"
				{
					if ($groupcommands[1] ne "")
					{
						my $groupname = $groupcommands[1];
						my $username = $groupcommands[2];
						if (core::groupmanager::addUserToGroup($username, $groupname) == 1)
						{
							connection::chatconnection::sendMessage("Added user $username to group $groupname");
						} else 
						{
							connection::chatconnection::sendMessage("Could not add user $username to group $groupname");
						}
					} else
					{
						connection::chatconnection::sendMessage("Usage: !groups adduser [groupname] [username]");
					}
				}
				
				case "deleteuser"
				{
					if ($groupcommands[1] ne "")
					{
						my $groupname = $groupcommands[1];
						my $username = $groupcommands[2];
						if (core::groupmanager::deleteUserFromGroup($username, $groupname) == 1)
						{
							connection::chatconnection::sendMessage("Removed user $username from group $groupname");
						} else 
						{
							connection::chatconnection::sendMessage("Could not remove user $username from group $groupname");
						}
					} else
					{
						connection::chatconnection::sendMessage("Usage: !groups deleteuser [groupname] [username]");
					}
				}
				
				case "listusers"
				{
					if ($groupcommands[1] ne "")
					{
						my @groupusers = core::groupmanager::getGroupUsers($groupcommands[1]);
						if ($#groupusers < 0)
						{
							connection::chatconnection::sendMessage("This group has no users");
						} else
						{
							connection::chatconnection::sendMessage(join(", ", @groupusers));
						}
					} else
					{
						connection::chatconnection::sendMessage("Usage: !groups listusers [groupname]");
					}
				}
				else
				{
					connection::chatconnection::sendMessage("Available subcommands: add, delete, list, addprivilege, deleteprivilege, listprivileges, adduser, deleteuser, listusers");
				}

			}
		}
	}
	
	return 1;
}

1;
