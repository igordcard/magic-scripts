Magic Scripts
=============

Some magic ~~tricks~~ scripts to help us overcome the day.

install_from_source-proxy.sh
---
OSM deployment script, corrected to work behind a proxy.

irssi/shell_notify.pl
---
Notify your shell when messages are received in IRC (irssi), works fine over SSH using Cygwin on Windows, as an example.

irssi/email_msgs.pl
---
Email you when IRC messages are received (or even sent) in irssi, including mentions. Very configurable with multiple options.

gbt.sh
---
gerrit backup tool.

install-xrdp-1-8-1.sh
---
Modified version of Griffon's xrdp 0.9 script for Ubuntu 16.04, originally available at http://c-nergy.be/blog/?p=10513.

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

dropbox
---
Bash completion for the dropbox.py command. It auto-completes command's switches, including the puburl using $HOME/Dropbox/Public folder.

vboxheadless
---
Bash completion for the vboxheadless command. Auto-completes command's switches, including VMs names when trying to start them.

