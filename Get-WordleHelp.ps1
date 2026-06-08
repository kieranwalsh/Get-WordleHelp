function Get-WordleHelp
{
    <#
    .SYNOPSIS
    This is a Wordle helper. Currently it only works with known letters, and excluded letters. It doesn't have a way to limit possible solutions based on their position in the word.

    .DESCRIPTION
    The script downloads a Scrabble word list. You enter in known letters and excluded letters based on guesses that you make in Wordle. You will then be presented with all the possible matches. Obviously, the more letters you supply, the fewer matches you'll be given.

    .PARAMETER KnownLetters
    These are the letters in Green, or Orange that you know are in the word.

    .PARAMETER ExcludedLetters
    These are the letters that Worlde indicates are not in the word.

    .PARAMETER Positions
    Use this parameter to indicate letters that are in their correct position (i.e. shown in GREEN). Show unknown letters as '*'.

    .PARAMETER MaximumResults
    There is no point in listing all the possible matches if there are hundreds. This parameter limits the maximum number of matches that are returned to 50 by default.

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
    Last Updated: 2026-06-08
    Version: 1.00.00
#>

    [CmdletBinding()]
    param(
        [string[]]$KnownLetters,
        [string[]]$ExcludedLetters,
        [validateLength(5, 5)]
        [string]$Positions,
        [int]$MaximumResults = 101
    )

    function ConvertTo-LetterArray
    {
        param(
            [string[]]$InputLetters
        )

        $NormalizedLetters = New-Object 'System.Collections.Generic.List[string]'

        foreach($InputLetter in $InputLetters)
        {
            if([string]::IsNullOrWhiteSpace($InputLetter))
            {
                continue
            }

            foreach($Segment in ($InputLetter -split ','))
            {
                $TrimmedSegment = $Segment.Trim()

                if([string]::IsNullOrWhiteSpace($TrimmedSegment))
                {
                    continue
                }

                $Characters = if($TrimmedSegment.Length -gt 1)
                {
                    $TrimmedSegment.ToCharArray()
                } else
                {
                    @($TrimmedSegment)
                }

                foreach($Character in $Characters)
                {
                    if(([string]$Character) -match '^[A-Za-z]$')
                    {
                        [void]$NormalizedLetters.Add(([string]$Character).ToLower())
                    }
                }
            }
        }

        $NormalizedLetters | Select-Object -Unique
    }

    Write-Host 'Gathering wordlist...'
    $WordlistContent = (Invoke-WebRequest -Uri 'https://gist.githubusercontent.com/cfreshman/a03ef2cba789d8cf00c08f767e0fad7b/raw/5d752e5f0702da315298a6bb5a771586d6ff445c/wordle-answers-alphabetical.txt').Content
    [array]$Wordlist = $WordlistContent -split '\r?\n' | Where-Object {$_}

    if(-not($Wordlist))
    {
        'The word list is empty. Verify that the URL is correct.'
        break
    }

    Write-Host "The word list contains $($Wordlist.count) words."
    $PossibleSolutions = $Wordlist

    if($ExcludedLetters)
    {
        $ExcludedLetters = ConvertTo-LetterArray -InputLetters $ExcludedLetters
        foreach($ExcludedLetter in $ExcludedLetters)
        {
            Write-Host "Removing $(($ExcludedLetter).ToUpper())" -NoNewline
            $PossibleSolutions = $PossibleSolutions | Where-Object {$_ -notmatch $ExcludedLetter}
            Write-Host " - $(($PossibleSolutions| Measure-Object).Count) matches remaining."
        }
    }

    if($KnownLetters)
    {
        $KnownLetters = ConvertTo-LetterArray -InputLetters $KnownLetters
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
    if((($PossibleSolutions | Measure-Object).Count) -gt $MaximumResults)
    {
        'There are too many potential solutions to list yet. Try another word to narrow the list.'
    } elseif((($PossibleSolutions | Measure-Object).Count) -lt 1)
    {
        Write-Host 'These are no known solutions. Please check your letters and try again.'
    } else
    {
        Write-Host "These are the $(($PossibleSolutions | Measure-Object).Count) possible solutions:"
        ($PossibleSolutions.ToUpper())
    }
}
