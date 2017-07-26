.parse.init:{[]
 / cd into spec directory for reading in files etc
 system"cd ",getenv[`TORQHOME],"/spec";

 / convert XML to JSON with python script and parse into variable fix
 fix:.j.k raze system"python xml2json.py -t xml2json FIX44.xml";
 / generate dictionary of message types
 msgtypes:(!/) flip {(`$x[`$"@msgtype"];`$x[`$"@name"])} each fix[`fix][`messages][`message];
 / generate table of FIX fields with tag number, field name and data type
 .fix.fields:flip `number`name`fixtype!flip {("I"$x[`$"@number"];`$x[`$"@name"];`$x[`$"@type"])} each fix[`fix][`fields][`field];

 / manually add custom CME fields - key & lj to overwrite existing fields
 .fix.fields,:("ISS";enlist ",")0:`:cust_fields.csv;

 / generate table with enumerations for fields
 .fix.enums:flip `name`enums`values!flip {(x[0];x[1][`$"@enum"];x[1][`$"@description"])} each c where 0 < count each last flip c:{(`$x[`$"@name"];x[`value])} each fix[`fix][`fields][`field];

 / add custom enumerations
 upd:flip exec name,enums:" " vs' enums,values:" " vs' values from ("S**";enlist ",")0:`:cust_enums.csv;
 / combine existing enums with ones from custom file, then uj to enums table, unkeyed & then keyed on first field i.e. name
 {.fix.enums::(1!0!.fix.enums) uj 1!enlist update first name from $[x[`name] in exec name from .fix.enums;x,'exec from .fix.enums where name=x[`name];x]} each upd;

 / cd back to top level directory
 system"cd ",getenv[`TORQHOME];

 / dictionary of functions to parse data types
 .fix.typefuncs:`LENGTH`STRING`SEQNUM`UTCTIMESTAMP`LOCALMKTDATE`INT`CHAR`CURRENCY`MONTHYEAR`EXCHANGE`QTY`NUMINGROUP`AMT`FLOAT`PRICE`BOOLEANLIST`SYMBOL`EPOCHDATE! (
   {"I"$x};			/LENGTH
   {x};				/STRING
   {"I"$x};			/SEQNUM
   {("D"$8#x)+"T"$8_x};		/UTCTIMESTAMP
   {"D"$x};			/LOCALMKTDATE
   {"I"$x};			/INT
   {`$x};			/CHAR
   {`$x};			/CURRENCY		
   {`month$"D"$(x,"01")};	/MONTHYEAR
   {`$x};			/EXCHANGE
   {"F"$x};			/QTY
   {"I"$x};			/NUMINGROUP
   {"F"$x};			/AMT
   {"F"$x};			/FLOAT
   {"F"$x};			/PRICE
   {`byte$$[0<count x;2 sv "1"=x;0]};		/BOOLEANLIST
   {`$x};			/SYMBOL
   {1970.01.01+"I"$x}		/EPOCHDATE
  );
 }
