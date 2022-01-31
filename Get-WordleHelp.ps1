<#
    .SYNOPSIS
    This is a Worlde helper. Currently it only works with known letters, and excluded letters. It doesn't have a way to limit possible solutions based on their position in the word.

    .DESCRIPTION
    The script downloads a Scrabble word list. You enter in known letters and excluded letters based on guesses that you make in Worlde. You will then be presented with all the possible matches. Obviously, the more letters you supply, the fewer matches you'll be given.

    .PARAMETER KnownLetters
    These are the letters in Green, or Orange that you know are in the word.

    .PARAMETER ExcludedLetters
    These are the letters that Worlde indicates are not in the word.

    .PARAMETER Positions
    Use this parameter to indicate letters that are in their correct position (i.e. shown in GREEN). Show unknown letters as '*'.

    .EXAMPLE
    .\Get-WorldleHelp.ps1 -KnownLetters E,Z -ExcludedLetters T,O
    This will search the word database and return all words that contain the letters E, Z, and not contain the letters T, or O.

    .EXAMPLE
    .\Get-WorldleHelp.ps1 -KnownLetters E,Z,A -ExcludedLetters T,O,S,L -Positions *Z***
    This will search the word database and return all words that contain the letters E, Z, A, that do not contain the letters T, O, S, L, but where Z is the second letter.

    .Notes
    Filename: Get-WorldleHelp.ps1
    Contributors: Kieran Walsh
    Created: 2022-01-28
    Last Updated: 2022-01-31
    Version: 0.02.04
#>

[CmdletBinding()]
Param(
    [Parameter()]
    [string[]]$KnownLetters,
    [string[]]$ExcludedLetters,
    [validateLength(5, 5)]
    [string]$Positions
)

if($Wordlist.count -lt 10)
{
    Write-Host 'Gathering wordlist...'
    $URL = 'https://wordfind.com/length/5-letter-words/'
    $Links = (Invoke-WebRequest -Uri $URL -UseBasicParsing | Select-Object -Property *).Links.href
}

$Wordlist = ($Links | Where-Object {$_ -match '/word/'}) -replace '/word/', '' -replace '/', ''
if(-not($Wordlist))
{
    'The word list is empty. Verify that the URL is correct.'
    break
}

Write-Host "The word list contains $($Wordlist.count) words."
$PossibleSolutions = $Wordlist

if($ExcludedLetters)
{
    if($ExcludedLetters -notmatch ',')
    {
        $ExcludedLetters = $ExcludedLetters.ToCharArray()
    }
    foreach($ExcludedLetter in $ExcludedLetters)
    {
        Write-Host "Removing $(($ExcludedLetter).ToUpper())" -NoNewline
        $PossibleSolutions = $PossibleSolutions | Where-Object {$_ -notmatch $ExcludedLetter}
        Write-Host " - $(($PossibleSolutions| Measure-Object).Count) matches remaining."
    }
}

if($KnownLetters)
{
    if($KnownLetters -notmatch ',')
    {
        $KnownLetters = $KnownLetters.ToCharArray()
    }
    foreach($Knownletter in $KnownLetters)
    {
        Write-Host "Matching $(($Knownletter).ToUpper()) " -NoNewline
        $PossibleSolutions = $PossibleSolutions | Where-Object {$_ -match $Knownletter}
        Write-Host " - $(($PossibleSolutions | Measure-Object).Count) matches remaining."

    }
}

if($Positions)
{
    0..4 | ForEach-Object {
        $Position = $_
        if($Positions[$Position] -ne '*')
        {
            Write-Host "Position $($Position + 1) $(([string]($Positions[$Position])).ToUpper())" -NoNewline

            $PossibleSolutions = $PossibleSolutions | Where-Object {$_[$Position] -match $Positions[$Position]}
            Write-Host " - $(($PossibleSolutions | Measure-Object).Count) matches remaining."
        }
    }
}

' '
if((($PossibleSolutions | Measure-Object).Count) -gt 30)
{
    'There are too many potential solutions to list yet. Try another word to narrow the list.'
}
Elseif((($PossibleSolutions | Measure-Object).Count) -lt 1)
{
    Write-Host 'These are no known solutions. Please check your letters and try again.'
}
Else
{
    Write-Host 'These are the possible solutions:'
    ($PossibleSolutions.ToUpper())
}
