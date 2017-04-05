/ functions to handle security definition messages

\d .cme

/ process SecurityDefintion msgs into definitions table
SECURITY_DEFINITION:{[msg]
  / pull out relevant fields, fix types and column names, upsert to global definitions table
  `.raw.definitions upsert .Q.en[hsym `$getenv[`DBDIR]] enlist (cols .raw.definitions)#(first each flip 0#.raw.definitions),msg;
  } 

