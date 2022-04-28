<#
    .SYNOPSIS
    This is a Wordle helper. Currently it only works with known letters, and excluded letters.

    .DESCRIPTION
    The script downloads a Scrabble word list. You enter in known letters and excluded letters based on guesses that you make in Worlde. You will then be presented with all the possible matches. Obviously, the more letters you supply, the fewer matches you'll be given.

    .PARAMETER KnownLetters
    These are the letters in Green, or Orange that you know are in the word.

    .PARAMETER ExcludedLetters
    These are the letters that Wordle indicates are not in the word.

    .PARAMETER Positions
    Use this parameter to indicate letters that are in their correct position (i.e. shown in GREEN). Show unknown letters as '*'.

    .PARAMETER MaximumResults
    There is no point in listing all the possible matches if there are hundreds. This parameter limits the maximum number of matches that are returned to 50 by default.

    .PARAMETER WrongPositions
    Use this parameter to pass in a hashtable holding places where you know letters are not located i.e. shown in ORANGE

    .EXAMPLE
    .\Get-WordleHelp.ps1 -KnownLetters E,Z -ExcludedLetters T,O
    This will search the word database and return all words that contain the letters E, Z, and not contain the letters T, or O.

    .EXAMPLE
    .\Get-WordleHelp.ps1 -KnownLetters E,Z,A -ExcludedLetters T,O,S,L -Positions *Z***
    This will search the word database and return all words that contain the letters E, Z, A, that do not contain the letters T, O, S, L, but where Z is the second letter.
    
    .EXAMPLE
    .\Get-WordleHelp.ps1 -KnownLetters cir -ExcludedLetters metalcoinssavertchirpearthagentcommaextra -Positions **I** -WrongPositions @{0='c'}
    This will search the word database and return all words that contain the letters C, I, and R.
    It will exclude all the letters in the ExcludedLetters that are not C, I, and R.
    It will also restrict the words to those where the 3rd letter is an I.
    Finally, it will remove words where the first character is a C.
    
    .EXAMPLE
    .\Get-WordleHelp.ps1 -KnownLetters bert -WrongPositions @{0 = 't'; 2 = 'ub'; 4 = 't'}
    Without the -WrongPositions parameter, this will return 6 results:
    BERET
    BERTH
    BRUTE
    REBUT
    TRIBE
    TUBER
    With the -WrongPositions parameter, we exlude all words that start with a T, leaving BERET, BERTH, BRUTE, REBUT.
    Then exclude all words that have a U or a B in the middle position, leaving BERET, BERTH
    Finally, excluding all words that end with a T, leaving just BERTH

    .Notes
    Filename: Get-WorldleHelp.ps1
    Contributors: Kieran Walsh
    Created: 2022-01-28
    Last Updated: 2022-02-01
    Version: 0.02.06
#>

[CmdletBinding()]
Param(
    [string[]]$KnownLetters,
    [string[]]$ExcludedLetters,
    [validateLength(5, 5)]
    [string]$Positions,
    [int]$MaximumResults = 101,
    [hashtable] $WrongPositions
)

Write-Host 'Gathering wordlist...'
[array]$Wordlist = ((Invoke-WebRequest -Uri 'https://gist.githubusercontent.com/cfreshman/a03ef2cba789d8cf00c08f767e0fad7b/raw/5d752e5f0702da315298a6bb5a771586d6ff445c/wordle-answers-alphabetical.txt').content).Split([Environment]::NewLine, [StringSplitOptions]::RemoveEmptyEntries)

if(-not($Wordlist))
{
    'The word list is empty. Verify that the URL is correct.'
    break
}

Write-Host "The word list contains $($Wordlist.count) words."
$PossibleSolutions = $Wordlist
$possibleCount = ($possibleSolutions | Measure-Object).Count

if($ExcludedLetters)
{
    $seenExclusions = [Collections.Generic.SortedSet[char]]::new()
    
    if($ExcludedLetters -notmatch ',')
    {
        $ExcludedLetters = $ExcludedLetters.ToCharArray()
    }
    foreach($ExcludedLetter in $ExcludedLetters)
    {
        # If we've already seen it, we don't need to strip it out again...
        if ($ExcludedLetter -in $seenExclusions) { continue }
        $null = $seenExclusions.Add($excludedLetter)
        
        # If it's in -KnownLetters (and we actually pass in -KnownLetters) then we don't have to exlude it
        if ($KnownLetters -and $ExcludedLetter -in $KnownLetters.ToCharArray()) {
            Write-Warning "[$($ExcludedLetter.ToUpper())] is also a Knownletter, skipping..."
            continue
        }
    
        Write-Host "Removing $(($ExcludedLetter).ToUpper())" -NoNewline
        
        $PossibleSolutions = $PossibleSolutions | Where-Object {$_ -notmatch $ExcludedLetter}
        $possibleCount = ($possibleSolutions | Measure-Object).Count
        
        Write-Host " - $possibleCount matches remaining."
    }
}

if($KnownLetters)
{
    $seenKnown = [Collections.Generic.SortedSet[char]]::new()
    
    if($KnownLetters -notmatch ',')
    {
        $KnownLetters = $KnownLetters.ToCharArray()
    }
    foreach($Knownletter in $KnownLetters)
    {
        Write-Host "Matching $(($Knownletter).ToUpper()) " -NoNewline
        $PossibleSolutions = $PossibleSolutions | Where-Object {$_ -match $Knownletter}
        
        if ($knownLetter -in $seenKnown) {
            Write-Verbose "Matching double letters for [$KnownLetter]"
            $possibleSolutions = $possibleSolutions |
            ForEach-Object -Process {
                $potential = $_
                     
                $doubleLetters = $potential.ToCharArray() |
                Group-Object |
                Where-Object { $_.Name -eq $knownLetter -and $_.Count -gt 1}
                        
                if ($doubleLetters) {
                   $potential
                }
                        
                Clear-Variable -Name doubleLetters
            }
        }
        
        $possibleCount = ($possibleSolutions | Measure-Object).Count
        
        
        Write-Host " - $possibleCount matches remaining."
        $null = $seenKnown.Add($knownLetter)
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
            $possibleCount = ($possibleSolutions | Measure-Object).Count
            
            Write-Host " - $possibleCount matches remaining."
        }
    }
}

if ($WrongPositions) {
    Write-Verbose "Removing known wrong positions"
        0..4 | ForEach-Object -Process {
            $position = $_
            $wrong = $WrongPositions[$position]
            if ($wrong) {
                $wrong = $wrong.ToCharArray() 
                foreach ($wrongChar in $wrong) {
                    $possibleSolutions = $possibleSolutions | Where-Object { $_[$position] -ne $wrongChar }
                    $possibleCount = ($possibleSolutions | Measure-Object).Count

                    Write-Host "Position [$position $(($wrongChar).ToString().ToUpper())] removed - [$possibleCount] matches remaining."
                }
            }
        }
    }

' '
if ($possibleCount -gt $MaximumResults)
{
    'There are too many potential solutions to list yet. Try another word to narrow the list.'
}
Elseif ($possibleCount -lt 1)
{
    Write-Host 'These are no known solutions. Please check your letters and try again.'
}
Else
{
    Write-Host "These are the $possibleCount possible solutions:"
    ($PossibleSolutions.ToUpper())
}
