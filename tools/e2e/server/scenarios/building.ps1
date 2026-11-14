# Building blocks (U10) on BDS: every building selftest (registration, connected textures, panes,
# stairs, slabs, copper wax / scrape / weathering, doors, redstone, scaffolding, ladders, girders,
# placard, copycats, brackets), then a door opened by redstone, built with /setblock.
$r = Invoke-SelfTest 'building.*'
if ($r.Pass -lt 15) { throw "expected at least 15 building selftests to pass, got $($r.Pass)" }

Send-Console 'tickingarea add 16 -64 16 31 0 31 br_building'
Wait-Seconds 3
$mark = Get-LogMark
Send-Console 'setblock 20 -58 20 bearing:train_door ["bearing:facing"=3]'
Send-Console 'setblock 20 -57 20 bearing:train_door ["bearing:facing"=3,"bearing:upper"=1]'
Wait-Seconds 1
Send-Console 'setblock 21 -58 20 redstone_block'
Wait-LogLine 'building: bearing:train_door at 20 -58 20 opened by redstone' 15 -Since $mark | Out-Null
Send-Console 'setblock 21 -58 20 air'
Wait-LogLine 'building: bearing:train_door at 20 -58 20 closed by redstone' 15 -Since $mark | Out-Null
Send-Console 'setblock 20 -58 20 air'
Send-Console 'setblock 20 -57 20 air'
Send-Console 'tickingarea remove br_building'
