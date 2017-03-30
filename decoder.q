/ parse params into dict (allowing "debug" mode)
/.params:.Q.opt .z.x

/ load dictionary with FIX msg tags & table with fields
.proc.loadf[getenv[`KDBCODE],"/parse.q"];

/ load additional code scripts
.proc.loadf[getenv[`KDBCODE],"/wide_book.q"];
.proc.loadf[getenv[`KDBCODE],"/schema.q"];
.proc.loadf[getenv[`KDBCODE],"/util.q"];
.proc.loadf[getenv[`KDBCODE],"/write.q"];

\d .proc

/ load per-message type scripts
.proc.loaddir[getenv[`KDBCODE],"/msgs/"];

/ process one message from log
msg:{
  / generate dictionary from message, with correct tags & properly typed values
  msg:(!/) flip {
    / get field name & type from tag number
    d:exec from .fix.fields where number=x[0];
    / check if field has enumerations
    enum:exec from .fix.enums where name=d[`name];
    val:$[null enum[`name];x[1];enum[`values]@enum[`enums]?x[1]];
    / fix field value type
    val:.fix.typefuncs[d[`fixtype]] val;
    (d[`name];val)
   } each flip "I=\001"0:x;
   / check if msghandler exists
   $[msg[`MsgType] in key .proc;
      / if exists, pass & catch errors
      @[value;(.proc[msg[`MsgType]];msg);
           {[msg;x]
            .lg.w[`msg] each .util.strdict msg;
            .lg.e[`msg;"Error parsing message: ",x];}[msg]];
      / if no handler, display warning with msg contents
      [.lg.w[`msg;"Missing msg handler: ",string msg[`MsgType]]
       .lg.w[`msg] each .util.strdict msg]];


 }

pipegz:{[gzfile]
 .lg.o[`pipegz;"Unzipping and piping to fifo"];
 system"rm -f fifo && mkfifo fifo";
 system"zcat ",(1_ string gzfile)," > fifo &";
 .lg.o[`pipegz;"Unzipped, parsing"];
 // zcat can fail silently when writing to fifo, need to handle empty fifo file.
 @[.Q.fps[{msg each x}];`:fifo;{.lg.e[`.proc.pipegz;"Reading form fifo failed, possible corrupt gz file: ",x]}];
 system"rm -f fifo";
 }

/ process one log file
logfile:{[logfile]
  if[()~key hsym logfile;.lg.e[`logfile;"Logile: ",(string logfile)," not found"];:()];
  .lg.o[`logfile;"Processing file: ",(string logfile)," with size: ",.util.fmtsize hcount hsym logfile];
 / pass each line (i.e. each msg) to proc_msg, using .Q.fs for lower mem usage
 / if file is zipped, use zcat to named pipe to .Q.fps in order to process wile unzipping
 $[logfile like "*.gz";
    pipegz[logfile];
    .Q.fs[{msg each x}] hsym logfile;
  ];
 .lg.o[`logfile;"Finished processing file: ",string logfile];
 }

\d .

.schema.init[]
.parse.init[]

/ load existing definitions table if it exists, print warning otherwise
.lg.o[`load;"Attempting to load existing definitions & status tables"];
sym:@[get;hsym `$getenv[`DBDIR],"/sym";{.lg.w[`load;"Failed to load sym file"]}]
.raw.definitions:select from @[get;hsym `$getenv[`DBDIR],"/definitions/";{.lg.w[`load;"No definitions table found"];.schema.definitions}]
.raw.status:select from @[get;hsym `$getenv[`DBDIR],"/status/";{.lg.w[`load;"No status table found"];.schema.status}]


if[`files in key .proc.params;
 .proc.logfile each hsym `$.proc.params[`files];
 .raw.quote:update MDEntryPx*DisplayFactor from .raw.quote lj select first DisplayFactor by Symbol from .raw.definitions;
 .proc.book .raw.quote;
 / generate user-friendly trade table
 trade:delete DisplayFactor from update price*DisplayFactor from ?[.raw.trade;();0b;.schema.trfieldmaps] lj `sym xcol select underlying:first SecurityGroup,first DisplayFactor by Symbol from .raw.definitions;
 writedown[];
 ];

/
Example Usage

> q torq.q -load decoder.q -proctype decoder -procname decoder -files /tmp/CME/CME_DATA/*6S*
> q torq.q -load decoder.q -proctype decoder -procname decoder -files /tmp/CME/CME_DATA/xcme_md_6s_fut_20161012-r-00447.gz
