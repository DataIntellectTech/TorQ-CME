// parse FIX spec into tables for use in processing

/ initialise tables from spec
.parse.init:{[]
  system"cd ",getenv[`TORQHOME],"/spec";                                               // cd into spec directory for reading in files etc
  fix:.j.k raze system"python xml2json.py -t xml2json FIX44.xml";                      // convert XML to JSON with python script and parse into variable fix
  jn:`$("@number";"@name";"@type";"@msgtype";"@enum";"@description";"value");          // list of JSON field names

  / fields
  .fix.fields:flip "ISS"$'flip `number`name`fixtype xcol jn[0 1 2]#/:fix[`fix][`fields][`field]; // generate table of FIX fields with tag number (@number), field name (@name) and data type (@type)
  .fix.fields:(`number xkey .fix.fields) uj `number xkey ("ISS";enlist ",")0:`:cust_fields.csv;  // manually add custom CME fields
  update number:`u#number from `.fix.fields;                                                     // apply `u attribute to tag number, for speed up

  / enumerations
  c:flip[c] where 0<count each last c:value flip jn[1 6]#/:fix[`fix][`fields][`field]; // extract enumeration details (value) for fields, filter to fields with enumerations (count>0)
  .fix.enums:flip `name`enums`values!flip (`$c[;0]),'.[c;(::;1;jn[4 5])];              // from each enum, extract @enum and @description, join to field name cast to sym
  upd:select name," "vs'enums," "vs'values from ("S**";enlist ",")0:`:cust_enums.csv;  // read custom enumerations from csv, split enums & values
  .fix.enums:raze@''`name xgroup .fix.enums,upd;                                       // group together records based on name, raze together to combine upd with .fix.enums
  update name:`u#name from `.fix.enums;                                                // apply `u attribute to name, for speed up

  system"cd ",getenv[`TORQHOME];                                                       // cd back to top level directory

  / dictionary of functions to parse data types
  .fix.typefuncs:(!/) flip 2 cut                                                       // define dictionary in convenient list format below
    (
    `LENGTH;       {"I"$x};
    `STRING;       {x};
    `SEQNUM;       {"I"$x};
    //`UTCTIMESTAMP; {("D"$8#x)+"T"$8_x};
    `UTCTIMESTAMP; {"P"$((8#x),"D",8_x)};
    `LOCALMKTDATE; {"D"$x};
    `INT;          {"I"$x};
    `CHAR;         {`$x};
    `CURRENCY;     {`$x};
    `MONTHYEAR;    {`month$"D"$(x,"01")};
    `EXCHANGE;     {`$x};
    `QTY;          {"F"$x};
    `NUMINGROUP;   {"I"$x};
    `AMT;          {"F"$x};
    `FLOAT;        {"F"$x};
    `PRICE;        {"F"$x};
    `BOOLEANLIST;  {`byte$$[0<count x;2 sv "1"=x;0]};
    `SYMBOL;       {`$x};
    `EPOCHDATE;    {1970.01.01+"I"$x}
    );
 }
