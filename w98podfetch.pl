#!/usr/bin/perl
# w98podfetch.pl
# Ian Douglas
# Free license to use/modoify/copy/distribute this script, just give credit
# where it's due
# PLEASE read the README.txt file ... there's probably very little you'll ever
# need to modify in this file.

use strict ;

my $version = "0.61" ;
$!=1 ; # non-buffered output, suggested by svn bug 0000006

###[[[ LIBRARIES
#use File::Glob ;
use Getopt::Long ;
use HTTP::Request::Common ;
use LWP::UserAgent ;
use XML::Simple ;
use Date::Manip ;
use String::Scanf ;
#tmp:
use Data::Dumper;
#]]]

my %GLOBAL ;
my %cmdopts ;
my @DOWNLOADED_FILES = () ;
my $VERBOSE ;
my $DEBUG ;
my $CONFIGFILE ;
my $M3Upath ;
my $ONEPODCAST ;

my $today = UnixDate("today","%Y-%m-%d") ;
my $ua = LWP::UserAgent->new(ssl_opts => { verify_hostname => 1 }) ;
$ua->agent("w98podfetch/$version") ;

# set to 0 to do everything but actually download the file
$GLOBAL{'active'} = 1 ;

GetOptions (
		"email=s"=>\$cmdopts{'email'},
		"config=s"=>\$cmdopts{'config'},
		"listpasswd=s"=>\$cmdopts{'listpasswd'},
		"onepodcast=s"=>\$cmdopts{'onepodcast'},
		"help:s"=>\$cmdopts{'help'},
		"verbose:s"=>\$cmdopts{'verbose'},
		"debug:s"=>\$cmdopts{'debug'},
		) ;
$DEBUG = defined($cmdopts{'debug'}) ;
$VERBOSE = defined($cmdopts{'verbose'}) ;
$ONEPODCAST = ($cmdopts{'onepodcast'} ? $cmdopts{'onepodcast'} : 0) ;
print &ts()."Starting...\n" if ($DEBUG) ;
if ($ONEPODCAST) {
	print "single podcast mode\n" if ($VERBOSE) ;
}

if (defined($cmdopts{'help'})) {
	Usage() ;
	exit ;
}

if (defined($cmdopts{'email'})) {
	if ($cmdopts{'config'} eq '') {
		Usage() ;
		exit ;
	} else {
		# build lwp request to get the list, check ->content for "password required"
		my $feedurl = 'http://w98.us/w98podfetch/index.php?md=makeconfig&email='.$cmdopts{'email'}.'&list='.$cmdopts{'config'} ;
		if ($cmdopts{'listpasswd'}) {
			$feedurl .= "&passwd=".$cmdopts{'listpasswd'} ;
		}
		print &ts()."connecting to $feedurl\n" if ($VERBOSE) ;
		my $res = $ua->get("$feedurl") ;
		if ($res->is_success) {
			#print "content:\n-----\n".$res->content."\n-----\n" ;
			if ($res->content =~ /requires a password/i) {
				print "***Error: the podcast list '".$cmdopts{'config'}."' requires a password.\n" ;
				exit ;
			} elsif ($res->content =~ /^Unknown user/i) {
				print "***Error: the Email address you've supplied (".$cmdopts{'email'}.") is not a valid user.\n" ;
				exit ;
			} elsif ($res->content =~ /^404/) {
				print "***Error: the podcast list '".$cmdopts{'config'}."' is not a valid list name.\n" ;
				exit ;
			} else {
				$CONFIGFILE = $res->content ;
			}
		} else {
			print "***Error: 'w98podfetch online' service is unavailable\n" ;
			exit ;
		}
	}
} else {
	$CONFIGFILE = ($cmdopts{'config'} ? $cmdopts{'config'} : "other" ) ;

	if ($CONFIGFILE eq "other") {
		if ( -e $ENV{'HOME'}."/.w98podfetch/config.xml") {
			$CONFIGFILE = $ENV{'HOME'}."/.w98podfetch/config.xml" ;
		} elsif ( -e "/etc/w98podfetch.xml") {
			$CONFIGFILE = "/etc/w98podfetch.xml" ;
		} elsif ( -e "/opt/w98podfetch/config.xml") {
			$CONFIGFILE = "/opt/w98podfetch/config.xml" ;
		}
	}
	if ($CONFIGFILE eq "other") {
		print STDERR "***Error: No configuration file found.\n" ;
		print STDERR "Application expects a configuration in one of the following paths:\n" ;
		print STDERR "    ~/.w98podfetch/config.xml\n" ;
		print STDERR "    /etc/w98podfetch.xml\n" ;
		print STDERR "    /opt/w98podfetch/config.xml\n" ;
		print STDERR "or you can use the --config command line option to point to a\n" ;
		print STDERR "configuration file elsewhere on your disk path\n\n" ;
		exit ;
	}
}


my $xml = new XML::Simple;
my $config = $xml->XMLin($CONFIGFILE, ForceArray=>['feed']) ;

$GLOBAL{'basedir'} = $config->{'basedir'} ; #[[[
if (!$GLOBAL{'basedir'}) {
	print STDERR "***Error in base config: 'basedir' value is missing\n" ;
	exit ;
} else {
	$GLOBAL{'basedir'} =~ s/\/$//g ;
} #]]]
$GLOBAL{'logdir'} = $config->{'logdir'} ; #[[[
if (!$GLOBAL{'logdir'}) {
	print STDERR "***Error in base config: 'logdir' value is missing\n" ;
	exit ;
} else {
	$GLOBAL{'logdir'} =~ s/\/$//g ;
} #]]]
#[[[ checking download limits
my @tmp = parse_limit($config->{'download'}->{'limit'},"base") ;
$GLOBAL{'limit_q'} = $tmp[0] ;
$GLOBAL{'limit_t'} = $tmp[1] ;
if ($GLOBAL{'limit_q'} eq "exit" || $GLOBAL{'limit_t'} eq "exit") {
	exit ;
}
#]]]
#[[[ check download order
$GLOBAL{'order'} = $config->{'download'}->{'order'} ;
if ($GLOBAL{'order'}) {
	if ($GLOBAL{'order'} ne "newest" && $GLOBAL{'order'} ne "oldest") {
		print STDERR "***Error in base config: download 'order' attribute is invalid ('".$GLOBAL{'order'}."')\n" ;
		exit ;
	}
} else {
# default is 'newest files first'
	$GLOBAL{'order'} = "newest" ;
}
#]]]
$GLOBAL{'makefolders'} = $config->{'makefolders'} ; #[[[
if ($GLOBAL{'makefolders'} && ($GLOBAL{'makefolders'} ne "per podcast" && $GLOBAL{'makefolders'} ne "date-today" && $GLOBAL{'makefolders'} ne "date-all")) {
	print STDERR "***Error in base config: makefolders set to an invalid value, should be 'per podcast' or 'date-all' or 'date-today'\n" ;
	exit ;
} elsif (!$GLOBAL{'makefolders'} || $GLOBAL{'makefolders'} eq '') {
	$GLOBAL{'makefolders'} = "per podcast" ;
} #]]]
if ($config->{'cutoffdate'}) { #[[[
	my $date = ParseDate($config->{'cutoffdate'}) ;
	$GLOBAL{'cutoffdate'} = UnixDate($date,"%q") ;
} #]]]
if ($config->{'m3upath'}) {
	$M3Upath = $config->{'m3upath'} ;
}

foreach ( @{$config->{'subscriptions'}->{'feed'}} ) {
	my %myfeed = %{$_} ;
	if (($ONEPODCAST && $myfeed{'feedname'} =~ /$ONEPODCAST/i) || (!$ONEPODCAST)) {
		print &ts()."Checking ".$myfeed{'feedname'}." for files\n" if ($VERBOSE) ;
		process_feed($_) ;
	}
}

print &ts()."Done\n" ;
exit ;

sub process_feed #[[[
{
	my $FEED = shift ;
	my @FETCHEDFILES = () ;
	my $limit_t = 0 ;
	my $limit_q = 0 ;
	my $feedname = '' ;
	my $feedurl = '' ;
	my $rename = 'no' ;
	my $podcastsinfeed = 0 ;
	my $skipped = 0 ;
	my $skiplog = 0 ;
	my $skipfile = 0 ;
	my $skipold = 0 ;
	my $fetched = 0 ;
	my $feedorder = '' ;
#[[[ check feed name
	if (!$FEED->{'feedname'} || $FEED->{'feedname'} eq '') {
		print &ts()."***Warning: detected a subscription feed without a 'feedname' value, skipping\n" ;
		next ;
	} else {
		$feedname = $FEED->{'feedname'} ;
		my $cleanname = '' ;
		for (my $i=0; $i<length($feedname); $i++) {
			my $ch = substr($feedname,$i,1) ;
			if ($ch =~ /[a-zA-Z0-9\-\.]/) {
				$cleanname .= $ch ;
			}
		}
		$feedname = $cleanname ;
	} #]]]
#[[[ check feed url
	if (!$FEED->{'url'} || $FEED->{'url'} eq '') {
		print &ts()."***Warning: subscription feed named '$feedname' has an invalid 'url' value, skipping\n" ;
		next ;
	} else {
		$feedurl = $FEED->{'url'} ;
	}
	print &ts()."$feedname:" if (!$VERBOSE) ;
	print "===\n".&ts()."$feedurl: ($feedname)\n" if ($VERBOSE) ;
#]]]
#[[[ rename
	if (length($FEED->{'rename'}->{'oldformat'}) > 0 && length($FEED->{'rename'}->{'newformat'}) > 0) {
		$rename = "yes" ;
	} elsif ($FEED->{'rename'}->{'oldformat'} && !$FEED->{'rename'}->{'newformat'}) {
		print STDERR "\n***Warning: subscription feed named '$feedname' has no 'newformat' attribute for 'rename', skipping\n" ;
		next ;
	} elsif (!$FEED->{'rename'}->{'oldformat'} && $FEED->{'rename'}->{'newformat'}) {
		$rename = "no" ;
	} else {
		$rename = "no" ;
	} #]]]
#[[[ check feed's limits, if any
	my $f_limit_q = 0 ;
	my $f_limit_t = 0 ;
	($limit_q, $limit_t) = parse_limit($FEED->{'download'}->{'limit'},"feed") ;
	if ($limit_q eq "skip" || $limit_t eq "skip") {
		next ;
	}
#]]]
	#[[[ check feed's download ordering, if any
	$feedorder = $FEED->{'download'}->{'order'} ;
	$feedorder = $GLOBAL{'order'} if ($feedorder eq '') ;
	if ($feedorder ne 'newest' && $feedorder ne 'oldest' && $feedorder ne 'smallest' && $feedorder ne 'biggest') {
		print STDERR "***Warning: $feedname has an invalid 'order' attribute ($feedorder), skipping this feed\n" ;
	} #]]]

# fetch feed list:
	my $res = $ua->request(GET "$feedurl") ;
	if ($res->is_success) {
		my $feedlist = $res->content ;
		my $feedxml = $xml->XMLin($feedlist, forcearray => ['item','enclosure'] ) ;
		my $bytessofar = 0 ;
		my @filelist = () ;
		my $skiprest = 0 ;
		foreach ( @{ $feedxml->{'channel'}->{'item'} } ) { #[[[
			last if ($skiprest == 1) ;
			my $PODCAST = $_ ;
			my $pubDate = '' ;
			my $podcasturl = '' ;
			my $podcastsize = 0 ;
			my $podcasttitle = $PODCAST->{'title'};
			my $podcastdescription = $PODCAST->{'description'};
			foreach ( @{ $PODCAST->{'enclosure'} } ) { #[[[ count podcasts only
				$podcasturl = &correct_url($_->{'url'}) ;
				if (!$podcasturl) {
					next ;
				}
				$podcastsinfeed++ ;
			} #]]]
			foreach ( @{ $PODCAST->{'enclosure'} } ) { #[[[
				$podcasturl = &correct_url($_->{'url'}) ;
				$podcastsize = $_->{'length'} ;
				if (!$podcasturl) {
					next ;
				}
# check date and size here before continuing
# [[[ size
				if (!$podcastsize) {
					print &ts()."Fetching file size via HTTP: " if ($DEBUG) ;
					$podcastsize = getpodcastsize($podcasturl) ;
					print translatesize($podcastsize)."\n" if ($DEBUG) ;
				}
        if ($DEBUG) {
          print "limit_t: $limit_t\n";
          print "bytes so far: $bytessofar\n";
          print "podcast size: $podcastsize\n";
          print "limit_q: $limit_q\n";
        }
				if ($limit_t eq "bytes" && (($bytessofar+$podcastsize)>$limit_q)) {
					print STDERR "\n***Info: Downloading $podcasturl would exceed your byte limitation, skipping rest of feed.\n" ;
					$skiprest = 1 ;
					last ;
				} else {
					$bytessofar += $podcastsize ;
				} #]]]
#[[[ date
				if (eval('$PODCAST->{pubDate}')) {
					$pubDate = $PODCAST->{'pubDate'} ;
				} else {
					print &ts()."Fetching file date via HTTP\n" if ($DEBUG) ;
					$pubDate = getpodcastdate($podcasturl) ;
				}
				$pubDate =~ s/-14400/-0700/g ;
				my $pubDateSeconds = UnixDate(ParseDate($pubDate),"%q") ;
				if ($pubDateSeconds < $GLOBAL{'cutoffdate'} && $FEED->{'download'}->{'skipold'} ne 'no') {
# if this pubDate is older than our configured cut-off date, then skip it
					print &ts()."***Info: $podcasturl is too old (".$pubDate.") (skipold='yes')\n" if ($VERBOSE && $DEBUG) ;
					#print "." if (!$VERBOSE && !$DEBUG) ;
					$skipold++ ;
					$skipped++ ;
					next ;
				} #]]]
				my $date = ParseDate($pubDate) ;
				$pubDate = UnixDate($date,"%q") ;
				print "==> pubDate: ".UnixDate($date,"%Y-%m-%d")."\n" if ($DEBUG) ;
				if ($feedorder eq 'smallest' || $feedorder eq 'biggest') {
					push (@filelist, "$podcastsize|$pubDate|$podcasttitle|$podcasturl|$podcastdescription") ;
				} elsif ($feedorder eq 'oldest' || $feedorder eq 'newest' || $feedorder eq '') {
					push (@filelist, "$pubDate|$podcastsize|$podcasttitle|$podcasturl|$podcastdescription") ;
				}
				print "==> $podcasturl ($podcasttitle) is queued for possible download\n" if ($VERBOSE && $DEBUG) ;
				print "==> $podcasturl\n" if ($VERBOSE && !$DEBUG) ;
			} #]]]
		} #]]]
		#if (!$skiprest) {
			#[[[ initial sort will put the array in oldest/smallest order
			@filelist = sort(@filelist) ;
			if ($feedorder eq "newest" || $feedorder eq "biggest") {
				@filelist = reverse(@filelist) ;
			} #]]]
			foreach my $PODCAST ( @filelist ) {
				#[[[ get file list to fetch
				my ($pubDate,$podcastsize,$podcasttitle,$podcastdescription,$podcasturl) ;
				if ($feedorder eq "newest" || $feedorder eq "oldest" || $feedorder eq '') {
					($pubDate, $podcastsize, $podcasttitle, $podcasturl, $podcastdescription) = split(/\|/, $PODCAST) ;
				} elsif ($feedorder eq "smallest" || $feedorder eq "biggest") {
					($podcastsize, $pubDate, $podcasttitle, $podcasturl, $podcastdescription) = split(/\|/, $PODCAST) ;
				} #]]]
				my $date = ParseDate($pubDate) ;
				my $podcastdate = UnixDate($date,"%Y-%m-%d") ;
				my $podcastdatetime = UnixDate($date,"%Y-%m-%d %H%M") ;
				my $outputfile = '' ;
				my $podcastfolder = '' ;
				my $podcastTsize = translatesize($podcastsize) ;

				# determine disk path to save the file
				$outputfile = $GLOBAL{'basedir'}."/" ;
				#[[[ figure out folder to make, if applicable
				if ($GLOBAL{'makefolders'} eq "per podcast") {
					if (defined($FEED->{'foldername'})) {
						$outputfile .= $FEED->{'foldername'} ;
					} else {
						$outputfile .= $FEED->{'feedname'} ;
					}
				} elsif ($GLOBAL{'makefolders'} eq "date-today") {
					$date = &timestamp_YMD() ;
					chomp($date) ;
					$outputfile .= $date ;
				} elsif ($GLOBAL{'makefolders'} eq "date-all") {
					$date = ParseDate($pubDate) ;
					$date = UnixDate($date,"%Y-%m-%d") ;
					$outputfile .= $date ;
				} #]]]
				$podcastfolder = $outputfile ;
				if (! mkdir $podcastfolder ) { #[[[
					if ($! !~ /file exist/i) {
						print "\n" if (!$VERBOSE) ;
						print &ts()."***Warning: Could not create folder: $podcastfolder: $! - skipping the rest of this feed\n" ;
						last ;
					}
				} #]]]
				#[[[ last bit of file mangling
				my @bits = split(/\//, $podcasturl) ;
				my $oldname = $bits[$#bits] ;
				my $podcastfilename = $bits[$#bits] ;
#				print "podcastfilename: $podcastfilename\n" ;
				my @filebits = split(/\./,$podcastfilename) ;
				my $file_extension = $filebits[$#filebits] ;
				if ($rename eq "yes") {
					my $filename = '' ;
					if ($FEED->{'rename'}->{'oldformat'} eq '%s') {
						$filename = $FEED->{'rename'}->{'newformat'} ;
						$filename =~ s/\$1/$podcastfilename/g ;
					} else {
						my @pieces = &sscanf($FEED->{'rename'}->{'oldformat'},$podcastfilename) ;
						$filename = $FEED->{'rename'}->{'newformat'} ;
						my $pccnt = $#pieces ;
						for (my $i=1; $i<($pccnt+1); $i++) {
							$filename =~ s/\$$i/$pieces[$i-1]/ ;
						}
					}
					$filename =~ s/\$datetime/$podcastdatetime/ ;
					$filename =~ s/\$date/$podcastdate/ ;
					$filename =~ s/\$name/$feedname/ ;
					$filename =~ s/\$ext/$file_extension/ ;
					$filename =~ tr/+/ / ;
					$filename =~ s/%([a-fA-F0-9]{2,2})/chr(hex($1))/eg ;
					$podcastfilename = $filename ;
				}
				$outputfile .= "/".$podcastfilename ;
				#print "outputfile: $outputfile\n" ;
				#]]]
				#[[[ build/check log files for this feed to determine whether we've ever downloaded this file before
				my @oldfilelist = () ;
				my @oldfiles = () ;
				if (! -e $GLOBAL{'logdir'}."/$feedname.log") { #[[[
					# create it if it doesn't already exist
					open(PODLOG,">".$GLOBAL{'logdir'}."/$feedname.log") ;
					close(PODLOG) ;
					@oldfilelist = () ;
					@oldfiles = () ;
					#]]]
				} else { #[[[
					open(PODLOG,"<".$GLOBAL{'logdir'}."/$feedname.log") ;
					@oldfilelist = <PODLOG> ;
					close(PODLOG) ;
					@oldfiles = grep (/\Q$podcasturl\E/, @oldfilelist) ; # svn bug 0000005
				} #]]]
				#[[[ check if the file already exists in the log (if renamed) or on disk
					if ( -e $outputfile || $oldfiles[0] ) {
						if ($oldfiles[0]) {
							print "$podcasturl (skip-log)\n" if ($DEBUG);
							$skiplog++ ;
						} else {
							print "$podcasturl (skip-fileexists)\n" if ($DEBUG) ;
							$skipfile++ ;
						}
						$skipped++ ;
						#print "." if (!$VERBOSE) ;
						next ;
					} else {
						push(@FETCHEDFILES, "$oldname|$podcastfilename|$podcastTsize") ;
					} #]]]
				# download the file if we're okay
				if ($GLOBAL{'active'}) {
					print &ts()."<== fetching >>>$podcasturl<<< ($podcastTsize)\n" if ($VERBOSE) ;
					print "x" if (!$VERBOSE) ;
					$podcasturl = &correct_url($podcasturl) ;
					my $res2 = $ua->get("$podcasturl") ;
					if ($res2->is_success) {
						$outputfile =~ tr/+/ / ;
						$outputfile =~ s/%([a-fA-F0-9]{2,2})/chr(hex($1))/eg ;
						open(OUTPUT,"> $outputfile") or die ("***Error: could not open $outputfile for writing, exitting\n") ;
						print OUTPUT $res2->content ;
						close(OUTPUT) ;
						&add2m3u("$podcastfolder/$podcastfilename") ;
						# write url into $podcastfolder/$feedname.log
						if (open(PODLOG,">>".$GLOBAL{'logdir'}."/$feedname.log")) {
							$podcastdescription =~ s/\r\n/ /g ;
							$podcastdescription =~ s/\n/ /g ;
							print PODLOG &ts()."\n".$podcasturl."\n" ;
							print PODLOG "Title: $podcasttitle\n" if ($podcasttitle) ;
							print PODLOG "Description: $podcastdescription\n" if ($podcastdescription) ;
							print PODLOG "\n" ;
							close(PODLOG) ;
						} else {
              print PODLOG &ts().$res2."\n";
							print &ts()."***Warning, could not append to ".$GLOBAL{'logdir'}."/$feedname.log\n" ;
						}
						$fetched++ ;
					} else {
						print "\n" if (!$VERBOSE) ;
						print "***Warning: $feedname possibly contains an invalid podcast URL: $podcasturl\n" ;
# figure out why ... maybe write the file anyway?
							print &ts()."\nUnsuccessful: ".$res2->status_line."\n" ;
						}
					}
#[[[ check if we've downloaded our count of files so far
					if ($fetched >= $limit_q && $limit_t eq "file") {
						print "\n" if (!$VERBOSE) ;
						print "***Info: Downloaded your limit of $limit_q files, skipping rest of feed.\n" ;
						last ;
					} #]]]
			} #]]]
			print " ".sprintf("%3d",$podcastsinfeed)." podcasts " ;
			print "in the data feed\n" if ($VERBOSE) ;
			print "," if (!$VERBOSE) ;
			print " $fetched fetched, $skipped skipped" if (!$VERBOSE) ;
			print " ".sprintf("%3d",$fetched)." fetched\n" if ($VERBOSE) ;
			print " ".sprintf("%3d",$skiplog)." were previously logged and were skipped\n" if ($VERBOSE) ;
			print " ".sprintf("%3d",$skipfile)." already existed and were skipped\n" if ($VERBOSE) ;
			print " ".sprintf("%3d",$skipold)." were skipped because they were too old" if ($VERBOSE && $skipold > 0) ;
			print "\n" ;
			if ($fetched > 0) {
				print "Fetched:\n" ;
				foreach (@FETCHEDFILES) {
					my ($oldname,$newname,$size) = split(/\|/,$_) ;
					print "\t$oldname " ;
					print "(renamed to $newname) " if ($VERBOSE && $rename eq "yes") ;
					print "($size)\n" ;
				}
			}
		#} else {
		#	last ;
		#}
	} else {
		print STDERR "\n" if (!$VERBOSE) ;
		print "***Error: subscription feed named '$feedname' had an error:\n";
    print $res->as_string ."\n";
    print $res->status_line ."\n";
    print $res->message ."\n";
	}
}#]]]
sub add2m3u #[[[
{
	my ($podfile) = @_ ;
	$podfile =~ s/$GLOBAL{'basedir'}//g ;
	$podfile =~ s/\/\//\\/g ;
	$podfile =~ s/\//\\/g ;
	$podfile =~ s/\\\\/\\/g ;
	$podfile =~ s/^\\// ;
	my $m3ufile = $GLOBAL{'basedir'}."/podcast-".$today.".m3u" ;
# we'll use >> so downloads are cumulative throughout the day
	open (M3U, ">> $m3ufile") or die ("Could not open $m3ufile for writing\n") ;
	my $filename = $M3Upath."\\".$podfile ;
	$filename =~ s/\//\\/g ;
	$filename =~ s/\\\\/\\/g ;
	print M3U "$filename\n" ;
	close(M3U) ;
# make sure m3u file is a DOS-formatted file
	`/usr/bin/unix2dos $m3ufile 2>&1 /dev/null` ;
}#]]]
sub parse_limit #[[[
{
	my ($limitstring,$config) = @_ ;
	my ($limit_t, $limit_q) ;
	my $oldlimitstring = $limitstring ;
	my $done = 0 ;

	if (length($limitstring) == 0 || $limitstring eq "" || !$limitstring || $limitstring eq " ") { #[[[
		if ($config eq "base") {
#			print "base config had empty limit string, assuming 'unlimited'\n" ;
			$limit_q = "100000" ;
			$limit_t = "file" ;
		} elsif ($config eq "feed") {
#			print "no limit string, setting to global defaults of '".$GLOBAL{'limit_q'}."' and '".$GLOBAL{'limit_t'}."'\n" ;
			$limit_t = $GLOBAL{'limit_t'} ;
			$limit_q = $GLOBAL{'limit_q'} ;
		}
		$done = 1 ;
#]]]
	} elsif ($limitstring eq "unlimited" || $limitstring eq "all") {#[[[
#		print "'unlimited' limit detected\n" ;
		$limit_q = "100000" ;
		$limit_t = "file" ;
		$done = 1 ;
	}#]]]
	if (!$done) { #[[[
		$limitstring =~ s/ //g ;
		my ($num,$type) = &sscanf("%d%s",$limitstring) ;
		$type =~ s/ //g ;
		$num =~ s/ //g ;

		if ($num =~ /\d/) { #[[[
			if ($num eq '0') { #[[[
				if ($config eq "base") {
					print "***Error: base config has a download limit of 0, effectively stopping all downloads, exiting\n" ;
					$limit_q = "exit" ;
					$limit_t = "exit" ;
				} elsif ($config eq "feed") {
					print " download limit of 0 detected, skipping this feed\n" ;
					$limit_q = "skip" ;
					$limit_t = "skip" ;
				}
#]]]
			} else { #[[[ num is a numeric value
				$limit_q = $num ;
				$limit_t = $type ;
				if ($limit_t =~ /file/i) {
					$limit_t = "file" ;
				} elsif ($limit_t =~ /b/i) {
					$limit_t = "bytes" ;
					if ($type =~ /kb/i) {
						$limit_q = $num*(1024) ;
					} elsif ($type =~ /mb/i) {
						$limit_q = $num*(1024*1024) ;
					} elsif ($type =~ /gb/i) {
						$limit_q = $num*(1024*1024*1024) ;
					} else {
						if ($config eq "base") {
							print "***Error: base config download limit has an invalid byte limitation: '$limitstring', exiting\n" ;
							$limit_q = "exit" ;
							$limit_t = "exit" ;
						} elsif ($config eq "feed") {
							print "***Warning, subscription feed has an invalid byte limitation '".$limitstring."', skipping\n" ;
							$limit_q = "skip" ;
							$limit_t = "skip" ;
						}
					}
				} else { #[[[
					if ($config eq "base") {
						print "***Error: base config has an invalid download limit type ('$type' in '$oldlimitstring'), cannot continue\n" ;
						$limit_q = "exit" ;
						$limit_t = "exit" ;
					} elsif ($config eq "feed") {
						print "\n***Warning: invalid download limit type detected in '$oldlimitstring', skipping this feed\n" ;
						$limit_q = "skip" ;
						$limit_t = "skip" ;
					}
				} #]]]
			} #]]]
#]]]
		} else { #[[[ 'num' is not a number
			if ($config eq "base") {
				print "***Error: base config has an invalid download limit ('$oldlimitstring'), cannot continue\n" ;
				$limit_q = "exit" ;
				$limit_t = "exit" ;
			} elsif ($config eq "feed") {
				print "\n***Warning: invalid download limit ('$oldlimitstring') detected, skipping this feed\n" ;
				$limit_q = "skip" ;
				$limit_t = "skip" ;
			}
		} #]]]
	} #]]]

	my @tmp = () ;
	$tmp[0] = $limit_q ;
	$tmp[1] = $limit_t ;
#print "returning num: '$limit_q' type: '$limit_t'\n" ;
	return @tmp ;
} #]]]
sub getpodcastsize #[[[
{
	my ($podcasturl) = @_ ;
	my $wize = 0 ;
	if ($podcasturl) {
		my $ua99 = new LWP::UserAgent ;
		my $res99 = $ua->request(HEAD "$podcasturl") ;
		if ($res99->is_success) {
			my $size = $res99->header("Content-length") ;
			if ($size) {
				return $size ;
			}
		}
	}
	return 0 ;
} #]]]
sub translatesize #[[[
{
	my ($size) = @_ ;
	if ($size) {
		if ($size < 1024) {
			return "$size B" ; # "123 B"
		} elsif ($size < (1024*1024)) {
			$size = $size / 1024 ;
			return sprintf ("%0.1f KB", $size) ; #  "12.3 KB"
		} elsif ($size < (1024*1024*1024)) {
			$size = $size / (1024*1024) ;
			return sprintf ("%0.3f MB", $size) ; #  "12.345 MB"
		}
	}
	return "0" ;
} #]]]
sub getpodcastdate #[[[
{
	my ($podcasturl) = @_ ;
	if ($podcasturl) {
		print timestamp_YMDHMS()." starting http date check\n" if ($VERBOSE) ;
		my $ua99 = new LWP::UserAgent ;
		my $res99 = $ua->request(HEAD "$podcasturl") ;
		if ($res99->is_success) {
			my $date = $res99->header("Last-Modified") ;
			if ($date) {
				print timestamp_YMDHMS()." got http date check, $date\n" if ($VERBOSE) ;
				return $date ;
			}
		}
	}
	print timestamp_YMDHMS()." finished http date check, no date found\n" if ($VERBOSE) ;
	return UnixDate("today",'%g') ;
} #]]]
sub timestamp_YMDHMS #[[[
{
	my($t) = @_;
	$t = time if (!defined($t));
  my($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($t) ;
  my($time_string) = sprintf("%04d-%02d-%02d %02d:%02d:%02d", $year+1900,$mon+1,$mday,$hour,$min,$sec) ;
  return $time_string ;
} #]]]
sub timestamp_YMD #[[[
{
	my($t) = @_;
	$t = time if (!defined($t));
  my($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($t) ;
  my($time_string) = sprintf("%04d-%02d-%02d", $year+1900,$mon+1,$mday) ;
  return $time_string ;
} #]]]
sub ts #[[[ shortcut name
{
	return '['.&timestamp_YMDHMS().'] ' ;
} #]]]
sub correct_url #[[[
{
	my ($url) = @_ ;
	if ($url =~ /^<a href=/i) {
		$url =~ s/^<a href=['"]//i ;
		$url =~ s/['"]>(.*)<\/a>//i ;
		print "newurl: $url\n\n" ;
	}
	return $url ;
} #]]]


sub Usage #[[[
{
	my $scriptname = `basename $0` ;
	chomp($scriptname) ;
	print <<__EOT__;
	Typical Usage:
		$scriptname [--email=email] [--config=config.xml] [--listpasswd]
		            [--verbose] [--help] [--onepodcast=feedname]

		If --email is used, the application will attempt to connect to
		w98podfetch's online database, and the --config option becomes mandatory,
		and must include the name of the confguration to download. If the list
		configuration you're downloading is protected by a password, you must also
		pass --listpasswd and send the proper case-sensitive password. The Email
		address passed as the 'email' parameter but be a valid registered user at
		'w98podfetch online'.

		If you are using a local configuration file which lives somewhere other
		than the default directories (see docs for details), you must pass the
		--config option to tell the script where to find your configuration file.
		Without it, the script will not run.

		Verbose mode simply prints more debugging information to the screen.

		'onepodcast' mode will let you download the files from only a single
		podcast, based on the 'feedname' of the podcast in the configuration.

		Help mode prints this message.

__EOT__
}#]]]
