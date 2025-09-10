
#!/usr/bin/env ksh
awk '
/Batch job id:/   { job=$0 }
/Result:COMPLETED/ { res=$0 }
END                { print job; print res }
' logfile

