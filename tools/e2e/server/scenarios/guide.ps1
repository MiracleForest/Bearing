# U30 Guide on BDS: the server side (`/bearing guide` resolves ids, sends `guide.open` to
# companions only, refuses vanilla clients and the console) and the shipped scene data.
$r = Invoke-SelfTest 'guide.*'
if ($r.Pass -lt 3) { throw "expected 3 guide selftests to pass, got $($r.Pass)" }
$mark = Get-LogMark
Send-Console 'bearing guide shaft'
Wait-LogLine 'Only players can open the guide' 10 -Since $mark | Out-Null