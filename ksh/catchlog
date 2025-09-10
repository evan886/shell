➜  ksh ksh catuplog 
[23:59:25 04/09/2025] Batch job id:RTPDS0231C
[23:59:36 04/09/2025] Result:COMPLETED
➜  ksh cat  catuplog

#!/usr/bin/env ksh
awk '
/Batch job id:/   { job=$0 }
/Result:COMPLETED/ { res=$0 }
END                { print job; print res }
' logfile


