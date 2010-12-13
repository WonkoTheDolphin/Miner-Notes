#! /usr/bin/perl -w

use strict;

use Tk;
use Tk::Font;
use Tk::TextUndo;

#Here's hoping this doesn't change from one person to the next!
my $targetlessDataFile = 'system741937notes.txt';
my $ScreenWidth = 950;
my $ScreenHeight = 760;

#Widgets!
my $MainWindow;
my $font;

#A Scrolled TextUndo for displaying data. Maybe I'll make this a pretty Scrolled Canvas some day...
my $RoidInfoDisplay;

#Buttons
my $LoadTargetlessDataButton;
my $DisplayAllDataButton;

my $SectorSortButton;
my $OreSortButton;

#A Listbox for selecting an ore type
my $OreListbox;


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


$LoadTargetlessDataButton = $MainWindow->Button(
  -text => 'Load data from targetless file',
  -command => \&LoadTargetlessData)
    ->place(-y => 0, -x => 0);

$OreListbox = $MainWindow->Listbox(
  -height => 13,
  -listvariable => "@OreTypes")
    ->place(-y => 0, -x => 750);

$SectorSortButton = $MainWindow->Button(
  -text => "Sort data by sector",
  -command => \&SortBySectorID)
    ->place(-y => 0, -x => 300);

$OreSortButton = $MainWindow->Button(
  -text => "Sort data by ore type",
  -command => \&SortByOreType)
    ->place(-y => 0, -x => 600);

$RoidInfoDisplay = $MainWindow->Scrolled('TextUndo',
  -width => 80,
  -height => 20,
  -font => $font,
  -insertofftime => 0)
    ->place(-y => 290, -x => 0);


#=============================================================================
MainLoop();
#=============================================================================

#Subroutines!

#Display all data for all rocks, in whatever order they happen to be in.
sub DisplayAllTargetlessData
{
  #Build output data
  my $newtext = "";

  my $rock;
  my $currSectorID = 0;
  my $OreType;

  foreach $rock (@RoidList)
  {
    #put a blank line between different sectors
    if ($rock->{"SectorID"} ne $currSectorID)
    {
      $currSectorID = $rock->{"SectorID"};
      $newtext .= "\n";
    }
    
    $newtext .= $rock->{"SectorID"} . " (" . $rock->{"RockID"} . "):";
    
    foreach $OreType (@OreTypes)
    {
      if ($rock->{"$OreType"} > 0)
      {
	$newtext .= " $OreType, " . $rock->{"$OreType"} . ";";
      }
    }

    #Don't need the final ;
    chop($newtext);
    $newtext .= "\n";
  }
  $newtext =~ s/^\n//;

  $RoidInfoDisplay->Contents($newtext);
}

#Display only data on the selected ore
sub DisplayDataForSelectedOre
{
  my $text = "";
  my $rock;

  my $OreType = $OreTypes[$OreListbox->index('active')];

  $text .= "$OreType:\n\n";

  foreach $rock (@RoidList)
  {
    if ($rock->{"$OreType"} > 0)
    {
      $text .= $rock->{"SectorID"} . " (" . $rock->{"RockID"} . "): " . $rock->{"$OreType"} . "%\n";
    }
  }

  $RoidInfoDisplay->Contents($text);
}


#Sorting subroutines
sub SortByOreType
{
  @RoidList = sort BySelectedOre @RoidList;

  DisplayDataForSelectedOre();
}

sub SortBySectorID
{
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


#Loads the targetless data file, and parses it, populating @RoidList
#then displays all data for all rocks.
sub LoadTargetlessData
{
  $RoidInfoDisplay->Load('system741937notes.txt');
  my $text = $RoidInfoDisplay->Contents();
  my $newtext = "";
  
  #insert line breaks.  I did this for my sanity and to make the data human readable.
  $text =~ s/\}\}(,|;)(\S)/\}\}$1\n$2/g;
  $text =~ s/\}\}"(,|;)(\S)/\}\}"$1\n\n$2/g;
  $text =~ s/="",(\S)/="",\n\n$1/g;

  #extract 'roid data
  my $RoidCount = 0;
  my %RockEntry;

  my $SectorID;
  my @OreData;
  my $OreData;

  my $OreType;

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
  $RoidInfoDisplay->Load($targetlessDataFile);
  my $text = $RoidInfoDisplay->Contents();

  #insert line breaks for readability
  $text =~ s/\}\}(,|;)(\S)/\}\}$1\n$2/g;
  $text =~ s/\}\}"(,|;)(\S)/\}\}"$1\n\n$2/g;
  $text =~ s/="",(\S)/="",\n\n$1/g;
  $text =~ s/\[(\d+)\]="(\S)/\[$1\]="\n$2/g;

  $RoidInfoDisplay->Contents($text);
}