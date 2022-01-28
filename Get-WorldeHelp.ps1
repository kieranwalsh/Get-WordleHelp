<#
    .SYNOPSIS
    This is a Worlde helper. Currently it only works with known letters, and excluded letters. It doesn't have a way to limit possible solutions based on their position in the word.

    .DESCRIPTION
    The script downloads a Scrabble word list. You enter in known letters and excluded letters based on guesses that you make in Worlde. You will then be presented with all the possible matches. Obviously, the more letters you supply, the fewer matches you'll be given.

    .PARAMETER KnownLetters
    These are the letters in Green, or Orange that you know are in the word.

    .PARAMETER ExcludedLetters
    These are the letters that Worlde indicates are not in the word.

    .EXAMPLE
    .\Get-WorldeHelp.ps1 -KnownLetters E,Z -ExcludedLetters T,O
    This will search the word database and return all words that contain the letters E, Z, and not contain the letters T, or O.

    .Notes
    Filename: Get-WorldeHelp.ps1
    Contributors: Kieran Walsh
    Created: 2022-01-28
    Last Updated: 2022-01-28
    Version: 0.01.01
#>

[CmdletBinding()]
Param(
    [Parameter()]
    [string[]]$KnownLetters,
    [string[]]$ExcludedLetters
)

if($Wordlist.count -lt 10)
{

    Write-Host 'Gathering wordlist...'
    $URL = 'https://wordfind.com/length/5-letter-words/'
    $Links = (Invoke-WebRequest -Uri $URL -UseBasicParsing | Select-Object -Property *).Links.href
}

if(-not($Wordlist))
{
    'The word list is empty. Verify that the URL is correct.'
    break
}
$Wordlist = ($Links | Where-Object {$_ -match '/word/'}) -replace '/word/', '' -replace '/', ''

Write-Host "The word list contains $($Wordlist.count) words."
$Matched = $Wordlist

if($ExcludedLetters)
{
    foreach($ExcludedLetter in $ExcludedLetters)
    {
        Write-Host "Removing $ExcludedLetter" -NoNewline
        $Matched = $Matched | Where-Object {$_ -notmatch $ExcludedLetter}
        Write-Host " - $(($Matched | Measure-Object).Count) matches remaining."
    }
    $PossibleSolutions = $Matched
}

if($KnownLetters)
{
    foreach($Knownletter in $KnownLetters)
    {
        Write-Host "Matching $Knownletter" -NoNewline
        $PossibleSolutions = $PossibleSolutions | Where-Object {$_ -match $Knownletter}
        Write-Host " - $(($PossibleSolutions | Measure-Object).Count) matches remaining."

    }
}
' '
Write-Host 'These are the possible solutions:'
$PossibleSolutions
