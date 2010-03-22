#!/usr/bin/perl

# DSPAM
# COPYRIGHT (C) 2002-2006 JONATHAN A. ZDZIARSKI
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; version 2
# of the License.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.


# This configuration file is read by all the CGI scripts to configure both the
# environment that DSPAM is working in and the way it will display information
# to the web user.

# Default DSPAM enviroment
$CONFIG{'DSPAM_HOME'}	= "/var/spool/dspam";
$CONFIG{'DSPAM_BIN'}	= "/usr/bin";

$CONFIG{'PASSWD_FILE'} = "/etc/bearmail/mailmap";
$CONFIG{'DSPAM_STATS'} = "/etc/dspam/dspam_stats_wrapper.pl";

$CONFIG{'DSPAM'}	= $CONFIG{'DSPAM_BIN'} . "/dspam";
#$CONFIG{'DSPAM_STATS'}	= $CONFIG{'DSPAM_BIN'} . "/dspam_stats";
$CONFIG{'DSPAM_ARGS'}	= "--deliver=innocent --class=innocent " .
                          "--source=error --user %CURRENT_USER% -d %u";
$CONFIG{'TEMPLATES'}	= "/var/www/bearmail/antispam/dspam-templates";	# Location of HTML templates
$CONFIG{'ALL_PROCS'}	= "ps auxw";		# use ps -deaf for Solaris
$CONFIG{'MAIL_QUEUE'}   = "mailq | grep '^[0-9,A-F]' | wc -l";

$CONFIG{'WEB_ROOT'}     = "./"; # URL location of included htdocs/ files

# Default DSPAM display
#$CONFIG{'DATE_FORMAT'}  = "%d.%m.%Y %H:%M"; # Date format in strftime style
					     # if undefined use default DSPAM display format
$CONFIG{'HISTORY_SIZE'} = 6000;		# Number of items in history
$CONFIG{'HISTORY_PER_PAGE'} = 200;
$CONFIG{'HISTORY_DUPLICATES'} = "yes";	# Wether to show duplicate entries in history "yes" or "no"
$CONFIG{'MAX_COL_LEN'}	= 50;		# Max chars in list columns
$CONFIG{'SORT_DEFAULT'}	= "Date";	# Show quarantine by "Date" or "Rating"
$CONFIG{'3D_GRAPHS'}	= 1;
$CONFIG{'OPTMODE'}	= "NONE";	# OUT=OptOut IN=OptIn NONE=not selectable
$CONFIG{'LOCAL_DOMAIN'}	= "";

# Add customized settings below
$CONFIG{'LOCAL_DOMAIN'}	= "";

$ENV{'PATH'} = "$ENV{'PATH'}:$CONFIG{'DSPAM_BIN'}";

# Autodetect filesystem layout and preference options
$CONFIG{'AUTODETECT'} = 0;

# Or, if you're running dspam.cgi as untrusted, it won't be able to auto-detect
# so you will need to specify some features manually:
$CONFIG{'AUTODETECT'} = 0;
#$CONFIG{'LARGE_SCALE'} = 0;
$CONFIG{'DOMAIN_SCALE'} = 1;
$CONFIG{'PREFERENCES_EXTENSION'} = 0;

$CONFIG{'DSPAM_CGI'} = "dspam.cgi";

# Configuration was successful
1;