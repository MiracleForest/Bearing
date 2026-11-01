# Assembly (U15): every assembly selftest (sequenced assembly engine, deployer placing / punching /
# recipes / swapping / redstone lock / capability, mechanical arm selection / placement /
# transfers / value box), then a deployer and an arm built from the console and running on their
# own, with their log lines.
$r = Invoke-SelfTest 'assembly.*'
if ($r.Pass -lt 15) { throw "expected at least 15 assembly selftests to pass, got $($r.Pass)" }
# U39: a precision mechanism finished by a deployer over a depot, two deployers fist bumping
Wait-LogLine 'deployer at .* applied bearing:cogwheel to bearing:golden_sheet' 10 | Out-Null
Wait-LogLine 'deployers at .* and .* fist bumped' 10 | Out-Null

# A deployer facing east, turned by a test source, places what it holds (given by the selftest
# helpers through its capability is not reachable from the console: it punches instead).
Send-Console 'tickingarea add 0 -64 0 15 -40 15 br_assembly_e2e true'
Wait-Seconds 3
Send-Console 'setblock 4 -60 4 dirt'
Send-Console 'setblock 2 -60 4 bearing:deployer ["bearing:facing"=5,"bearing:axis_along_first"=0]'
Send-Console 'setblock 2 -60 3 bearing:kinetics_test_source ["bearing:axis"=2]'
Wait-Seconds 1
$mark = Get-LogMark
Send-Console 'create kinetics 2 -60 4'
Wait-Seconds 1
# a mechanical arm next to it with a composter
Send-Console 'setblock 8 -60 8 bearing:mechanical_arm'
Send-Console 'setblock 8 -61 8 bearing:kinetics_test_source ["bearing:axis"=1]'
Wait-Seconds 2
Send-Console 'create kinetics 8 -60 8'
Wait-LogLine 'mechanical_arm' 20 -Since $mark | Out-Null
Send-Console 'setblock 2 -60 3 air'
Send-Console 'setblock 2 -60 4 air'
Send-Console 'setblock 4 -60 4 air'
Send-Console 'setblock 8 -60 8 air'
Send-Console 'setblock 8 -61 8 air'
Send-Console 'tickingarea remove br_assembly_e2e'
