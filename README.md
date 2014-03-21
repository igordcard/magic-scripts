Magic Scripts
=============

Some magic ~~tricks~~ scripts to help me overcome the day.

connectedto
---
This bash script checks if the host computer is connected to a network whose address includes a part that is specified by an argument.

srv
---
This bash script makes it easy to give the same command to a set of (Upstart) services sharing the same string prefix.
Currently supports Ubuntu 12.04 LTS onwards, at least.

wundermail
---
This bash script makes it possible to batch add any number of tasks straight into Wunderlist (there is no native way to batch add tasks in Wunderlist, yet: http://support.wunderlist.com/customer/portal/questions/750794-batch-add-tasks). The way this is possible is by using the "Mail to Wunderlist" feature (https://www.wunderlist.com/blog/mail-to-wunderlist/) but in an automatic way so as to send 1 email per each line of a text file. The script comes ready for Gmail accounts only. If you use another email provider, please hack the script and change the $smtp_addr and $smtp_port variables. Depending on the provider you may also need to change something else. Any issue just contact me. This script requires mailx (http://en.wikipedia.org/wiki/Mailx) to be installed.

After some testing it seems wundermail works better if no sync is carried out while the process is ongoing. So, close any Wunderlist instance and then wait at least 2 minutes after wundermail has finished. The Wunderlist mail feature is very sensitive. Also, I've added a delay of 10 second between each task because it seems Wunderlist throttles the amount of mails accepted per unit of time when they become too frequent.
