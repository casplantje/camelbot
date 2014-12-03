package connection::chatconnection;
# Interface for connection plugins
# TODO: make this interface approach the connection plugin in a
#		universal way

use connection::irc;

sub connect
{
	connection::irc::connect();
}

sub sendMessage
{
	connection::irc::sendText(\@_);
}

1;
