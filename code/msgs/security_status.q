/ functions to handle security status messages

\d .proc

SECURITY_STATUS:{[msg] `.raw.status upsert .Q.en[hsym `$getenv[`DBDIR]] enlist (cols .raw.status)#(first each flip 0#.raw.status),msg} / f - market data security status
