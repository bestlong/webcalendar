#!/usr/bin/perl
#
# This tool will update a translation file by doing the following:
# - When a missing translation is found, the phrase will have
#   "<< MISSING >>"
#   right before it to make it easy to find.
# - Show the English text (in a comment) after an untranslated phrase,
#   when the "phrase" is not the same as the "translation",
#   making it easier to translate.
# - Phrases are organized by the page on which they appear.
#
# Note: you will lose any comments you put in the translation file
# when using this tool (except for the comments at the very beginning).
#
# Note #2: This will overwrite the existing translation file, so a backup
# of the original can optionally be saved with a .bak file extension.
#
# Usage:
# update_translation.pl [-p plugin] languagefile
#
# Example for main WebCalendar translation:
# update_translation.pl French.txt
#    or
# update_translation.pl French
#
# Example for plugin "tnn" translation:
# update_translation.pl -p tnn French.txt
#    or
# update_translation.pl -p tnn French
#
# Note: this utility should be run from this directory (tools).
# Note #2: you can use perltidy to format this perl script nicely:
#  http://perltidy.sourceforge.net/
# Usage:
#  perltidy -i=2 update_translation.pl
#  (which will create update_translation.pl.tdy, the new version)
#
###########################################################################

$base_dir  = "..";
$trans_dir = "../translations";

$base_trans_file = "$trans_dir/English-US.txt";
$plugin          = "";

$show_missing = 1;    # set to 0 to minimize translation file.
$show_dups    = 0;    # set to 0 to minimize translation file.
$verbose      = 0;

($this) = reverse split( /\//, $0 );

$save_backup = 0;     # set to 1 to create backups

for ( $i = 0 ; $i < @ARGV ; $i++ ) {
  if ( $ARGV[$i] eq "-p" ) {
    $plugin = $ARGV[ ++$i ];
  }
  elsif ( $ARGV[$i] eq "-v" ) {
    $verbose++;
  }
  else {
    $infile = $ARGV[$i];
  }
}

die "Usage: $this [-p plugin] language\n" if ( $infile eq "" );

if ( $plugin ne "" ) {
  $p_trans_dir       = "$base_dir/$plugin/translations";
  $p_base_trans_file = "$p_trans_dir/English-US.txt";
  $p_base_dir        = "$base_dir/$plugin";
}
else {
  $p_trans_dir       = $trans_dir;
  $p_base_trans_file = $base_trans_file;
  $p_base_dir        = $base_dir;
}

if ( $infile !~ /txt$/ ) {
  $infile .= ".txt";
}
if ( -f "$trans_dir/$infile" || -f "$p_trans_dir/$infile" ) {
  $b_infile = "$trans_dir/$infile";
  $infile   = "$p_trans_dir/$infile";
}

#print "infile: $infile\nb_infile: $b_infile\ntrans_dir: $trans_dir\n";

die "Usage: $this [-p plugin] language\n" if ( !-f $infile );

print "Translation file: $infile\n" if ($verbose);

# Now load the base translation(s) file (English) so that we can include
# the English text, below the untranslated phrase, in a comment.
open( F, $base_trans_file ) || die "Error opening $base_trans_file";
print "Reading base translation file: $base_trans_file\n" if ($verbose);
while (<F>) {
  chop;
  s/\r*$//g;    # remove annoying CR
  next if (/^#/);
  if (/\s*:\s*/) {
    $abbrev = $`;
    $base_trans{$abbrev} = $' if ( $abbrev ne 'charset' );
  }
}
close(F);

# read in the plugin base translation file
if ( $plugin ne "" ) {
  print "Reading plugin base translation file: $p_base_trans_file\n"
    if ($verbose);
  open( F, $p_base_trans_file ) || die "Error opening $p_base_trans_file";
  while (<F>) {
    chop;
    s/\r*$//g;    # remove annoying CR
    next if (/^#/);
    if (/\s*:\s*/) {
      $abbrev = $`;
      $base_trans{$abbrev} = $';
    }
  }
  close(F);
}

#
# Now load the translation file we are going to update.
#
$old = "";
if ( -f $infile ) {
  print "Reading current translations from $infile\n" if ($verbose);
  open( F, $infile ) || die "Error opening $infile";
  $in_header = 1;
  while (<F>) {
    $old .= $_;
    chop;
    s/\r*$//g;    # remove annoying CR
    if ( $in_header && /^#/ ) {
      if (/Translation last (pagified|updated)/) {

        # ignore since we will replace this with current date below
      }
      else {
        $header .= $_ . "\n";
      }
    }
    next if (/^#/);
    $in_header = 0;
    if (/\s*:\s*/) {
      $abbrev = $`;
      $trans{$abbrev} = $';
    }
  }
}
$trans{'direction'} = 'ltr' if ( !defined( $trans{'direction'} ) );
if ( $plugin ne "" ) {
  print "Reading current WebCalendar translations from $b_infile\n"
    if ($verbose);
  open( F, $b_infile ) || die "Error opening $b_infile";
  $in_header = 1;
  while (<F>) {
    chop;
    s/\r*$//g;    # remove annoying CR
    if (/\s*:\s*/) {
      $abbrev = $`;
      $webcaltrans{$abbrev} = $';
    }
  }
}

#
# Save a backup copy of old translation file.
#
if ($save_backup) {
  open( F, ">$infile.bak" ) || die "Error writing $infile.bak";
  print F $old;
  close(F);
  print "Backup of translation saved in $infile.bak\n";
}

if ( $header !~ /Translation last updated/ ) {
  ( $day, $mon, $year ) = ( localtime( time() ) )[ 3, 4, 5 ];
  $header .=
    "# Translation last updated on "
    . sprintf( "%02d-%02d-%04d", $mon + 1, $day, $year + 1900 ) . "\n";
}

# First get the list of .php files
print "Searching for PHP files in $p_base_dir\n" if ($verbose);
opendir( DIR, $p_base_dir ) || die "Error opening $p_base_dir";
@files = grep ( /\.php$/, readdir(DIR) );
closedir(DIR);

if ( -d "$p_base_dir/includes" ) {
  print "Searching for PHP files in $p_base_dir/includes\n" if ($verbose);
  opendir( DIR, "$p_base_dir/includes" )
    || die "Error opening $p_base_dir/includes";
  @incfiles = grep ( /\.php$/, readdir(DIR) );
  closedir(DIR);
  foreach $f (@incfiles) {
    push( @files, "includes/$f" );
  }
}
if ( -d "$p_base_dir/includes/js" ) {
  print "Searching for PHP files in $p_base_dir/includes/js\n" if ($verbose);
  opendir( DIR, "$p_base_dir/includes/js" )
    || die "Error opening $p_base_dir/includes/js";
  @incfiles = grep ( /\.php$/, readdir(DIR) );
  closedir(DIR);
  foreach $f (@incfiles) {
    push( @files, "includes/js/$f" );
  }
}
if ( -d "$p_base_dir/includes/classes" ) {
  print "Searching for Class files in $p_base_dir/includes/classes\n"
    if ($verbose);
  opendir( DIR, "$p_base_dir/includes/classes" )
    || die "Error opening $p_base_dir/includes/classes";
  @incfiles = grep ( /\.class$/, readdir(DIR) );
  closedir(DIR);
  foreach $f (@incfiles) {
    push( @files, "includes/classes/$f" );
  }
}
if ( $plugin eq "" ) {
  push( @files, "includes/menu/index.php" );
  push( @files, "tools/send_reminders.php" );
  push( @files, "tools/reload_remotes.php" );
#
# Do not add any files below this point. We want to be able to
# ignore these translations when not performing an installation
# Please see includes/translate.php for details
#
  push( @files, "install/install_functions.php" );
  push( @files, "install/index.php" );
}

#
# Write new translation file.
#
$notfound = 0;
open( OUT, ">$infile" ) || die "Error writing $infile: ";
print OUT $header;
if ( $plugin eq '' ) {
  if ( defined( $trans{'charset'} ) ) {
    print OUT "\n\n###############################################\n"
      . "# Specify a charset (will be sent within meta tag for each page)\n#\n"
      . "charset: $trans{'charset'}\n\n";
    $text{'charset'}    = 1;
    $foundin{'charset'} = " top of this file";
  }
  else {
    print OUT "\n# No charset specified (not needed for iso-8859-1)\n"
      . "# \"charset\" is used in a meta tag, "
      . "do not translate \"charset\" here.\n"
      . "# charset:\n\n";
  }
}

foreach $f (@files) {
  $pageHeader =
    "\n\n###############################################\n# Page: $f\n#\n";
  $file = "$p_base_dir/$f";
  open( F, $file ) || die "Error reading $file";
  print "Searching $f\n" if ($verbose);
  %thispage = ();
  while (<F>) {
    $data = $_;
    while ( $data =~ /(translate|tooltip)\s*\(\s*['"]/ ) {
      $data = $';
      if ( $data =~ /['"]\s*[,\)]/ ) {
        $text = $`;
        if ( defined( $thispage{$text} ) ) {

          # text already found within this page...
        }
        elsif ( $text eq 'charset' ) {

          # ignore...
        }
        elsif ( defined( $text{$text} ) ) {
          if ( !show_dups ) {
            if ( $pageHeader ne '' ) {
              print OUT $pageHeader;
              $pageHeader = '';
            }
            print OUT "# \"$text\" previously defined (in $foundin{$text})\n";
          }
          $thispage{$text} = 1;
        }
        else {
          if ( !length( $trans{$text} ) ) {
            if ($show_missing) {
              if ( length( $webcaltrans{$text} ) ) {
                if ( $pageHeader ne '' ) {
                  print OUT $pageHeader;
                  $pageHeader = '';
                }
                print OUT "# \"$text\" defined in WebCalendar translation\n";
              }
              else {
                if ( $pageHeader ne '' ) {
                  print OUT $pageHeader;
                  $pageHeader = '';
                }
                print OUT "#\n# << MISSING >>\n# $text:\n";
                print OUT "# English text: $base_trans{$text}\n#\n"
                  if ( length( $base_trans{$text} )
                  && $base_trans{$text} ne $text );
              }
            }
            $text{$text}     = 1;
            $thispage{$text} = 1;
            $foundin{$text}  = $f;
            $notfound++ if ( !length( $webcaltrans{$text} ) );
          }
          else {
            $text{$text}     = 1;
            $foundin{$text}  = $f;
            $thispage{$text} = 1;
            if ( $pageHeader ne '' ) {
              print OUT $pageHeader;
              $pageHeader = '';
            }
            printf OUT ( "%s: %s\n", $text, $trans{$text} );
          }
        }
        $data = $';
      }
    }
  }
  close(F);
}

if ( !$notfound ) {
  print STDERR "All text was found in $infile.  Good job :-)\n";
}
else {
  print STDERR "$notfound translation(s) missing.\n";
}

exit 0;
