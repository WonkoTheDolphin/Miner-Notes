#! /usr/bin/perl -w

use strict;

use Tk;
use Tk::Font;

#Here's hoping this doesn't change from one person to the next!
my $targetlessDataFile = './system741937notes.txt';
my $ScreenWidth = 950;  #Mad arbitrary.  This could use some thought...
my $ScreenHeight = 760;

#Widgets!
my $MainWindow;
my $font;

my $MenuFrame;
my $DisplayFrame;
my $OtherWidgetsFrame;

#A Scrolled Text for displaying data. Maybe I'll make this a pretty Scrolled Canvas some day...
my $RoidInfoDisplay;

#A Listbox for selecting an ore type
my $OreListbox;

#An entry for choosing what file to load.
my $DataFileEntry;


#Buttons
my $LoadTargetlessDataButton;
my $DisplayAllDataButton;

my $SectorSortButton;
my $OreSortButton;



#Structure for the 'roid data,
#A list of pointers to hashes.  ex: $RoidList[x]->{"SectorID"}
my @RoidList;

#Useful stuff:
my @OreTypes = (
  "Heliocene",
  "Pentric",
  "Apicene",
  "Pyronic",
  "Denic",
  "Lanthanic",
  "Xithricite",
  "VanAzek",
  "Ishik",
  "Ferric",
  "Carbonic",
  "Silicate",
  "Aquean");

my @SystemList = (
  "Sol II",
  "Betheshee",
  "Geira Rutilus",
  "Deneb",
  "Eo",
  "Cantus",
  "Metana",
  "Setalli Shinas",
  "Itan",
  "Pherona",
  "Artana Aquilus",
  "Divinia",
  "Jallik",
  "Edras",
  "Verasi",
  "Pelatus",
  "Bractus",
  "Nyrius",
  "Dau",
  "Sedina",
  "Azek",
  "Odia",
  "Latos",
  "Arta Caelestis",
  "Ukari",
  "Helios",
  "Initros",
  "Pyronis",
  "Rhamus",
  "Dantia",
  "Devlopia");
#That's right... Devlopia.

my @SectorAlphas = ("A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P");

#=============================================================================

#Onward!
$MainWindow = new MainWindow(
  -width => $ScreenWidth,
  -height => $ScreenHeight);

$font = $MainWindow->Font(
  -family => 'Courier',
  -size => 14);


#Frames

$MenuFrame = $MainWindow->Frame(
  -width => "$ScreenWidth",
  -height => 80)
    ->pack(-anchor => 'nw', -side => 'top');

$DisplayFrame = $MainWindow->Frame(
  -width => $ScreenWidth,
  -height => $ScreenHeight - 40)
    ->pack(-anchor => 'sw', -side => 'bottom');

$OtherWidgetsFrame = $MainWindow->Frame(
  -width => 100,
  -height => $ScreenHeight)
    ->pack(-anchor => 'e', -side => 'right');


#Major widgets

$RoidInfoDisplay = $DisplayFrame->Scrolled('Text',
  -width => 100,
  -height => 20,
  -font => $font,
  -background => 'white',
  -insertofftime => 0)
    ->pack();

$OreListbox = $OtherWidgetsFrame->Listbox(
  -height => 13,
  -background => 'white',
  -listvariable => "@OreTypes")
    ->pack();

$DataFileEntry = $MenuFrame->Entry(
  -width => 80,
  -text => $targetlessDataFile,
  -font => $font,
  -background => 'white')
    ->pack(-anchor => 'nw');


#Menu Buttons

$LoadTargetlessDataButton = $MenuFrame->Button(
  -text => 'Load data from targetless file',
  -command => \&LoadTargetlessData)
    ->pack(-anchor => 'nw', -side => 'left');

$OreSortButton = $MenuFrame->Button(
  -text => "Sort data by ore type",
  -command => \&SortByOreType)
    ->pack(-anchor => 'ne', -side => 'right');

$SectorSortButton = $MenuFrame->Button(
  -text => "Sort data by sector",
  -command => \&SortBySectorID)
    ->pack(-anchor => 'ne', -side => 'right');


#=============================================================================
MainLoop();
#=============================================================================

#Subroutines!

#Display all data for all rocks, in whatever order they happen to be in.
sub DisplayAllTargetlessData
{
  #Build output data
  my $text = "";

  my $Rock;
  my $CurrSectorID = 0;
  my $OreType;

  foreach $Rock (@RoidList)
  {
    #put a blank line between different sectors
    if ($Rock->{"SectorID"} ne $CurrSectorID)
    {
      $CurrSectorID = $Rock->{"SectorID"};
      $text .= "\n";
    }
    
    $text .= $Rock->{"SectorID"} . " (" . $Rock->{"RockID"} . "):";
    
    foreach $OreType (@OreTypes)
    {
      if ($Rock->{"$OreType"} > 0)
      {
	$text .= " $OreType, " . $Rock->{"$OreType"} . "%;";
      }
    }

    #Don't need the final ;
    chop($text);
    $text .= "\n";
  }

  #Get rid of a newline added at the begining.
  $text =~ s/^\n//;

  $RoidInfoDisplay->Contents($text);
}

#Display only data on the selected ore
sub DisplayDataForSelectedOre
{
  my $text = "";
  my $OreType = $OreTypes[$OreListbox->index('active')];
  my $Rock;

  $text .= "$OreType:\n\n";

  foreach $Rock (@RoidList)
  {
    if ($Rock->{"$OreType"} > 0)
    {
      $text .= $Rock->{"SectorID"} . " (" . $Rock->{"RockID"} . "): " . $Rock->{"$OreType"} . "%\n";
    }
  }

  $RoidInfoDisplay->Contents($text);
}


#Sorting subroutines
sub SortByOreType
{
  @RoidList or return;

  $RoidInfoDisplay->Contents("Working, please wait...");
  $RoidInfoDisplay->idletasks();

  @RoidList = sort BySelectedOre @RoidList;

  DisplayDataForSelectedOre();
}

sub SortBySectorID
{
  @RoidList or return;

  $RoidInfoDisplay->Contents("Working, please wait...");
  $RoidInfoDisplay->idletasks();

  @RoidList = sort BySectorID @RoidList;
  
  DisplayAllTargetlessData();
}

#subs for the builtin sort function
sub BySelectedOre
{
  my $OreType = $OreTypes[$OreListbox->index('active')];
  $b->{"$OreType"} <=> $a->{"$OreType"};
}

sub BySectorID
{
  $a->{"SectorID"} cmp $b->{"SectorID"};
}


#Loading and parsing subroutines

#Loads the targetless data file, and parses it, populating @RoidList
#then displays all data for all rocks.
sub LoadTargetlessData
{
  my $text = "";
  my $filename = $DataFileEntry->get();

  #Get rid of any file:// at the begining of the filename
  $filename =~ s/^file:\/\///;

  unless (open(TARGETLESSFILE, $filename))
  {
    $RoidInfoDisplay->Contents("Couldn't find file: $filename");
    return;
  }
  $text = <TARGETLESSFILE>; #targetless doesn't use any line breaks
  close TARGETLESSFILE;
  
  #insert line breaks.  I did this for my sanity and to make the data human readable.
  $text =~ s/\}\}(,|;)(\S)/\}\}$1\n$2/g;
  $text =~ s/\}\}"(,|;)(\S)/\}\}"$1\n\n$2/g;
  $text =~ s/="",(\S)/="",\n\n$1/g;

  #Make sure this is a targetless data file.
  unless ($text =~ /^\[\d+\]="\S/)
  {
    $RoidInfoDisplay->Contents("$filename\ndoes not appear to contain targetless data!");
    return;
  }

  $RoidInfoDisplay->Contents("Massive amounts of asteroid data found!\n\nWorking, please wait...");
  $RoidInfoDisplay->idletasks();

  #extract 'roid data
  my $RoidCount = 0;
  my %RockEntry;

  my $SectorID;
  my @OreData;
  my $OreData;

  my $OreType;

  #Clear any current data
  @RoidList = [];

  #As a sanity check, this won't really do anything unless the file contained data
  #in the format it expected.
  while($text =~ s/\[(\d+)\]="(\S)/\[$1\]="\n$2/)
  {
    #New Sector ID found!
    #Parse ID to readable system/sector name.
    $SectorID = $SystemList[$1 / 256] . " " . $SectorAlphas[(($1 % 256) % 16) - 1] . "-" . int((($1 % 256) / 16) + 1);

    #Remove line with sector ID
    $text =~ s/\S*\n//;

    while($text =~ /^\S+id=(\d+),\S+,ore={(\S+)\}\}/)
    {
      #New rock data found!
      $RockEntry{"SectorID"} = $SectorID;
      $RockEntry{"RockID"} = $1;
      $OreData = $2;
      
      #initialize the ore data for this rock
      foreach $OreType (@OreTypes)
      {
	$RockEntry{"$OreType"} = 0;
      }

      #parse the ore data for this rock
      @OreData = split /,\s*/, $OreData;
      foreach $OreData (@OreData)
      {
	$OreData =~ /(\S+)=\\"(\S+)\\"/;
	$RockEntry{"$1"} = $2;
      }

      #Add the rock to our @RoidList
      $RoidList[$RoidCount] = { %RockEntry };
      $RoidCount++;

      #Remove this rock's entry from the loaded data
      $text =~ s/\S*\n//;
    }
    
    if ($text =~ /^"/)
    {
      #this Sector ID had no rocks associated with it.
      #Remove the empty line
      $text =~ s/\S*\n//;
    }

    $text =~ s/\n//;
  }

  DisplayAllTargetlessData();
}

#Loads the contents of the targetless data file without parsing it
#Left this in from when I was first writing things.
sub LoadTargetlessDataRaw
{
  my $text = "";
  my $filename = $DataFileEntry->get();

  #Get rid of any file:// at the begining of the filename
  $filename =~ s/^file:\/\///;

  open(TARGETLESSFILE, $filename) or return;
  $text = <TARGETLESSFILE>; #targetless doesn't use any line breaks
  close TARGETLESSFILE;

  #insert line breaks for readability
  $text =~ s/\}\}(,|;)(\S)/\}\}$1\n$2/g;
  $text =~ s/\}\}"(,|;)(\S)/\}\}"$1\n\n$2/g;
  $text =~ s/="",(\S)/="",\n\n$1/g;
  $text =~ s/\[(\d+)\]="(\S)/\[$1\]="\n$2/g;

  $RoidInfoDisplay->Contents($text);
}