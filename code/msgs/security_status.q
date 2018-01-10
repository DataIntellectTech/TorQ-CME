// functions to handle security status messages

\d .cme

SECURITY_STATUS:{[msg]
  `.raw.status upsert .Q.en[hsym `$getenv[`DBDIR]] enlist (cols .raw.status)#(first each flip 0#.raw.status),msg        // join msg to typed null dict (ensure correct cols), enumerate & upsert
 }
