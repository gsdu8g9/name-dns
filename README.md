## What? ##

A DNS syncing daemon for name.com DNS. You know you need it when you are running your own server on dynamic IP.
Whenever your ISP give you a new IP, you need to login to name.com and update your DNS record. This small tool
automate that pain process for you. It automatically syncs the current IP to all defined DNS entry.

## How? ##

  * You can set cron job to run "ruby named.rb" directly
  * Or start it via systemd. a named.serviced file is given for this purpose. You may need to correct the path and some minor customizing.
	
## Who?	##
  * kureikain
  * And you.

## Thanks ##

systemd script file is taken and modified from MongoDB package of Arch Linux.
