#** @file semaphore.pm
# @brief Global semaphore for making the threads work together properly.
#
#*
package core::semaphore;


use Thread::Semaphore;

our $coreSemaphore =  Thread::Semaphore->new();

1;
