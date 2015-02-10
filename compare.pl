#!/usr/bin/perl

my $Usage = qq`
# Usage:
#   compare.pl SOURCE DESTINATION
#
# Output:
#   copy statement for all subdirectories within SOURCE that do not exist in DESTINATION
` ; 

# Directory: Source
my $Source = $ARGV[0] ; 

# Directory: Destination
my $Destination = $ARGV[1] ; 

die "You must specify SOURCE and DESTINATION directories\n" . 
    "( Instead of '$Source' and '$Destination' )\n" . $usage
    unless ( ( -d $Source ) && ( -d $Destination ) ) ; 

  
# Find the directories in Source that are present in Destination
# As well as the directories in Source missing from Destination

sub findPaths { 

    my $Destination = shift ; 
    my (@sourcePaths) = (@_) ;  
    my $dir ; 
    my $destinationPath ; 
    my @presentDestinationDirs ; 
    my @missingDestinationDirs ; 

    foreach $dir ( @sourcePaths ) { 
        $destinationPath = "$Destination/$dir" ;
        if ( -d $destinationPath ) {
            push( @presentDestinationDirs, $dir ) ; 
        } else { 
            push( @missingDestinationDirs, $dir ) ; 
        } 
    }

    return \@presentDestinationDirs, \@missingDestinationDirs ; 
}


# Prepare a copy statement from SOURCE to DESTINATION for each of the specified missing directories

sub prepareCopyStatements {

    my $Source = shift ; 
    my $Destination = shift ; 
    my (@missingDestinationDirs) = (@_) ; 
    my $dir ; 
    my $copyStatement ;
    my @copyStatements ;  
    foreach $dir ( @missingDestinationDirs ) {
        $copyStatement = "cp -R \"$Source/$dir\" \"$Destination/$dir\"" ; 
        push( @copyStatements, $copyStatement ) ; 
    }

    return @copyStatements ;
}

# For each present directory, report on whether the number of files match or not

sub compareDirs { 

    my $Source = shift ; 
    my $Destination = shift ; 
    my (@presentDestinationDirs) = (@_) ; 
    my $dir ; 
    my $sourceCount ; 
    my $destinationCount ; 
    my $message ; 
    my @messages ; 

    foreach $dir ( @presentDestinationDirs ) { 
        $sourceCount = `find \"$Source/$dir\" | wc -l` ; 
        $destinationCount = `find \"$Destination/$dir\" | wc -l` ; 
                chomp $sourceCount ; 
        chomp $destinationCount ;
        if ( $sourceCount > $destinationCount ) { 
            $message = "More files in Source than Destination for $dir : $sourceCount vs. $destinationCount" ;
        } 
        if ( $destinationCount > $sourceCount ) { 
            $message = "Fewer files in Source than Destination for $dir : $sourceCount vs. $destinationCount" ;
        } 
        if ( $destinationCount = $sourceCount ) { 
            $message = "Same number of files in Source and Destination for $dir : $sourceCount vs. $destinationCount" ;
        } 
        push( @messages, $message ) ; 
    }
 
    return @messages ;         
}

sub runReport { 

    my $Source = shift ; 
    my $Destination = shift ; 

    my $title = "     Comparing $Source to $Destination     " ; 
    my $bars = '#' x length($title) ; 
    print "$bars\n$title\n$bars\n" ;

    # Find all existing directories in Source, relative to source 

    my (@rawSourcePaths) = `cd $Source ; find */* -type d -prune`;
    my $rawSourcePath ; 
    foreach $sourcePath ( @rawSourcePaths ) { 
        chomp $sourcePath ; 
        push( @sourcePaths, $sourcePath ) ; 
    }

    my (@presentDestinationDirs) = (@_) ; 
    my $dir ; 
    my $sourceCount ; 
    my $destinationCount ; 
    my $message ;     

    # Find all existing directories in Source that are present in Destination
    # As well as all existing directories in Source that are missing in Destination
    
    my $presentDestinationDirs = undef ; 
    my $missingDestinationDirs = undef ; 
    ( $presentDestinationDirs,         
      $missingDestinationDirs ) = findPaths( $Destination, @sourcePaths ) ;     
    my (@presentDestinationDirs) = @$presentDestinationDirs ;     
    my (@missingDestinationDirs) = @$missingDestinationDirs ;  
            
    # Prepare copy statements for the missing directories    
   
    my (@copyStatements) = prepareCopyStatements( $Source, $Destination, @missingDestinationDirs ) ; 


    # For each present directory, report on whether the number of files match or not

    my (@comparisonMessages) = compareDirs( $Source, $Destination, @presentDestinationDirs ) ; 


    # Print the copy statements

    print join ";\n", @copyStatements, '' ; 

    # Print the comparison statements

    print join ";\n", @comparisonMessages, '' ; 
}


# Run the reports 

runReport( $Source, $Destination ) ; 
runReport( $Destination, $Source ) ; 
