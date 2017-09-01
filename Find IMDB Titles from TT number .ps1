###################################
### Michael O'Rourke
### 8/30/2017
### Find IMDB Titles from TT number 
###################################

function Get-IMDBItemHTML
{
    <#
    .Synopsis
       Retrieves information about a movie/tv show etc. from IMDB.
    .DESCRIPTION
       This cmdlet fetches information about the movie/tv show matching the specified ID from IMDB.
       The ID is often seen at the end of the URL at IMDB.
    .EXAMPLE
        Get-IMDBItem -ID tt0848228
    .EXAMPLE
       Get-IMDBMatch -Title 'American Dad!' | Get-IMDBItem
 
       This will fetch information about the item(s) piped from the Get-IMDBMatch cmdlet.
    .PARAMETER ID
       Specify the ID of the tv show/movie you want get. The ID has the format of tt0123456
    #>
 
    [cmdletbinding()]
    param([Parameter(Mandatory=$True, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
          [string[]] $ID)
 
    BEGIN { }
 
    PROCESS {
        foreach ($ImdbID in $ID) {
 
            $IMDBItem = Invoke-WebRequest -Uri "http://www.imdb.com/title/$ImdbID" -UseBasicParsing
 
            $ItemInfo = (($IMDBItem.Content -split "<div id=`"title-overview-widget`" class=`"heroic-overview`">")[1] -split "<div id=`"sidebar`">")[0]
 
            $ItemTitle = (($ItemInfo -split "<h1 itemprop=`"name`" class=`"`">")[1] -split "&nbsp;")[0]
           
            If (($ItemInfo -split "itemprop=`"datePublished`" content=`"").Length -gt 1) {
                $Type = "Movie"
                [DateTime]$Released = (($ItemInfo -split "<meta itemprop=`"datePublished`" content=`"")[1] -split "`" />")[0]
            } Else {
                $Type = "TV Series"
                $Released = $null
            }
 
            $Description = ((($ItemInfo -split "<div class=`"summary_text`" itemprop=`"description`">")[1] -split "</div>")[0]).Trim()
           
            $Rating = (($ItemInfo -split "<span itemprop=`"ratingValue`">")[1] -split "</span>")[0]
           
            $GenreSplit = $ItemInfo -split "itemprop=`"genre`">"
            $NumGenres = ($GenreSplit.Length)-1
            $Genres = foreach ($Genre in $GenreSplit[1..$NumGenres]) {
                ($Genre -split "</span>")[0]
            }
 
            $MPAARating = (($ItemInfo -split "<meta itemprop=`"contentRating`" content=`"")[1] -split "`">")[0]
 
            try {
                $RuntimeMinutes = New-TimeSpan -Minutes (($ItemInfo -split "<time itemprop=`"duration`" datetime=`"PT")[1] -split "M`">")[0]
            }
            catch {
                $RuntimeMinutes = $null
            }
 
            if ($Description -like '*Add a plot*') {
                $Description = $null
            }
 
            $Properties = @{
                Type = "$Type"
                Title = "$ItemTitle"
                Genre = "$Genres"
                Description = "$Description"
                Released = "$Released"
                RuntimeMinutes = "$RuntimeMinutes"
                Rating = "$Rating"
                MPAARating = "$MPAARating"
            }
            $returnObject = New-Object -TypeName PSObject -Property $Properties
           
            Write-Output $returnObject
 
            Remove-Variable IMDBItem, ItemInfo, ItemTitle, Genres, Description, Released, Type, Rating, RuntimeMinutes, MPAARating -ErrorAction SilentlyContinue
        }
    }
 
    END { }
}


# Get the IDs of the movies in the file path
$TTIDs = Get-ChildItem -path "H:\Movies" | Select -Property "Name" 

# Initialize the array
$MovieWithTitle = @()

# Initialize the count variables
$Count = 0
$Count2 = 0

# Remove .m4v from the end of the Movie IDs
# Get the Name of each of the movies from the ID
foreach ($ID in $TTIDs.Name) {

    # Get to the next ID
    $TTID = $TTIDs[$Count]  

    if ($TTID.Name -like "tt*") {
    
        $ID = $ID.Replace(".m4v","")

        $Movie = Get-IMDBItemHTML $ID

        # Remove Special Characters 
        # This is a bad method to do this but it works
        $Movie = $Movie.Title 
        $Movie = $Movie.Replace(":","")
        $Movie = $Movie.Replace("/","")
        $Movie = $Movie.Replace("\","")
        $Movie = $Movie.Replace("|","")
        $Movie = $Movie.Replace("<","")
        $Movie = $Movie.Replace(">","")
        $Movie = $Movie.Replace("?","")
        $Movie = $Movie.Replace("!","")
        $Movie = $Movie.Replace("'","")
        $Movie = $Movie.Replace('"',"")
        $Movie = $Movie.Replace("*","")

        try {
            
            $Error.clear()

            # Rename the items to the actual name from the ID
            Rename-Item -Path "H:\Movies\$($TTID.Name)" -NewName "$Movie.m4v" -ErrorAction Stop
        
        } catch {
        
            Write-Host "$Error" -ForegroundColor Red

        }

    } else {
    
        Write-Host "Skipping Rename $($TTID.Name)" -ForegroundColor Cyan
        
    }   

    # Iterate to the next one
    $Count = $Count + 1

}


<#
# Removes .m4v if you have extras tacked on

 if ($TTID.Name -like "*.m4v") {
    
        $ID = $ID.Replace(".m4v","")

        try {
            
            $Error.clear()

            Rename-Item -Path "H:\Movies\$($TTID.Name)" -NewName "$ID" -ErrorAction Stop
        
        } catch {
        
            Write-Host "$Error" -ForegroundColor Red

        }

    } else {
    
        Write-Host "Skipping remove .m4v $($TTID.Name)" -ForegroundColor Cyan
    
}
#>


<#
# If you delete all the .m4v 

Write-Host "Changing $($TTID.Name) to .m4v format" -ForegroundColor Cyan
    
try {
            
    $Error.clear()

    Rename-Item -Path "H:\Movies\$($TTID.Name)" -NewName "$($TTID.Name).m4v" -ErrorAction Stop
        
} catch {
        
    Write-Host "$Error" -ForegroundColor Red

}
#>




