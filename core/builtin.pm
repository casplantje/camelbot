#** @file builtin.pm
# @brief module containing handlers for builtin functions
#*
package core::builtin;

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
	return 1;
}
