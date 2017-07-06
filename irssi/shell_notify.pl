# Copyright (c) 2017 Igor Duarte Cardoso <igordcard@gmail.com>

# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:

# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

# Changelog:
# 1.0 - initial release:
#   * scan private and public mentions:
#     - send a notification to the client if a private msg is received;
#     - send a notification to the client if a public mention is received;
#     - send a notification to the client if a certain keyword is
#       detected in public messages.

use strict;
use vars qw($VERSION %IRSSI);

use Irssi;

$VERSION = '1.0';
%IRSSI = (
        authors => 'Igor Duarte Cardoso',
        contact => 'igordcard@gmail.com',
        url => "http://www.igordcard.com",
        name => 'shell_notify',
        description =>
                "Scan private and public mentions. " .
                "Send a notification to the client if a private msg is received. " .
                "Send a notification to the client if a public mention is received. " .
                "Send a notification to the client if a certain keywords i ".
                "detected in public messages.",
        license => 'MIT',
);

# user configurable variables (1->yes; 0->no):
# ##############################################
# whether to look for specific keywords in public messages:
my $look_for_keyword = 1;
# which keyword to look for in public messages:
my $keyword = 'igor';
# TODO: support an array of keywords to look for

sub just_notify {
    system('echo -en "\007"');
}

sub handle_pubmsg {
    my ($server, $message, $user, $address, $target) = @_;
    if (index($message,$server->{nick}) >= 0) {
        just_notify()
    }
    elsif ($look_for_keyword && index($message,$keyword) >= 0) {
        just_notify()
    }
}

sub handle_privmsg {
    just_notify()
}

Irssi::signal_add_last("message public", "handle_pubmsg");
Irssi::signal_add_last("message private", "handle_privmsg");
