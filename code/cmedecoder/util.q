// utility functions

\d .util

/ convert file size (bytes) to human readable representation
fmtsize:{.Q.f[2;x%2 xexp 10*b],(" KMGT" b:floor 0.1*a:2 xlog x),"B"}

/ convert a dictionary to string representation for console output, logging etc.
strdict:{[d]((max count each a)$/:a:string key d),'" | ",/:raze each string value d}
