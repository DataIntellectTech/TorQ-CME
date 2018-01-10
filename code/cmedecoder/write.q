// writing tables to disk

/ sort table by column & apply attribute to that column
apply_attr:{[tbl;dt;c]
  c xasc dir:hsym `$"/" sv (dbdir;string dt;tbl);                               // sort table on disk by passed column
  @[dir; c; `p#]                                                                // apply `p attribute
 };

/ write the data down partitioned on date with a `p# attribute on symcol
write_partitioned:{[tbl;dt]
  c:first a where (a:cols tbl) like\: "*[Ss]ym*";                               // find sym/Symbol column
  n:$[tbl like ".raw*";c xcols select from tbl where TradeDate=dt;              // if raw table, date is TradeDate column
      c xcols select from tbl where date=dt];                                   // if processed, date is date column
  .lg.o[`endofday;"Saving ", string tbl];
  tn:(string tbl) except ".";                                                   // name for saving = table name without "."
  (hsym `$"/" sv (dbdir;string dt;tn;"")) upsert .Q.en[hsym `$dbdir] n;         // enumerate and upsert, appending to existing partition if present
  apply_attr[tn;dt;c]                                                           // sort by sym/Symbol & apply `p attribute
 };

/ write the data down splayed to a directory
write_splay:{[tbl;dt]
  n:select from tbl;                                                            // select full table
  .lg.o[`endofday;"Saving ",string tbl];
  tn:(string tbl) except ".";                                                   // name for saving = table name without "."
  (hsym `$"/" sv (dbdir;tn;"")) set .Q.en[hsym `$dbdir] n                       // enumerate and set, overwriting old version
 };

/ call appropriate write function based on table name for each supplied date
write_method:{[d;x]
  $[.schema.savetype[x]~`splay;                                                 // check save type, defined in code/cmedecoder/schema.q
    write_splay[x]'[d];                                                         // write splayed table
    write_partitioned[x]'[d]                                                    // write partitioned table
  ]
 };

writedown:{
  dbdir::getenv[`DBDIR];                                                        // setting db directory pathways
  .lg.o[`writedown;"Writing to disk"];
  x:((` sv' ``raw,/:tables[`.raw]),tables[]) except `heartbeat`logmsg`df;       // get list of tables in the .raw & root namespace
  d:(union/) {exec distinct date from x} each `book`trade;                      // extract the date(s) from the raw tables
  write_method[d]'[x];                                                          // write each table for each date
  .lg.o[`writedown;"Successfully saved to disk"];
 }	
