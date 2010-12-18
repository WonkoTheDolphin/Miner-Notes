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
my $MergeTargetlessDataButton;

my $SectorSortButton;
my $OreSortButton;

my $GenerateNewFileButton;

my $LoadRawDataButton;

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
    ->pack(-anchor => 'nw', -side => 'top');

$OreListbox = $OtherWidgetsFrame->Listbox(
  -height => 13,
  -background => 'white',
  -listvariable => "@OreTypes")
    ->pack(-anchor => 'ne', -side => 'right');

$DataFileEntry = $MenuFrame->Entry(
  -width => 80,
  -text => $targetlessDataFile,
  -font => $font,
  -background => 'white')
    ->pack(-anchor => 'nw', -side => 'top');


#Menu Buttons

$LoadTargetlessDataButton = $MenuFrame->Button(
  -text => "Load this file",
  -command => [\&LoadTargetlessData, 0])
    ->pack(-anchor => 'nw', -side => 'left');

$MergeTargetlessDataButton = $MenuFrame->Button(
  -text => "Merge this file with current data",
  -command => [\&LoadTargetlessData, 1])
    ->pack(-anchor => 'nw', -side => 'left');

$OreSortButton = $OtherWidgetsFrame->Button(
  -text => "Display data by ore type",
  -command => \&DisplayByOreType)
    ->pack(-anchor => 'se', -side => 'bottom');

$SectorSortButton = $OtherWidgetsFrame->Button(
  -text => "Display data by sector",
  -command => \&DisplayBySectorName)
    ->pack(-anchor => 'se', -side => 'bottom');

$GenerateNewFileButton = $MenuFrame->Button(
  -text => "Generate new targetless file",
  -command => \&GenerateNewTargetlessFile)
    ->pack(-anchor => 'nw', -side => 'right');


#For debugging... uncomment to see this button.
#$LoadRawDataButton = $MenuFrame->Button(-text => 'LRD', -command => \&LoadTargetlessDataRaw)->pack(-anchor => 'nw', -side => 'left');


#=============================================================================
MainLoop();
#=============================================================================

#Subroutines!

#Could stand to think of a better name for this...
sub m_print
{
  $RoidInfoDisplay->Contents("@_");
  $RoidInfoDisplay->idletasks();
}

#Display all data for all rocks, in whatever order they happen to be in.
sub DisplayAllTargetlessData
{
  unless(@RoidList)
  {
    m_print("No data to display!");
    return;
  }

  #Build output data
  my $text = "";

  my $Rock;
  my $CurrSectorID = 0;
  my $OreType;

  foreach $Rock (@RoidList)
  {
    #put a blank line between different sectors
    if ($Rock->{"SectorID"} != $CurrSectorID)
    {
      $CurrSectorID = $Rock->{"SectorID"};
      $text .= "\n";
    }
    
    $text .= $Rock->{"SectorName"} . " (" . $Rock->{"RockID"} . "):";
    
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

  m_print $text;
}

#Display only data on the selected ore
sub DisplayDataForSelectedOre
{
  unless(@RoidList)
  {
    m_print("No data to display!");
    return;
  }

  my $text = "";
  my $OreType = $OreTypes[$OreListbox->index('active')];
  my $Rock;

  $text .= "$OreType:\n\n";

  foreach $Rock (@RoidList)
  {
    if ($Rock->{"$OreType"} > 0)
    {
      $text .= $Rock->{"SectorName"} . " (" . $Rock->{"RockID"} . "): " . $Rock->{"$OreType"} . "%\n";
    }
  }

  m_print $text;
}


#Sorting subroutines
sub DisplayByOreType
{
  unless(@RoidList)
  {
    m_print("No data to display!");
    return;
  }

  m_print "Working, please wait...";
  
  @RoidList = sort BySelectedOre @RoidList;

  DisplayDataForSelectedOre();
}

sub DisplayBySectorName
{
  unless(@RoidList)
  {
    m_print("No data to display!");
    return;
  }

  m_print "Working, please wait...";

  @RoidList = sort BySectorName @RoidList;
  
  DisplayAllTargetlessData();
}

#subs for the builtin sort function
sub BySelectedOre
{
  my $OreType = $OreTypes[$OreListbox->index('active')];
  $b->{"$OreType"} <=> $a->{"$OreType"};
}

sub BySectorName
{
  $a->{"SectorName"} cmp $b->{"SectorName"};
}


#Loading and parsing subroutines

#Loads the targetless data file, and parses it, populating @RoidList
#then displays all data for all rocks.
sub LoadTargetlessData
{
  my $MergeFlag = $_[0];
  my $text = "";
  my $filename = $DataFileEntry->get();

  #Get rid of any file:// at the begining of the filename
  $filename =~ s/^file:\/\///;

  unless (open(TARGETLESSFILE, $filename))
  {
    m_print "Couldn't find file: $filename";
    return;
  }
  $text = <TARGETLESSFILE>; #targetless doesn't use any line breaks
  close TARGETLESSFILE;
  
  #insert line breaks.  I did this for my sanity and to make the data human readable.
  $text =~ s/\}\}([,|;])(\S)/\}\}$1\n$2/g;
  $text =~ s/\}\}"([,|;])(\S)/\}\}"$1\n\n$2/g;
  $text =~ s/="",(\S)/="",\n\n$1/g;

  #Make sure this is a targetless data file.
  unless ($text =~ /^\[\d+\]="/)
  {
    m_print "$filename\ndoes not appear to contain targetless data!";
    return;
  }

  #extract 'roid data
  my $RoidCount = 0;
  my $NewRoidCount = 0;
  my %RockEntry;

  my $Rock;
  my $RepeatRock;

  my $SectorID;
  my $SectorName;
  my @OreData;
  my $OreType;
  my $OreData;

  if ($MergeFlag)
  {
    #Count the data we already have
    $RoidCount = scalar(@RoidList);
  }
  else
  {
    #Clear any current data if not merging
    @RoidList = ();
  }

  #As a sanity check, this won't really do anything unless the file contained data
  #in the format it expected.
  while($text =~ s/^\[(\d+)\]="(\S)/\[$1\]="\n$2/)
  {
    #New Sector ID found!
    #Parse ID to readable system/sector name.
    $SectorID = $1;
    $SectorName = $SystemList[$1 / 256] . " " . $SectorAlphas[(($1 % 256) % 16) - 1] . "-" . int((($1 % 256) / 16) + 1);

    m_print "Massive amounts of asteroid data found!  This may take a moment...\n\nProcessing sector $SectorName...";

    #Remove line with sector ID
    $text =~ s/\S+\n//;

    while($text =~ /^\S+id=(\d+),note=\\"(\S*)\\",ore={(\S+)\}\}/)
    {
      #New rock data found!
      $RockEntry{"SectorID"} = $SectorID;
      $RockEntry{"SectorName"} = $SectorName;
      $RockEntry{"RockID"} = $1;
      $RockEntry{"note"} = $2;
      $RockEntry{"OreData"} = $3;

      $RepeatRock = 0;

      if ($MergeFlag)
      {
	foreach $Rock (@RoidList)
	{
	  if ($Rock->{"SectorID"} == $RockEntry{"SectorID"} && $Rock->{"RockID"} == $RockEntry{"RockID"})
	  {
	    $RepeatRock = 1;
	    last;
	  }
	}
      }
      
      if (!$RepeatRock)
      {
	#initialize the ore data for this rock
	foreach $OreType (@OreTypes)
	{
	  $RockEntry{"$OreType"} = 0;
	}

	#parse the ore data for this rock
	@OreData = split /,\s*/, $RockEntry{"OreData"};
	foreach $OreData (@OreData)
	{
	  $OreData =~ /(\S+)=\\"(\S+)\\"/;
	  $RockEntry{"$1"} = $2;
	}

	#Add the rock to our @RoidList
	$RoidList[$RoidCount] = { %RockEntry };
	$RoidCount++;
	$NewRoidCount++;
      }

      #Remove this rock's entry from the loaded data
      $text =~ s/\S+\n?//;
    }
    
    if ($text =~ /^"/)
    {
      #this Sector ID had no rocks associated with it.
      #Remove the empty line
      $text =~ s/\S+\n//;
    }

    $text =~ s/^\n//;
  }

  if ($RoidCount > 0)
  {
    #Data loading successful!
    if ($MergeFlag)
    {
      m_print "Data successfully merged!\n\n$NewRoidCount new rocks added to dataset for a total of $RoidCount.";
    }
    else
    {
      m_print "Data successfully loaded!\n\n$NewRoidCount rocks found!";
    }
  }
  else
  {
    #Data loading failed!
    m_print "$filename\ndoes not appear to contain targetless data!";
  }
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
  $text =~ s/\}\}([,|;])(\S)/\}\}$1\n$2/g;
  $text =~ s/\}\}"([,|;])(\S)/\}\}"$1\n\n$2/g;
  $text =~ s/="",(\S)/="",\n\n$1/g;
  $text =~ s/\[(\d+)\]="(\S)/\[$1\]="\n$2/g;

  m_print($text);
}


#New data file generation

sub GenerateNewTargetlessFile
{
  unless (@RoidList)
  {
    m_print("No data to save!");
    return;
  }

  my $text = "";
  my $Rock;
  my $CurrSectorID = 0;
  my $filename = $DataFileEntry->get();

  #Get rid of any file:// at the begining of the filename
  $filename =~ s/^file:\/\///;
  $filename .= ".new";

  #check to make sure we can write to this file before doing tons of work.
  unless (open(NEWTARGETLESSFILE, ">$filename"))
  {
    m_print("Error opening $filename for output!");
    return;
  }
  close NEWTARGETLESSFILE;


  @RoidList = sort BySectorName @RoidList;

  foreach $Rock (@RoidList)
  {
    if ($Rock->{"SectorID"} != $CurrSectorID)
    {
      if ($CurrSectorID)
      {
	#Needs a " before the , for all but the first sector
	chop($text);
	$text .= "\",";
      }
      $text .= "[" . $Rock->{"SectorID"} . "]=\"";

      $CurrSectorID = $Rock->{"SectorID"};
    }
    
    m_print "Working, please wait...\n\nProcessing sector " . $Rock->{"SectorName"} . "...";

    $text .= "[" . $Rock->{"RockID"} . "]={id=" . $Rock->{"RockID"} . ",";
    $text .= "note=\\\"" . $Rock->{"note"} . "\\\",";
    $text .= "ore={" . $Rock->{"OreData"} . "}},";
  }

  chop($text);
  $text .= "\"";

  #Spit out the new file
  unless (open(NEWTARGETLESSFILE, ">$filename"))
  {
    m_print("Error opening $filename for output!");
    return;
  }
  print NEWTARGETLESSFILE $text;
  close NEWTARGETLESSFILE;

  m_print "Data successfully saved to $filename\n\nDON'T FORGET TO BACKUP YOUR ORIGINAL TARGETLESS DATA!";
}