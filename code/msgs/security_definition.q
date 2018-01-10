// functions to handle security definition messages

\d .cme

/ process SecurityDefintion msgs into definitions table
SECURITY_DEFINITION:{[msg]
  `.raw.definitions upsert .Q.en[hsym `$getenv[`DBDIR]] enlist (cols .raw.definitions)#(first each flip 0#.raw.definitions),msg; // join msg to typed null dict (ensure correct cols), enumerate & upsert
  } 

