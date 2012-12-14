#!/usr/bin/perl

# Add my customized keyboard layouts to the system layout folder, and register
# them with XKB
#
# The script will search a few standard directories for xkb, then copy the
# files to $xkb_path/symbols(/pc)?, and add necessary text to xorg.(xml|lst)
# and evdev.(xml|lst)
#
# Design notes:
# - This script is meant to be run on a freshly-installed system, so cannot
#   rely on any non-Core modules.

# TODO:
# The script can't tell whether a rule file already contains some of the
# layout definitions, and will end up making multiple copies.
# Fix this by (within the <layoutList> block) reading entire <layout>
# sections, then updating if a section matches any user layout. (Similar for
# .lst)
# Make a list of layout names to compare against each section

# Default path to search for keyboard layouts
my $DEFAULT_LAYOUT_PATH = $ENV{HOME} . "/Documents/projects/current/keylayouts/";

# Information about each keylayout
# (hardcoded 'cause I'm hardcore. Also, should this ever be passed to a
# sysadmin, it should have as few file dependencies as possible)
my $KEYLAYOUTS = [
   {
      layout => 'pconley',
      short_name => 'PDvorak',
      full_name => 'PConley Dvorak',
      language => 'eng',
      path => undef,
      variants => [
         {
            layout => 'dvp',
            short_name => 'PProgramming',
            full_name => 'PConley Programming',
         },
      ]
   },
];

use strict;
use warnings;
use utf8;

use File::Copy;
use File::Temp;
use Getopt::Long;
use Cwd;

# Try to use Log::Handler for debug output
my $has_logger = 0;
eval {
   require PConley::Log::Setup;
   PConley::Log::Setup->import();
   $has_logger = 1;
};

my @xkb_files = map( "rules/" . $_, qw/evdev xorg/ );

# CL options
my $input_xkb_path;
my $input_keylayout_path;
my $print_help;
my $logger_verbosity = 0;
my $dry_run = 0;

GetOptions(
   "xkb=s" => \$input_xkb_path,
   "layouts=s" => \$input_keylayout_path,
   "help" => \$print_help,
   "verbose" => sub { $logger_verbosity = 1 },
   "quiet" => sub { $logger_verbosity = -1 },
   "debug" => sub { $logger_verbosity = 2 },
   "dry-run" => sub { $dry_run = 1 },
                  
);

my $log = PConley::Log::Setup::log_setup( Log::Handler->new(),
   verbosity => $logger_verbosity ) if $has_logger;

print "Dry run. Changes will not be written to file\n" 
   if $dry_run && $logger_verbosity >= 0;

# Function  : help() {{{1
# Arguments : N/A
# Return    : N/A
# Purpose   : print out -h type help information
sub help
{

   $log->info( "Called ::help()" ) if $has_logger;

   print <<EOT
Usage: keylayout.pl [ --help ] [ --dry-run ] [ --xkb /path/to/xkb/data ] [ --layouts /path/to/original/keylayouts ]
Add custom key layouts (defined inside the script) to the XKB data directory;
register these layouts with xorg.
The path to XKB and the original keyboard layouts is found by searching
several common directories for appropriate files.

If the option 'dry-run' is used, the script will run normally, but no changes
will be made except to temporary files.

Warning: this script is not smart enough to properly update a rule file that
already contains some of the layout definitions. I don't know what X11 will do
if you try it.
EOT

}
# Function  : xkb_path = find_xkb() {{{1
# Arguments : N/A
# Return    : full path to the directory containing the xkb rules and symbol
#             files. Directory ends with a /
# Purpose   : Find the path to xkb. Wow.
my @xkb_validators = qw/symbols rules/;
my @likely_xkb_paths = (
   "/usr/share/X11/xkb", # used on Ubuntu
   "/etc/X11/xkb/", # used elsewhere(?)
   "/usr/lib/X11/xkb/", # used by XFree86?
   "/usr/X11R6/lib/X11/xkb/", # used somewhere?
);

sub find_xkb
{
   $log->debug( "Called ::find_xkb()" ) if $has_logger;

   my @paths;

   if ( $input_xkb_path )
   {
      my $real_input_xkb_path = Cwd::realpath( $input_xkb_path );
      unshift @likely_xkb_paths, $real_input_xkb_path;

      $log->debug( "Using suggested path [ $input_xkb_path ] as [ "
         . "$real_input_xkb_path ]" );
   }

   $log->debug( "Paths to search for XKB:\n\t" 
      . join( "\n\t", @likely_xkb_paths ) ) if $has_logger;

   # First try a number of likely directories {{{2
   my @defined_paths = grep( -d, @likely_xkb_paths );

   $log->debug( ( scalar @defined_paths ) . " possible paths exist:\n\t"
      . join( "\n\t", @defined_paths ) ) if $has_logger;

   my @valid_paths = @defined_paths;
   foreach my $validator ( @xkb_validators )
   {
      @valid_paths = grep( -d "$_/$validator", @valid_paths );
   }

   $log->debug( ( scalar @valid_paths ) . " paths contain rules/ and symbols/:\n"
      . "\t" . join( "\n\t", @valid_paths ) ) if $has_logger;

   foreach my $path ( @valid_paths )
   {
      push @paths, $path
         if ( grep( -e "$path/$_.xml", @xkb_files ) == 2
            && grep( -e "$path/$_.lst", @xkb_files ) == 2 )
   }

   # If that fails, search for a directory with the right files {{{2
   # TODO: write this using File::Find

   # }}}2

   # Make sure the path ends with a separator
   $paths[0] =~ s/([^\/])$/$1\//;

   $log->debug( "Valid paths to XKB:\n\t" . join( "\n\t", @paths ) )
      if $has_logger;

   # Print result status
   if ( ! @paths )
   {
      die( "Path to XKB data could not be identified.\n Stopped" )
   }
   elsif ( @paths && defined $input_xkb_path && $paths[0] !~ $input_xkb_path )
   {
      die( "$input_xkb_path does not contain XKB data.\n"
         . "Did you mean $paths[0] ?\n Stopped " );
   }
   elsif ( @paths > 1 && ! $input_xkb_path )
   {
      die( "More than one possible path to XKB data:\n"
         . join( "\n", @paths ) . "\n"
         . "Specify the correct one with --path\n"
         . "Stopped" );
   }
   else
   {
      print "Using $paths[0] as path to XKB data.\n" if $logger_verbosity >= 0;
   }

   return $paths[0];
   
}

# Function  : find_layouts() {{{1
# Arguments : N/A
# Return    : N/A
# Purpose   : Find the path to each original keyboard layout, and add it to
# the $KEYLAYOUTS hash array.
sub find_layouts
{
   $log->debug( "Called ::find_layouts()" ) if $has_logger;

   # Set up possible paths. input > default > script-path {{{2
   my @possible_paths = ( $DEFAULT_LAYOUT_PATH ); # default path

   # path to this script
   ( my $script_path = Cwd::realpath( $0 ) ) =~ s/[^\/]*$/\//;
   push @possible_paths, $script_path;

   # path from CL option
   if ( $input_keylayout_path )
   {
      my $real_input_keylayout_path = Cwd::realpath( $input_keylayout_path );
      unshift @possible_paths, $real_input_keylayout_path;

       $log->debug( "Using suggested path [ $input_keylayout_path ] as [ "
         . "$real_input_keylayout_path ]" );
   }

   # Make sure each path ends with a separator
   map( s/([^\/])$/$1\//, @possible_paths );

   $log->debug( "Paths to search for keylayouts:\n\t"
      . join( "\n\t", @possible_paths ) ) if $has_logger;

   # Search for the directory of each layout. {{{2
   # The first path found will be taken as correct
   foreach my $layout ( @$KEYLAYOUTS )
   {
      my @paths_to_layout = grep( -e $_ . $layout->{layout}, @possible_paths );

      if ( @paths_to_layout )
      {
         $layout->{path} = $paths_to_layout[0] . $layout->{layout};
         print "Using $layout->{path} as path to layout $layout->{layout}\n"
            if $logger_verbosity >= 0;
      }
      else
      {
         die( "No path could be found to layout $layout->{layout}" );
      }
   }

   # }}}2
}

# Function  : add_layout_files( xkb_path ) {{{1
# Arguments : string path to XKB
# Return    : N/A
# Purpose   : copy appropriate keyboard layout files from $layout_path to
#             <xkb_path>/symbols(/pc)?
sub add_layout_files
{

   $log->debug( "Called ::add_layout_files()" ) if $has_logger;

   # Find the path to XKB
   my $xkb_path = shift;

   if ( defined $xkb_path )
   {
      $log->debug( "XKB path $xkb_path passed as parameter" ) if $has_logger;
   }
   else
   {
      $xkb_path = find_xkb();
      $log->info( "Using $xkb_path as path to XKB" ) if $has_logger;
   }

   # Some systems (dunno which) put the symbol files in $xkb_path/symbols/pc
   my $symbol_path = $xkb_path . "symbols/";
   if ( -d $symbol_path . "pc" )
   {
      $symbol_path .= "pc/";
   }

   print "Symbols files appear to be stored in $symbol_path\n"
      if $logger_verbosity >= 0;

   foreach my $layout ( @$KEYLAYOUTS )
   {
      copy( $layout->{path}, $symbol_path . $layout->{layout} ) unless $dry_run;
      $log->info( "Copied $layout->{path} to $symbol_path" ) if $has_logger;
   }

}

# Function  : rules_exist( rule_filename ) {{{1
# Arguments : string path to a rules file
# Return    : boolean whether the rules file has been modified
# Purpose   : Check whether the given rules file contains references to any of
#             the layouts in $KEYLAYOUTS. NB: variants are allowed, as there
#             can be multiple of those with the same name.
sub rules_exist
{

   $log->debug( "Called ::rules_exist( " . join( ', ', @_ ) . " )" ) if $has_logger;

   my $rules_file = shift;
   $log->debug( "Checking rules file $rules_file for custom rules" ) if $has_logger;

   # Make a list of the layout names
   my @layouts;
   foreach my $layout ( @$KEYLAYOUTS ) { push @layouts, $layout->{layout}; }

   # grep(1) the rules file for each layout
   return 1 if ( grep( qx{ grep $_ $rules_file }, @layouts ) );

   return 0;

}

# Function  : register_xml( xkb_path ) {{{1
# Arguments : string path to XKB
# Return    : N/A
# Purpose   : Add the key layout's metadata to the XML files
sub register_xml
{

   $log->debug( "Called ::register_xml()" ) if $has_logger;

   # Get the path to xkb
   my $xkb_path = shift;

   if ( defined $xkb_path )
   {
      $log->debug( "XKB path $xkb_path passed as parameter" ) if $has_logger;
   }
   else
   {
      $xkb_path = find_xkb();
      $log->info( "Using $xkb_path as path to XKB" ) if $has_logger;
   }

   # Write to the rules files
   foreach my $rule_filename ( map( $xkb_path . $_ . ".xml", @xkb_files ) )
   {

      if ( rules_exist( $rule_filename ) && ! -e "$rule_filename.orig" )
      {
         print <<EOT
Cannot edit rules file $rule_filename as it already contains some of this
script's layouts. Try reverting from $rule_filename.orig, if it exists.
EOT
         ;

         next;
      }

      print "Writing to $rule_filename\n" if $logger_verbosity >= 0;

      $log->debug( "Making a backup of $rule_filename\n" ) if $has_logger;
      copy( $rule_filename, "$rule_filename.orig" ) 
         unless ( $dry_run || -e "$rule_filename.orig" );

      # Open the files: rules/?.xml for input, a temp file for output
      open( my $fin, '<', $rule_filename )
         or die( "Can't open $rule_filename." );
      my $fout = File::Temp->new() 
         or die( "Can't open temporary output file for $rule_filename" );

      my $line;
      my $layout_definition;

      # Copy up to the beginning of the layout definitions {{{2
      while ( defined( $line = <$fin> ) && $line !~ /<layoutList>/ )
      {
         print $fout $line;
      }

      print $fout $line;

      # Write the layout definitions {{{2
      foreach my $layout ( @$KEYLAYOUTS )
      {
         $layout_definition = <<EOT
<layout>
   <configItem>
      <name>$layout->{layout}</name>
      <shortDescription>$layout->{short_name}</shortDescription>
      <description>$layout->{full_name}</description>
      <languageList><iso639Id>$layout->{language}</iso639Id></languageList>
   </configItem>
EOT
         ;

         # Variants
         if ( defined $layout->{variants} )
         {
            $layout_definition .= "   <variantList>\n";

            foreach my $variant ( @{$layout->{variants}} )
            {

               $layout_definition .= <<EOT
      <variant>
         <configItem>
            <name>$variant->{layout}</name>
            <shortDescription>$variant->{short_name}</shortDescription>
            <description>$variant->{full_name}</description>
         </configItem>
      </variant>
EOT
               ;

            }

            $layout_definition .= "   </variantList>\n";

         } # if variants

         $layout_definition .= "</layout>\n";

         # log the changes before writing
         if ( $has_logger )
         {
            ( my $printable_layout = $layout_definition ) =~ s/^/\t/g;
            $log->debug( "Writing definition for layout $layout->{layout} "
               . "in $rule_filename:\n$printable_layout" );
         }

         print $fout $layout_definition;

      }

      # Copy to the end {{{2
      while ( defined( $line = <$fin> ) )
      {
         print $fout $line;
      }

      # Replace the original layout file with the temp file {{{2
      close( $fout );
      close( $fin );

      if ( ! $dry_run )
      {
         move( $fout->filename, $rule_filename )
            or die( "Can't write to $rule_filename" );
         chmod 0644, $rule_filename;
      }

      # }}}2

   } # foreach rules file

}

# Function  : register_lst( xkb_path ) {{{1
# Arguments : string path to XKB
# Return    : N/A
# Prupose   : Add the key layout's metadata to the .lst files
sub register_lst
{

   $log->debug( "Called ::register_lst()" ) if $has_logger;

   # Get the path to XKB
   my $xkb_path = shift;

   if ( defined $xkb_path )
   {
      $log->debug( "XKB path $xkb_path passed as parameter" ) if $has_logger;
   }
   else
   {
      $xkb_path = find_xkb();
      $log->info( "Using $xkb_path as path to XKB" ) if $has_logger;
   }

   # Write to the rules files
   foreach my $rule_filename ( map( $xkb_path . $_ . ".lst", @xkb_files ) )
   {

      if ( rules_exist( $rule_filename ) && ! -e "$rule_filename.orig" )
      {
         print <<EOT
Cannot edit rules file $rule_filename as it already contains some of this
script's layouts. Try reverting from $rule_filename.orig, if it exists.
EOT
         ;

         next;
      }

      print "Writing to $rule_filename\n" if $logger_verbosity >= 0;

      $log->debug( "Making a backup of $rule_filename\n" ) if $has_logger;
      copy( $rule_filename, "$rule_filename.orig" )
         unless ( $dry_run || -e "$rule_filename.orig" );

      # Open the files
      open( my $fin, '<', $rule_filename )
         or die( "Can't open $rule_filename." );
      my $fout = File::Temp->new()
         or die( "Can't open temporary output file for $rule_filename" );

      my $line;
      my $layout_definition;

      # Copy up to the beginning of layout definitions {{{2
      while ( defined( $line = <$fin> ) && $line !~ /! layout/ )
      {
         print $fout $line;
      }

      print $fout $line;

      # Write the layout definitions {{{2
      foreach my $layout ( @$KEYLAYOUTS )
      {
         my $layout_definition = "$layout->{layout}\t$layout->{short_name}\n";

         if ( $has_logger )
         {
            ( my $printable_layout = $layout_definition ) =~ s/^/\t/;
            $log->debug( "Writing definition for layout $layout->{layout} "
               . "in $rule_filename:\n$printable_layout" );
         }

         print $fout $layout_definition;
      }

      # Copy up to the beginning of variant definitions {{{2
      while ( defined( $line = <$fin> ) && $line !~ /! variant/ )
      {
         print $fout $line;
      }

      print $fout $line;

      # Write the variant definitions {{{2
      foreach my $layout ( @$KEYLAYOUTS )
      {

         foreach my $variant ( @{$layout->{variants}} )
         {
            my $layout_definition = "$variant->{layout}\t$layout->{layout}: $variant->{short_name}\n";

            if ( $has_logger )
            {
               ( my $printable_layout = $layout_definition ) =~ s/^/\t/;
               $log->debug( "Writing definition for variant $variant->{layout} "
                  . "in $rule_filename:\n$printable_layout" );
            }

            print $fout $layout_definition;
         }

      }

      # Copy to the end {{{2
      while ( defined( $line = <$fin> ) )
      {
         print $fout $line;
      }

      # Replace the original layout file with the temp file {{{2
      close( $fout );
      close( $fin );

      if ( ! $dry_run )
      {
         move( $fout->filename, $rule_filename )
            or die( "Can't write to $rule_filename" );
         chmod 0644, $rule_filename;
      }

      # }}}2

   } # foreach rule file

}

# }}}1

help() && exit if ( $print_help );
my $path_to_xkb = find_xkb();

find_layouts();

add_layout_files( $path_to_xkb );

register_xml( $path_to_xkb );
register_lst( $path_to_xkb );
