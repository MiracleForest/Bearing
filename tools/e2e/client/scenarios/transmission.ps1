# Transmission (U6) on a real client: every block of the unit in a wall in front of the player,
# a driven line with both gauges, and the sequenced gearshift screen opened by right-clicking it.
#   local / remote-mod: the client mod spins the rotating parts and draws the eased gauge needles
#                       (log "transmission client: drawing N gauge needles"); right-clicking the
#                       sequenced gearshift opens the native instruction screen
#   remote-vanilla:     static models (needles at their 22.5 degree steps) and the form fallback
# U50: a large cogwheel right-clicked on a mechanical mixer lands on its diagonal (placement helper).
# Screenshots: out/transmission/{wall,wall-b,gauges,sequencer-screen,integrated-cog}.png
$withMod = $script:Mode -ne 'remote-vanilla'
$mark    = Get-LogMark

# content errors about our blocks / models / textures (transmission.prelaunch.ps1 turned the log on)
$logDir = Join-Path (Get-GameDataDir) 'logs'
$contentLog = Get-ChildItem $logDir -Filter 'ContentLog*' -ErrorAction SilentlyContinue |
    Where-Object { $_.LastWriteTime -ge $script:TransmissionContentLogStart } | Sort-Object LastWriteTime -Descending | Select-Object -First 1
if ($contentLog) {
    $pattern = 'transmission|bearing:(shaft|cogwheel|large_cogwheel|gearbox|vertical_gearbox|clutch|gearshift|encased_chain_drive|adjustable_chain_gearshift|andesite_encased|brass_encased|sequenced_gearshift|rotation_speed_controller|speedometer|stressometer)'
    $errors = Select-String -Path $contentLog.FullName -Pattern $pattern | ForEach-Object { $_.Line }
    if ($errors) {
        $errors | Set-Content (Join-Path (Join-Path $script:OutRoot $script:Unit) 'content-errors.txt')
        throw "content log reports $(@($errors).Count) problem(s) with the transmission blocks (content-errors.txt): $($errors | Select-Object -First 3)"
    }
}

if ($withMod -and $script:Mode -eq 'local') {
    $r = Invoke-SelfTest 'transmission.*'
    if ($r.Pass -lt 10) { throw "expected at least 10 transmission selftests to pass, got $($r.Pass)" }
}

Invoke-Chat '/gamemode creative'
Invoke-Chat '/time set noon'
Invoke-Chat '/fill ~-2 ~ ~-8 ~12 ~6 ~8 air'
# look east at a wall 6 blocks ahead
Invoke-Chat '/tp @s ~ ~ ~ -90 10'
Start-Sleep -Milliseconds 500

# row 1 (y+1): shafts and cogs along x, driven by a source behind them
Invoke-Chat '/setblock ~7 ~1 ~-6 bearing:kinetics_test_source ["bearing:axis"=0]'
Invoke-Chat '/setblock ~6 ~1 ~-6 bearing:shaft ["bearing:axis"=0]'
Invoke-Chat '/setblock ~7 ~1 ~-4 bearing:kinetics_test_source ["bearing:axis"=0]'
Invoke-Chat '/setblock ~6 ~1 ~-4 bearing:cogwheel ["bearing:axis"=0]'
Invoke-Chat '/setblock ~6 ~2 ~-4 bearing:cogwheel ["bearing:axis"=0]'
Invoke-Chat '/setblock ~7 ~1 ~-2 bearing:kinetics_test_source ["bearing:axis"=0]'
Invoke-Chat '/setblock ~6 ~1 ~-2 bearing:large_cogwheel ["bearing:axis"=0]'
Invoke-Chat '/setblock ~7 ~1 ~1 bearing:kinetics_test_source ["bearing:axis"=0]'
Invoke-Chat '/setblock ~6 ~1 ~1 bearing:gearbox ["bearing:axis"=1]'
Invoke-Chat '/setblock ~5 ~1 ~1 bearing:shaft ["bearing:axis"=0]'
Invoke-Chat '/setblock ~6 ~1 ~2 bearing:shaft ["bearing:axis"=2]'
Invoke-Chat '/setblock ~7 ~1 ~4 bearing:kinetics_test_source ["bearing:axis"=0]'
Invoke-Chat '/setblock ~6 ~1 ~4 bearing:gearshift ["bearing:axis"=0,"bearing:powered"=1]'
Invoke-Chat '/setblock ~5 ~1 ~4 bearing:shaft ["bearing:axis"=0]'
Invoke-Chat '/setblock ~7 ~1 ~6 bearing:kinetics_test_source ["bearing:axis"=0]'
Invoke-Chat '/setblock ~6 ~1 ~6 bearing:clutch ["bearing:axis"=0]'
# row 2 (y+3): encased blocks, chain drives, sequenced gearshift, controller
Invoke-Chat '/setblock ~6 ~3 ~-6 bearing:andesite_encased_shaft ["bearing:axis"=0]'
Invoke-Chat '/setblock ~6 ~3 ~-5 bearing:brass_encased_shaft ["bearing:axis"=1]'
Invoke-Chat '/setblock ~6 ~3 ~-3 bearing:andesite_encased_cogwheel ["bearing:axis"=0,"bearing:top_shaft"=1]'
Invoke-Chat '/setblock ~6 ~3 ~-1 bearing:brass_encased_large_cogwheel ["bearing:axis"=0,"bearing:bottom_shaft"=1]'
Invoke-Chat '/setblock ~6 ~3 ~1 bearing:encased_chain_drive ["bearing:axis"=0]'
Invoke-Chat '/setblock ~6 ~3 ~2 bearing:adjustable_chain_gearshift ["bearing:axis"=0]'
Invoke-Chat '/setblock ~6 ~3 ~4 bearing:sequenced_gearshift ["bearing:axis"=0]'
Invoke-Chat '/setblock ~6 ~3 ~6 bearing:rotation_speed_controller ["bearing:axis"=2]'
Invoke-Chat '/setblock ~6 ~4 ~6 bearing:large_cogwheel ["bearing:axis"=0]'
Start-Sleep -Seconds 2
if ($withMod) {
    Invoke-Chat '/create kinetics ~7 ~1 ~-6 speed 32'
    Wait-LogLine 'kinetics client: drawing \d+ rotating parts' 30 | Out-Null
}
Start-Sleep -Seconds 2
Save-Screenshot 'wall' | Out-Null
Start-Sleep -Milliseconds 400
Save-Screenshot 'wall-b' | Out-Null

# at eye level: a driven line with both gauges facing the player (west), 3 blocks ahead
Invoke-Chat '/setblock ~3 ~1 ~-3 bearing:kinetics_test_source ["bearing:axis"=2]'
Invoke-Chat '/setblock ~3 ~1 ~-2 bearing:speedometer ["bearing:facing"=4,"bearing:along_first"=0]'
Invoke-Chat '/setblock ~3 ~1 ~-1 bearing:shaft ["bearing:axis"=2]'
Invoke-Chat '/setblock ~3 ~1 ~0 bearing:stressometer ["bearing:facing"=4,"bearing:along_first"=0]'
Invoke-Chat '/setblock ~3 ~1 ~1 bearing:kinetics_test_consumer ["bearing:axis"=2]'
# a sequenced gearshift on the ground 2 blocks ahead
Invoke-Chat '/setblock ~2 ~ ~ bearing:sequenced_gearshift ["bearing:axis"=0]'
Invoke-Chat '/tp @s ~ ~ ~ -90 10'
if ($withMod) { Wait-LogLine 'transmission client: drawing \d+ gauge needles' 30 | Out-Null }
Start-Sleep -Seconds 2
Save-Screenshot 'gauges' | Out-Null

# right-click the sequenced gearshift (with an item in hand: the game only sends block clicks
# with an empty hand for interactive blocks; Create opens the screen with any item but the wrench)
Invoke-Chat '/replaceitem entity @s slot.weapon.mainhand 0 stick'
Invoke-Chat '/tp @s ~ ~ ~ -90 35'
Start-Sleep -Milliseconds 800
$mark2 = Get-LogMark
Click 0.5 0.5 -Relative -Right
if ($withMod) {
    Wait-LogLine 'screen transmission.sequenced_gearshift opened for .* \(native\)' 20 -Since $mark2 | Out-Null
} else {
    Wait-LogLine 'screen transmission.sequenced_gearshift opened for .* \(form\)' 20 -Since $mark2 | Out-Null
}
Start-Sleep -Milliseconds 1200
Save-Screenshot 'sequencer-screen' | Out-Null
Close-Screen
if ($withMod) {
    Wait-LogLine 'transmission: sequenced gearshift at .* configured' 20 -Since $mark2 | Out-Null
}

# U50: a large cogwheel used on the west face of a mechanical mixer (an integrated cog, axis y)
# goes to the mixer's north-west diagonal, axis y (Create's DiagonalCogHelper), and meshes with it.
# The mixer at eye level 3 blocks east, driven by a cogwheel south of it on a source.
Invoke-Chat '/fill ~1 ~ ~-4 ~6 ~3 ~4 air'
Invoke-Chat '/setblock ~3 ~1 ~ bearing:mechanical_mixer'
Invoke-Chat '/setblock ~3 ~ ~1 bearing:kinetics_test_source ["bearing:axis"=1]'
Invoke-Chat '/setblock ~3 ~1 ~1 bearing:cogwheel ["bearing:axis"=1]'
# the south-west diagonal is taken: a hit on the face's middle line (north / south tie) can only go north-west
Invoke-Chat '/setblock ~2 ~1 ~1 stone'
Invoke-Chat '/replaceitem entity @s slot.weapon.mainhand 0 bearing:large_cogwheel'
Invoke-Chat '/tp @s ~ ~ ~ -90 0'
Start-Sleep -Milliseconds 800
$mark3 = Get-LogMark
Click 0.5 0.5 -Relative -Right
Wait-LogLine 'transmission: .* placed bearing:large_cogwheel at .* by placement assist' 20 -Since $mark3 | Out-Null
Start-Sleep -Milliseconds 600
# the source only speeds up (a logged line) when the large cog stands at the diagonal with axis y
Invoke-ChatConfirmed '/execute if block ~2 ~1 ~-1 bearing:large_cogwheel ["bearing:axis"=1] run create kinetics ~3 ~ ~1 speed 24' 'Generator at -?\d+ -?\d+ -?\d+ now turns at 24 ' -Attempts 2 | Out-Null
Invoke-Chat '/tp @s ~ ~ ~ -90 20'
Start-Sleep -Seconds 2
Save-Screenshot 'integrated-cog' | Out-Null
Assert-NoErrors
