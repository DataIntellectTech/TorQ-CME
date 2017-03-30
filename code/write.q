/ Apply attributes
apply_attr:{[tbl;dt;c]
  c xasc dir:hsym `$"/" sv (dbdir;string dt;tbl);
  @[dir; c; `p#]
 };

/ Write the data down partitioned on date with a `p# attribute on symcol
write_partitioned:{[tbl;dt]
  c:first a where (a:cols tbl) like\: "*[Ss]ym*";
 
  n:$[tbl like ".raw*";c xcols select from tbl where TradeDate=dt; 
      c xcols select from tbl where date=dt];
	  
  .lg.o[`endofday;"Saving ", string tbl];
 
  tn:(string tbl) except ".";
  (hsym `$"/" sv (dbdir;string dt;tn;"")) upsert .Q.en[hsym `$dbdir] n;
	
  apply_attr[tn;dt;c]
 };

/ Write the data down splayed to a directory
write_splay:{[tbl;dt]
  (n:`$5_string tbl) set select from tbl;
  .lg.o[`endofday;"Saving ",string tbl];
  (hsym `$"/" sv (dbdir;string n;"")) set .Q.en[hsym `$dbdir] value tbl
 };


writedown:{
	/ Setting db directory pathways
	dbdir::getenv[`DBDIR];

	.lg.o[`writedown;"Writing to disk"]; 
	
	/ Get tables in the .raw & root namespace
        x:((` sv' ``raw,/:tables[`.raw]),tables[]) except `heartbeat`logmsg;

	/ Extract the date from the file being processed
	d:distinct "D"$'8#'last each "_" vs' .proc.params[`files];

	/ Conditional to determine how each table is saved down
	/ Dictionary of write down methods held in schema.q in .schema.savetype	
	write_method:{[x;d] $[.schema.savetype[x]~`splay; write_splay[x]'[d];
		write_partitioned[x]'[d]]};

	write_method[;d]'[x];
	
	.lg.o[`writedown;"Successfully saved to disk"];
 }	
