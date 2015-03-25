camelbot
========

Perl based modular twitch/irc bot

The idea for this project is to make a lightweight chatbot, initially focused on twitch chat, where all plugins defining the behaviour(so not the plugin for the chat connection) are dynamically (re)loadable.

Notes on multithreading:
There are 2 semaphores at the moment one for the chat connection and one general semaphore; when one of the semaphores is locked no function may be called that locks the other one.
This means in practice calling these functions should be done to prepare data or to process prepared data.


Requirements:
* The core can accept different connection modules, but only one at a time.
  * This connection module does not need to be reloadable
* Plugins are loadable on runtime
  * It's possible to reload all plugins at once
  * It's possible to unload plugins
* There's an internal group management for extending privilege management
  * There are builtin commands for the group management
  * Only the group "superuser" is able to manage users and groups
  * a list of all users with groups(internal and external) can be 
  * the group management works with an SQLite database
retrieved by plugins
* a list of regular expressions is managed to trigger plugin functions
  * Plugin functions triggered by a regex get a readily parsed message pushed to them
    * This message contains:
      * Unparsed text
      * username
      * a list of all user privileges and internally managed groups it belongs to
      * an array which will contain any text parsed by the regex
    * The triggers can have a cooldown time
* Plugins can add new interfaces that can be used by other plugins
* All settings are saved in xml format
* Twitch regularly derps out revoking all mod rights and reinstating them a few moments later; camelbot  must handle this strange behaviour properly, preferably without the temporary mod outage
* The twitch api connection shall have 2 parts
  * a normal(mod privilege) part
  * an optional elevated privilege (caster) part(will contain dedicated one-way irc client, simply for sending commands)

Nice to have:
* Plugin that generates visitor graphs
* A SOAP API so external interface applications can connect to it
* A russian roulette(with bans/timeouts) plugin


===========
= Roadmap =
===========

The plans are roughly this; no dates, it is done when it is done.

* ver 0.1(alpha)
All components are connected and roughly tested

* ver 0.2(beta)
Complete Doxygen comment coverage and unit test coverage on all critical modules.
There's a doxygen release available 
This version will be ready for advanced end users to run.

* ver 0.3-0.9(release candidates)
Bug fixing and adding new plugins.

* ver 1.0(release)
The bot framework meets all requirements except for GUI and SOAP.
A Windows installer is released with activeperl built in.

* ver 1.1(alpha)
A SOAP interface has been implemented and a basic C# GUI application has been designed.

* ver 1.2(beta)
N-unit testcases have been added to the C# application for testing the SOAP interface.
This version will be ready for advanced end users to run.

* ver 1.3-1.9(release candidates)
Bug fixing and refining the C# GUI application, completing the functionality.
All command-line functionality must be available in the GUI as well.

* ver 2.0(release)
The bot framework meets all requirements.
A windows installer is released with activeperl built in.
A "golden" build of Doxygen is available
