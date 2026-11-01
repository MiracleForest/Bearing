# Transmission (U6) on BDS: every transmission selftest (shafts, cogs, gearbox, clutch / gearshift,
# chain drives, speed controller, sequenced gearshift, gauges, placement rules, the sequencer
# screen, U49: cuckoo clocks and the flywheel), then a line built with /setblock: a clutch powered by a
# redstone block from the console, and a cuckoo clock that cuckoos at noon.
$r = Invoke-SelfTest 'transmission.*'
if ($r.Pass -lt 14) { throw "expected at least 14 transmission selftests to pass, got $($r.Pass)" }
Wait-LogLine 'transmission: sequenced gearshift at .* runs instruction 1 \(turn_angle\)' 10 | Out-Null
Wait-LogLine 'transmission: speed controller at .* targets -48 RPM' 10 | Out-Null
Wait-LogLine 'transmission: .* placed bearing:shaft at .* by placement assist' 10 | Out-Null

Send-Console 'tickingarea add 0 -64 0 15 0 15 br_transmission'
Wait-Seconds 3
$mark = Get-LogMark
Send-Console 'setblock 2 -58 6 bearing:kinetics_test_source ["bearing:axis"=0]'
Send-Console 'setblock 3 -58 6 bearing:clutch ["bearing:axis"=0]'
Send-Console 'setblock 4 -58 6 bearing:shaft ["bearing:axis"=0]'
Wait-Seconds 1
Send-Console 'create kinetics 4 -58 6'
Wait-LogLine 'kinetics: Speed: 16 RPM' 15 -Since $mark | Out-Null
Send-Console 'setblock 3 -57 6 redstone_block'
Wait-LogLine 'transmission: bearing:clutch at .* powered' 15 -Since $mark | Out-Null
Wait-Seconds 1
$mark2 = Get-LogMark
Send-Console 'create kinetics 4 -58 6'
Wait-LogLine 'kinetics: Speed: 0 RPM' 15 -Since $mark2 | Out-Null
Send-Console 'setblock 3 -57 6 air'
Wait-LogLine 'transmission: bearing:clutch at .* unpowered' 15 -Since $mark | Out-Null
Send-Console 'tickingarea remove br_transmission'

# U49: a turning cuckoo clock (shaft at its back, south) cuckoos when the world's time is noon
Send-Console 'tickingarea add 0 -64 0 15 0 15 br_transmission_clock'
Wait-Seconds 3
$mark = Get-LogMark
Send-Console 'setblock 6 -58 6 bearing:cuckoo_clock ["bearing:horizontal_facing"=2]'
Send-Console 'setblock 6 -58 7 bearing:kinetics_test_source ["bearing:axis"=2]'
Wait-Seconds 1
Send-Console 'time set 6000'
Wait-LogLine 'transmission: cuckoo clock at .* starts the pig animation' 15 -Since $mark | Out-Null
Send-Console 'setblock 6 -58 6 air'
Send-Console 'setblock 6 -58 7 air'
Send-Console 'tickingarea remove br_transmission_clock'
