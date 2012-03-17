README -  w98podfetch
v0.60 2005-11-04, Ian Douglas
ian.douglas@iandouglas.com, iandouglas736@gmail.com

#[[[ TABLE OF CONTENTS
- Introduction
- Contact/Support/Requests
- Requirements
- Installation
- Run-Time Options
- Configuration
- Logging
- Future Plans
- Known Bugs
- Thanks

Note: I use 'vim' pretty much exclusively for all of my programming needs.
'vim' has a great feature to collapse sections of a document, and I use
markers made up of three left-square-brackets and three right-square-brackets
('[' and ']' respectively). You'll see them here in this document as well as
the script itself to help me organize and collapse areas of what I'm working
on. They can be safely removed if they're too annoying for you.

#]]]
#[[[ INTRODUCTION:
This script is released as freeware to use/modify/copy/distribute any way you
like as long as you give credit where it's due and understand that I provide
absolutely NO warranty or guarantee whatsoever regarding this script or its
use. This script is offered free of charge, and may not be sold for profit
under any circumstances whatsoever.

w98podfetch is a two-piece software/service bundle.

The Perl script, w98podfetch.pl, is a podcast 'aggregator', which means it
will check podcast subscriptions and download new published files for you. It
does this using an XML-based configuration file which describes disk path
information for where to put downloaded files, log files, and which podcasts
you want to subscribe to. Written in Perl, it should work fine on any
operating system that can interpret and run Perl scripts, including Windows,
although no Windows testing has been done.

'w98podfetch online' is a web site at http://w98podfetch.w98.us/ (or
http://w98.us/w98podfetch/) which I set up with the initial intent of just
being a place where you could type in some values and it would generate a
configuration file to save to your system. It expanded into a service which
will store podcast information as well as let you build a list of your
favorite podcasts and in conjunction with the Perl script, allow you to share
that podcast list with other friends. For example, you could set up a list of
your favorite technical podcasts and save it as 'technews', then your friends
or coworkers could also use the Perl script to download that same list of
podcasts.

This README file mostly describes the Perl script and how to manually build
the XML configuration file or to use the online service to download podcast
lists on the fly.
#]]]
#[[[ CONTACT/SUPPORT/REQUESTS:
If you use w98podfetch, I'd love to hear from you, drop me a line at
w98podfetch@gmail.com and include your city, state and country.

The web site has links to SourceForge where I have a public CVS repository set
up, and also for forums and bug tracking as well as feature requests. You can
feel free to Email them to me as well, but I'd prefer using SourceForge for
the time being.

If you care to donate to me via PayPal for the script (NOT mandatory, this
script will always be free to use), contact me for my PayPal info.

If you send me an Email for help using the script, please include a valid
return Email address, which version of the script you downloaded, any changes
you've made to it, attach your complete configuration file, and let me know
what errors (if any) you see on your screen. I may ask you to send me a copy
of the script. I will provide *minimal* support where requested but if support
issues become excessive, I may ask for a PayPal donation to cover my time.

#]]]
#[[[ REQUIREMENTS:
I've written and tested this script pretty much exclusively under Linux, and
have had some documentation sent to me on how to run w98podfetch as a service
in Windows, which I've included here.

What you'll need are the following:

Perl 5.6 or better, usually installed with common Linux distributions
www.perl.com

unix2dos
This is used to convert m3u files from Unix format to DOS format so MP3
players understand them properly.

The following Perl libraries:
- XML::Simple
- Getopt::Long
- HTTP::Request::Common
- LWP::UserAgent
- Date::Manip
- String::Scanf

You can use Perl's CPAN interface or 'ppm' for ActivePerl to download these
libraries.

How and where to find these and successfully install them are beyond the scope
of this document or my ability to support but if you're really stuck, send me
an Email.

I received an Email from 'Mike' at my gmail account that he was able to get
w98podfetch working in a Windows environment:

	I'm using it under Windows 2000 running every day in the Task Scheduler.
	I have installed ActivePerl. Downloaded additional perl modules. Set the 
	environment variable TZ to EST: "SET TZ=EST". And got it working in "per 
	podcast" mode.'

Mike also suggested some changes, and I fixed a bug so it would run on 
Windows in "date-today" mode where a new folder would be generated for 
every date you start running the script.

If anyone else manages to get this script working under a non-Linux environment
using these Perl libraries, please drop me a line at the Email address at the
top of this README file and I'll be sure to include a note in future
releases.

#]]]
#[[[ INSTALLATION:
You can save this script wherever you have permission to write files. If
you're working in a Linux/Unix environment, you will need to make the script
executable using the 'chmod' utility, usually something like this will do:

	chmod +x w98podfetch.pl
	or
	chmor 775 w98podfetch.pl

The beauty of being written as a command-line tool is that the script could be
run by 'cron' (a background task scheduler on Linux/Unix) or run manually.

The software will search for a configuration file and fail if it doesn't find
anything. Currently, it looks for files in this order:

~/.w98podfetch/config.xml
This would be a directory named '.w98podfetch' (notice the dot at the
beginning) in your home folder, and the config.xml file copied inside there.
This will allow each user on the system to use a personalized confguration
file.

/etc/w98podfetch.xml
This would be more of a 'global' place to put it if you didn't want to clutter
up your home folder with hidden-dotted directories. Every user on your system
will use this file if they don't have a the config file mentioned above.

/opt/w98podfetch/config.xml
This conforms to a better representation of a global configuration for your
system, if you're the only one on the system.

Note that I have NO idea where I'd tell the script to find a configuration
file under a non-Linux/non-Unix operating system, so you can use the --config
command-line switch to indicate where you want the software to find your
configuration.

Copy the config.xml.sample file to one of the three locations listed above, or
you can use the --config command line switch to point to a different location.
For example, if you copy config.xml.sample to /tmp/podcast.xml then you would
run the script as:
	/path/to/w98podfetch.pl --config=/tmp/podcast.xml

#]]]
#[[[ RUN-TIME OPTIONS
w98podfetch has a number of command line switches that you can use that will
modify how the script operates. Some switches require extra information, some
just set internal flags.

--verbose
	This switch will turn on extra output to your terminal/console and provide a
	lot of extra detail you wouldn't otherwise see. When submitting a bug
	report, I may ask you to do a 'verbose' output and send the text to me in an
	Email for debugging.
	This can also be written as a shortened command: -v

--config
	As mentioned above, the --config setting indicates to the script where to
	find your configuration file. The option requires an extra string of
	information, which is either a disk path to the configuration file on your
	system, or the name of a preconfigured podcast list on the 'online' service.
	To use the 'online' service, you must also include the --email option.
	The shortened version of this command is -c

--email
	To use the 'online' version of w98podfetch, where podcast lists can be
	downloaded on-the-fly, you must register a (free) account at the web site
	(http://w98podfetch.w98.us/) and use this option to pass the Email address
	as an extra string of information.
	The shortened version of this command is -e

--listpasswd
	Some users on the 'online' service will generate a 'private' list of
	podcasts, and have the option of password-protecting the list. In this case,
	you will be notified that the list you're trying to download with the
	--config option requires a password, so you must use the --listpasswd option
	to pass that string to the 'online' server.
	The shortened version of this command is -l

--help
	This command simply prints a simple help screen to the terminal/console to
	give you a brief recap of this information.

-- debug
	This will output LOTS of debugging information. Use it with the --verbose
	command.

--onepodcast=feedname
	This will let you download a single podcast feed, by passing a case-
	insensitive feedname from the configuration.

Note that the --config, --email, and --listpasswd commands all use an equal
sign when used in long form (--config=/path/to/file) but do NOT use an equal
sign when used in the shortened form (-c /path/to/file). You can also mix and
match when to use the long option name or the short option name, the script is
smart enough to figure out what you mean.


Examples:

1. You have a config.xml file in a folder called .w98podfetch in your home
directory (one of the default paths), and you just want to run the script
using that configuration:

	w98podfetch.pl

2. You have downloaded or built a configuration script called "blah.xml" in
your /tmp/ folder, and want to use that configuration in verbose mode:

	w98podfetch.pl --config=/tmp/blah.xml
	or
	w98podfetch.pl -c /tmp/blah.xml

3. You have registered for a free account with the 'online' service, and want
to download a configuration for Scott Sigler's podcast novels called
'scottsigler' (an actual public list on the 'online' service that I personally
created. Assume that your Email address is joesmith@gmail.com and that there
is no list password:

	w98podfetch.pl --email=joesmith@gmail.com --config=scottsigler
	or
	w98podfetch.pl -e joesmith@gmail.com -c scottsigler

4. You have registered as joesmith@gmail.com, and want to download an online
podcast list called 'linuxgeek' that has a list password of 'penguin' and want
to run in verbose mode:

	w98podfetch.pl -e joesmith@gmail.com -c linuxgeek --listpasswd=penguin -v
	or
	w98podfetch.pl -e joesmith@gmail.com -c linuxgeek -l penguinjunkie -v

5. If you have a podcast with a feedname of "mypodcast" and want to download
ONLY that podcast like this:

	w98podfetch.pl --onepodcast=mypodcast
	or
	w98podfetch.pl -o mypodcast

#]]]
#[[[ CONFIGURATION:
In order to have w98podfetch.pl execute correctly, it needs to have an XML
configuration file indicating things like disk paths.

It's a little beyond the scope of this documentation to teach new users how to
write proper XML, so if you have difficulty reading the rest of the
Configuration documentation, I recommend that you sign up (for free) at the
'online' service at http://w98podfetch.w98.us/ ... there, you can simply type
in the disk paths of where you want your files stored, and then when you're
ready to run the script, just pass the registered Email address to the --email
option and set the --config option to the podcast list you want to download.
And because you're a registered user, if you find another list you want too,
just rerun the application with the other list name(s), and your registration
details will automatically be sent to w98podfetch.pl for each podcast list.

The heart of w98podfetch.pl is a well-built configuration file. A single syntax
error in the config file can ruin your experience, and I'm already envisioning
supporting people who don't understand XML, but that's the hole I've dug for
myself and why I've created the 'online' interface.

To get started, use the config.xml.sample file as a basis for what you want to
do. Most people will simply need to change the disk paths at the beginning of
the file, and copy-and-paste the the <feed></feed> blocks for new
subscriptions and modify the internal pieces.

I'LL MENTION IT AGAIN: if you're not familiar with writing XML, it's probably
best if you register for the 'online' service and use the files it produces
for you. It will save you a lot of grief, and will save me some time from
having to explain how to write XML.

If you're really a do-it-yourself type of person, you can read more about
writing XML at various web sites out there. Simply google for "how to write
XML" and you'll see sites like this that look pretty good:
http://www.c-sharpcorner.com/LearnXML/XMLSyntaxes.asp
Note: I do not necessarily endorse that site or its content, it's just offered
as an example of an XML tutorial.
There are PLENTY of books out there on how to write XML, such as the "XML
Bible" found at http://www.ibiblio.org/xml/books/bible/

Back to the configuration:

There are two portions of the configuration file, the 'base' configuration and
a series of 'feed' configurations. I'm explaining everything in this file so I
don't clutter up the configuration file with a bunch of message <!-- -->
comment markers (which still need to get parsed by the script).

#[[[ Base Configuration
-----
Everything NOT in the <subscriptions></subscriptions> block is used for
running the script. Generally speaking, you should only need to change a few
disk paths for where you want the podcasts downloaded to, and the application
will default to taking care of a lot of other details on your behalf.

#[[[ <basedir></basedir>
This is the base directory for where you want your podcasts to be downloaded
to. You must have read and write permissions on this folder. THE SCRIPT WILL
NOT OPERATE IF THIS OPTION IS NOT SET! This folder name should be written as
/home/joe or /home/joe/ - I have not tested the script with relative paths 
like "../joe" so don't bug me for support if you try it and the script fails.
	Example:
		<basedir>/home/joe/</basedir>

#]]]
#[[[ <makefolders></makefolders>
'makefolders' instructs the application how to build folders within 'basedir'
for each podcast file that gets downloaded. Personally, I find it easier to
sort my podcasts into grouped folders, but wanted to give everyone the
flexibility of their own taste. BashPodder, which influenced this application,
built a new folder every day that their script was run and all podcast files
downloaded that day were placed into that single folder.
I give three options for how to create folders: create a folder based on the
podcast feed configuration ('per podcast'), build a single folder for the day
the application is run and put all files in that folder ('date-today') or to
create a new folder based on the publication date of every podcast file
('date-all'). NOTE: the 'date-all' option has not been tested, but *should*
work okay, but has the potential of generating a LOT of folders. I may drop
this third feature ('date-all') completely as I see less and less use for it
now that I've built in m3u generation.

Any folders created will be appended to 'basedir'

	'per podcast' will make a folder for each podcast using its 'foldername'
	attribute and put each downloaded file into that respective folder and 
	is the default option if 'makefolders' is not set at all.
	example: (these three examples are treated equal to 'per podcast')
	<makefolders>per podcast</makefolders>
	<makefolders></makefolders>
	<makefolders />

	'date-today' will make a folder with today's date and download all files
	into that folder.
	example:
	<makefolders>date-today</makefolders>

	'date-all' will make a folder for every publication date of every downloaded file
	For example, if 'basedir' is set to '/home/joe/', and 'makefolders' is set
	to 'date-today', a folder will be created every day this script is run, and
	will create a folder such as '/home/joe/2005-10-20/' when run on October 20,
	2005.
	example:
	<makefolders>date-all</makefolders>

#]]]
#[[[ <download order="" limit="" />
This tagset determines which order to fetch podcast files ('newest' or
'oldest' first) and if/when to halt any podcast fetching based on a limitation
imposed.

The 'order' attribute is either 'newest' or 'oldest' and will check the
'pubDate' tag for each item or enclosure in the podcast feed to determine
which order to actually download the files. If the feed does not have any
pubDate listed in the <item> heirarchy at all, today's date is injected and
the oldest/newest flag is ignored for that feed.

The 'limit' attribute sets a preset limitation for any podcasts that do not
already set their own limitation. For example, if the base configuration
'limit' is set to '3 files', each time the application is run, each podcast
feed will attempt to download 3 files assuming 3 files are available. This
assumes that none of your podcast feeds override the limit.

There are two types of limitations you can set: file count, or byte count.

If your 'limit' specifies a number of files to download ("1 file", "3 files"
etc), each podcast you are subscribed to will attempt to download that
quantity of files each time the application is executed. For example, if you
want each podcast to download a maximum of 2 files, regardless of file size,
you would set limit="2 files" as the attribute. The application logic will
determine the difference between singular and plural grammar, such as "1 file"
or "2 files".

If you would rather halt a podcast from downloading a huge amount of data, you
can halt a download before fetching a specific quantity of bytes (useful if
your bandwidth is slow). The byte count will recognize the common file sizes
of "KB", "MB" or "GB". Using "KB" likely won't be very useful, since most
podcast files in my experience so far are much larger than a kilobyte setting
would allow unless your subscription is for podcast files shorter than about a
minute each. For example, you could set the limit like limit="50 MB" - this
would tell the application to stop downloading files from a subscription from
downloading any more files if the 'next' file to download would exceed a total
of 50MB of data from that subscription. The application will check ahead for
the next file to download, and if it will exceed this byte count, that file
will *not* be downloaded. The logic of the application will determine the
difference between "50MB" and "50 MB" as being a 50-megabyte download cap.

If you want to just download EVERY available podcast file for every
subscription feed, you can set the limit attribute to 'all', 'unlimited' or
leave it blank.

Example: impose a global setting for each podcast where oldest files should be
downloaded first and that the application should attempt to download a maximum
of 2 files per subscription:
	<download order="oldest" limit="2 files">

Example: impose a global setting for each podcast where newest files should be
downloaded first and that the application should stop downloading files if the
next file fetched would exceed 25MB for this feed:
	<download order="oldest" limit="25 MB">

Example: impose a global setting for each podcast where newest files should be
downloaded first, and that the application should attempt to download every
file available in a subscription: (all three lines are the equivalent of
downloading all files)
	<download order="oldest" limit="all" />
	<download order="oldest" limit="unlimited" />
	<download order="oldest" limit="" />

PLEASE NOTE: the 'limit' attribute of the base configuration is not a
cumulative limitation. I do have a future plan of a total cumulative download
cap where you could specify "10 files" and the application will stop running
once 10 total files have been downloaded from all of the podcasts.

#]]]
#[[[<m3upath></m3upath>
If <makefolders> is set to "per podcast", an M3U playlist will be created
inside the folder setting in <basedir> named as "podcast-YYYY-MM-DD.m3u". The
'm3upath' tag is a non-relative path which your MP3 player will use to start
getting at podcast downloads that will be written as a standard M3U playlist
file. For example, I mount my iRiver H320 as /usb/podcast on my linux
workstation which means that I download my files into folders like
/usb/podcast/Music and /usb/podcast/Tech and /usb/podcast/News  However, my
iRiver cannot understand the 'usb' portion of the filename, therefore its
'base' directory is only '/podcast/', so I can set that value here.

If you are using a program like XMMS or WinAmp, you can probably set 'm3upath'
to the same path as 'basedir'.

Note as well that standard M3U playlists will use a backslash '\' character

using the '/' character. The application will convert all '/' characters in
the filename to '\' when writing to the M3U playlist file. Also, the standard
file format is to use DOS-compatible carriage returns and line feeds, so the
utility 'unix2dos' is used to convert the file.

The M3U file is written to after every individual file download, so if an
error occurs or you manually stop the application from running, the M3U file
will contain the last files you downloaded.

The application will also re-open the M3U file created 'today' and keep
appending podcast files to that same file. So if you run the application at
7am and download 10 files, and run it again at 5pm and download another 15
files, all 25 files will be in the same M3U file.

#]]]
#[[[ <cutoffdate>YYYY-MM-DD</cutoffdate>
If 'cutoffdate' contains a valid date string (preferably in YYYY-MM-DD format,
but really, any date string that can be parsed by the Date::Manip library
function "ParseDateString" will work including cool things like:
YYYYMMDDHHMNSS 
YYYYMMDDHHMNSS 
YYYYMMDDHHMN 
YYYYMMDDHH 
YY-MMDDHHMNSS
YY-MMDDHHMN
YY-MMDDHH
YYYYMMDD
YYYYMM
YYYY
YY-MMDD
etc, with or without dashes, it does its best to figure it all out. However,
the Date::Manip library is even cooler in that it will figure out "today's"
date, and let you use relative strings like this:
"last Friday"
"2 weeks ago Friday"
"last day of September"
"first Sunday in June 2004"
... check the 'man' page on Date::Manip for ParseDateString to see exactly how
it all works, but I personally recommend setting the date string to YYYY-MM-DD
format for simplicity.
In verbose mode (use the --verbose or -v command line option) you sill get a
printout of which url's are too old and thus skipped)

#]]]
#]]]
#[[[ Subscription Configuration
This is where you define each podcast subscription. The XML block between
which you define every feed is named <subscription></subscription>. Each
individual podcast feed is encapsulated between <feed></feed> tags.
Essentially, this portion of your XML file looks like this:
<subscriptions>
	<feed feedname="" url="">
		...
	</feed>
	<feed feedname="" url="">
		...
	</feed>
</subscriptions>

Notice that the 'subscriptions' tag set contains everything else in between.
Likewise, the 'feed' tag set will contain (encapsulate) everything else in
between as well.

#[[[ <feed feedname="" foldername="" url="">
Each feed is defined with the following attributes:

"feedname"
This is a unique name that will be used to create a separate folder for
downloading new podcasts for this feed. It will be appended to 'basedir' from
the basic configuration and should not contain relative links. For example, if
'basedir' is set to '/home/joe/' and 'foldername' for this feed is set to
'diggnation', the script will create '/home/joe/diggnation' and will place new
podcast files inside that folder. Note that this feature is only used if
'folders' from the base configuration is set to 'per podcast'. This value will
also store the string into $name for use with 'newformat', as decribed below.
Note that duplicating the 'name' attribute for any podcast will result in the
script overwriting any previous definitions with whatever is found later in
the config file.

"foldername"
The foldername is used to write podcast downloads into a foldername which is
created as part of 'basedir' (defined in the Base Configuration). The
foldername value does not have to be unique. For example, if you download a
number of podcasts that are technology related, you can set your foldername
value to 'Tech' for all of those podcasts, and all of the files from those
podcast subscriptions will be written into the same folder. Note that this
attribute is ONLY used if 'makefolders' in the Base Configuration is set to
'per podcast'.

"url"
This is a string value containing the fully-qualified url of the xml
subscription RSS or XML feed to parse. This URL must point to a valid XML compliant
i(preferably iTunes compatible) subscription feed, no exceptions.

	Example:
		<feed ... url="http://mdattilo.audioblog.com/rss/tih.xml">
Keep in mind that because the configuration file is written in XML and parsed
using XML::Simple, you may need to tweak your subscription feed if it contains
special characters. The feed name *must* conform to XML standards. For
example, a feed like this:
	http://www.blah.com/feed/podcast.xml?a=123&b=234
... would be invalid, because '&' is a reserved character in XML. You would
have to tweak the URL to replace '&' with '&amp;' like this:
	http://www.blah.com/feed/podcast.xml?a=123&amp;b=234
This is fairly uncommon in the podcasts feeds I'm seeing so far, but it was
worth mentioning just in case.

Note: to ensure proper directory naming across all platforms, I currently
strip all whitespace, and non-numeric and non-alphabetic characters from the
'feedname' value. For example, "Music News" would be renamed to "MusicNews"
and "Tech Update @ 10pm" would be renamed to "TechUpdate10pm".

#]]]
#[[[ <rename oldformat="" newformat="" />
The application will examine 'oldformat' and 'newformat' to determine whether
to change the name of a file after it has been downloaded. If you find that
podcast files are named things like "show4.mp3" or "05-2005-10-27.mp3" which
are pretty ambiguous at first glance, you may consider using the renaming
feature of the application to make the filenames more friendly.

If 'oldformat' is not empty, 'newformat' must not be empty. Likewise, if
'oldformat' is empty, 'newformat' is ignored.

'oldformat' will allow you to strip out known items from the filename in order
to rename the file. This is done by using printf/scanf elements, such as '%s'
for strings, and '%d' for numbers to extract the elements from the old
filename. Once elements are extracted, 'newformat' will plug those pieces back
into a new filename using $1 for the first element extracted, $2 for the
second element, and so on in left-to-right order. Note that you don't *need*
to use any extracted piece, it's simply there to pull known data out of a
filename.

I built in some reserved 'newformat' tags to use:
	$name
	this value gets filled in using the 'feedname' attribute from the <feed> tag

	$date
	this value gets filled in with 'YYYY-MM-DD' of the publication date of the
	donwloaded file; if a pubDate element isn't found in the subscription feed,
	today's date is used instead.

	$datetime
	this value gets filled in as above but as 'YYYY-MM-DD HHMM' to include the
	24-hour clock time of the publication - handy if a podcast has multiple
	files published on the same day.

	$ext
	this calue is filled in with the file extension of the original downloaded
	file. I didn't want to assume that every podcast feed uses MP3 files, so
	this will let you download MP3's, OGG's, torrents, PDF files, etc. without
	worrying about renaming the file and messing up the file extension.

	Example:
		This 'tech geek' podcast always names their file show1.mp3, show2.mp3,
		show3.mp3, etc. and we want to rename it to something easier to
		understand:
		<feed feedname="TechGeek" foldername="Tech" url="http://blah.com/rss">
			<rename oldformat="show%d.mp3" newformat="$name-show $1.mp3" />
			<download order="newest" limit="">
		</feed>
		This will help the script to strip the numeric value out of the filename
		by using the '%d' marker, and fills in that number into the $1 value in
		the 'newformat' attribute. This example assumes that every podcast file
		from this feed is an MP3 file. The new filename will look something like
		"TechGeek-show 3.mp3"
		This example will also move all downloaded files into a folder called
		'Tech' and will use the global download limits from the base
		configuration.

	Example:
		This 'money news' podcast always names their files like
		"10-18-2005-Episode12-InterviewWithJoeTaxman.mp3" or
		"10-19-2005-Episode13-UsefulInvestingInfo.pdf" and we want to make the
		files easier to understand at a glance:
		<feed feedname="MoneyNews" foldername="Finances" url="http://money.org/rss">
		  <rename oldformat="%d-%d-%d-Episode%d-%s.%s" newformat="$name-$date,$4.$ext" />
		</feed>
		This will help the script to strip the date into individual pieces, 
		episode number, and subsequent string description, as well as the file
		extension. The new filename would look something like
		"MoneyNews-2005-10-17,InterviewWithJowTaxman.mp3" or
		"MoneyNews-2005-10-18,UsefulInvestingInfo.pdf"
		Note that in this example, we could have used $6 for the file extension,
		but we used the reserved $ext value instead.

Note that the oldformat string can simply be "%s" if you want to prefix the
filename with the feedname or publication date of the file. For example, if a
podcast has a nicely formatted filename of "Episode 18.mp3" and you simply
want to prefix the filename with the name of the podcast, you could use
something like this:
	<feed feedname="New Music" foldername="Music" url="http://music.net/podcast">
	  <rename oldformat="%s" newformat="$name, $1" />
This will take the *entire* filename, including the file extension, and use it
as $1 in the newformat string. We prefix the filename, then, with the
feedname, so the new filename would look like "NewMusic, Episode 18.mp3"

#]]]
#[[[ <download order="" limit="" skipold="" />
The 'order' attribute works the same was as the base configuration, and is
given here as an override for each individual feed. For example, the base configuration
may be set so the 'order' is 'newest' (which makes sense, you typically want to download
newer podcasts), but maybe a feed you want to add is a podcast novel, and you want
to download older files (earlier chapters) first. Remember, if no publication
date is given for a podcast file, today's date is used as the publication
date, and that could mess up the ordering of the files when sorting in
oldest/newest modes.
	Example
		<download order="oldest" ... />

The 'limit' attribute works just like the base configuration limit flag.
However, in this case, you could leave the 'base' configuration to a blank
string (unlimited mode), but place a limit on this particular feed, to only
get a single file by setting this feed's limit value to limit="1 file". The
logic of the application will detect the grammar difference between "1 file"
and "2 files" (plural), and can also contain common disk sizes like "MB" for
megabyte just as the base configuration is used. The opposite works too: if
your base configuration is set to only download one new file each time the
application is run, but you know that this podcast contains many small files
to download, you could set this feed to limit="unlimited" to download all
available podcasts for this feed only.

The 'skipold' feature will pay attention to whether 'cutoffdate' is set in the
base configuration. If the base configuration is set to, say "2005-10-01"
(October 1st, 2005), then this flag will determine whether to skip any files
in the data feed that have a publication date (pubDate) older than that date
and whether or not to skip that older file.
For example, you could set 'cutoffdate' to "last Saturday" so only new
podcasts this week will get downloaded. But say you just added a new
subscription, and you *want* to get a backlog of podcasts - simply set
"skipold" to "no" and the application will fetch older files for you.

#]]]
#]]]
#]]]
#[[[ LOGGING
A log file for each podcast feed is kept in the destination folder when
running with the base configuration of makefolders="per podcast".

The application, because of the renaming features, will look at both a log of
URL's it has previously downloaded as well as existing filenames (in case the
files have NOT been renamed) to determine whether a file has already been
downloaded so it is not downloaded again and again every time you run the
application.

If a file is skipped, it is not counted toward the 'limit' set - the file
counter will be decreased by one, and the byte size of the file is not added
to the running total for accurate processing.

For example, if a podcast feed has a limit of "3 files", and the first file in
the podcast was downloaded previously, that first file will not count towards
the limit of three files, and the next three files will be fetched.

If your base configuration builds a date-related filename (date-today or
date-all), no log file will be stored, and no file detection will be done.
This is a current limitation on the application that I hope to fix at some
point in the future.

#]]]
#[[[ FUTURE PLANS
Future plans, feature requests, etc., can be found at http://iandouglas.com
Feel free to submit feature requests in the forums or Mantis bug tracker at my
site.

More command-line options
I'd love a cmdline option for just checking the configuration file for
completeness, and maybe checking that each podcast URL is valid (and
downloadable)

#]]]
#[[[ KNOWN BUGS
No software is perfect. If you find a bug, or more importantly a podcast feed
that doesn't work with the software, PLEASE submit a bug report through the
w98podfetch web site.

#]]]
#[[[ THANKS
Thanks to my wife for putting up with my geek tendancies which flare up from
time to time unexpectedly and I spend hours and hours working on something
like this.

Thanks to my buddy Jorge (jorgev.com) for getting me hooked on In-n-Out
burgers, yellowtail, and podcasts. And Everquest, and World of Warcraft, and
trips to San Diego, and geeking out, and ...

Thanks to those at http://mantis.iandouglas.com/ who are submitting bugs and
ideas to make the script better.

And, speaking of giving credit where it's due:

This script was a major rewrite of bashpodder which is a bash shell script
found at http://bashpodder.sourceforge.net/
When I saw the limitations of bashpodder and the flexibility I knew I could
write into it, I decided to write a similar script from scratch using Perl to
download and manage my podcast collection.
Credit and kudos to the guys that wrote that script, and to some of their
contributors from whom I've borrowed ideas. Thanks for making your application
open-source and free to download.

#]]]
