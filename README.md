# Get-WordleHelp

Get-WordleHelp downloads an online 5-letter Wordle answer list and narrows possible matches based on:
- letters known to be in the word
- letters known not to be in the word
- optional fixed positions for green letters

Parameters:
- -KnownLetters: letters that must exist in the solution
- -ExcludedLetters: letters that must not exist in the solution
- -Positions: fixed positions using * for unknowns (example: *Z***)
- -MaximumResults: max number of results to print (default 101)

Accepted letter input styles:
- Comma-separated: -KnownLetters E,Z -ExcludedLetters T,O
- Quoted comma-separated: -KnownLetters "E, Z" -ExcludedLetters "T, O"
- Compact string: -KnownLetters EZ -ExcludedLetters TO

Note on spacing:
- Using -KnownLetters E Z (or -ExcludedLetters T O) is not valid for this script signature when called via -File, because PowerShell can bind the extra token to -Positions.
- Prefer comma-separated, quoted comma-separated, or compact string styles.

Example:
- .\Get-WordleHelp.ps1 -KnownLetters E,Z,A -ExcludedLetters T,O,S,L -Positions *Z***

Screenshot:

![img](https://raw.githubusercontent.com/kieranwalsh/img/main/Get-WordleHelp.png)
