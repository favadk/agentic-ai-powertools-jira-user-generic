# Update Notes and AC Coverage Matrix in TC_OLAC-7456.md
$file = 'c:\Agentic-AI\agentic-ai-powertools-jira-user-new\docs\TestCases\TC_OLAC-7456.md'
$c = [System.IO.File]::ReadAllText($file, [System.Text.Encoding]::UTF8)

# ---- Fix 1: AC-05 row in coverage matrix ----
# Find the entire AC-05 row (from '| AC-05' to end of that line)
$acStart = $c.IndexOf('| AC-05    | Session timeout / logout does not affect already-open help pages')
if ($acStart -lt 0) { Write-Error "AC-05 row not found"; exit 1 }
$acEnd = $c.IndexOf("`n", $acStart) + 1
$oldAcRow = $c.Substring($acStart, $acEnd - $acStart)
Write-Output "Old AC-05 row: [$oldAcRow]"

$covered = [char]0x2705  # actual checkmark emoji
$newAcRow = "| AC-05    | Session timeout / logout does not affect already-open help pages; browser session end (close all windows / machine restart) blocks new access | TC-OLAC-7456-10, TC-OLAC-7456-11 (Scenarios A + B), TC-OLAC-7456-12 (Scenario C) | $covered Covered      |`n"

$c = $c.Replace($oldAcRow, $newAcRow)
Write-Output "AC-05 row replaced: $($c.Contains('Scenarios A + B'))"

# ---- Fix 2: TC-12 note in Notes and Assumptions ----
$noteStart = $c.IndexOf('**TC-12** (Refresh after logout)')
if ($noteStart -lt 0) { Write-Error "TC-12 note not found"; exit 1 }
$noteEnd = $c.IndexOf("`n", $noteStart) + 1
$oldNote = $c.Substring($noteStart, $noteEnd - $noteStart)
Write-Output "Old note: [$oldNote]"

$newNote = @'
**TC-11 and TC-12 -- Three distinct AC-05 scenarios** (all must be tested):
  - **Scenario A** (TC-11 Steps 1-4): Logout -> docs tab still open, no refresh -> docs **still accessible** (AC-05 session live). PASS expected.
  - **Scenario B** (TC-11 Step 5): Logout -> F5 refresh on the **same open tab** -> docs **still accessible** (cookie persists within browser session). PASS expected. Confirmed in OLAC-7530 Cycle 1 Step 7.
  - **Scenario C** (TC-12): Logout -> **close all browser windows OR restart machine** -> open new browser -> navigate to docs -> docs **blocked** (browser session ended, session cookie cleared). PASS expected IF ac_docs_auth is a session cookie; raise finding if persistent.
  These three scenarios together fully define the AC-05 boundary. Scenario C must be run manually due to the machine-restart requirement.
- **TC-12** updated 2026-07-22: original TC incorrectly tested F5 refresh as the blocking trigger. Execution evidence from OLAC-7530 Cycle 1 Step 7 confirmed F5 in the same browser session does NOT block (cookie persists through hub logout). TC-12 now correctly tests the close-all-windows + machine-restart browser-session-end boundary. TC-12 is Manual-only.
'@

$c = $c.Replace($oldNote, "- $newNote")
Write-Output "TC-12 note replaced: $($c.Contains('Three distinct AC-05 scenarios'))"

# Write back
[System.IO.File]::WriteAllText($file, $c, [System.Text.Encoding]::UTF8)
Write-Output "File saved. Size: $((Get-Item $file).Length) bytes"
