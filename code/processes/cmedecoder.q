\d .cme

.cme.book:$[`tallbook in key .proc.params;.cme.tallbook;.cme.widebook];   // determine book function to use from process params
.proc.loaddir[getenv[`KDBCODE],"/msgs/"];                                 // load per-message type scripts

/ process one message from log (i.e. one line from text file)
msg:{
  / generate dictionary from message, with correct tags & properly typed values
  msg:(!/) {
    d:.fix.fields each x[;0];                                             // get field name & type from tag number
    enum:0!([] name:d`name)#.fix.enums;                                   // check if field has enumerations
    a:enum[`values]@'enum[`enums]?'x[;1];                                 // get list of un-enumerated values
    val:?[""~/:a;x[;1];a];                                                // if enumeration exists, use it, else use original value from msg
    val:.fix.typefuncs[d`fixtype]@'val;                                   // fix field value type
    (d[`name];val)                                                        // list of name-value pairs
    } flip "I=\001"0:x;                                                   // split message into key-value pairs for processing

  $[msg[`MsgType] in key .cme;                                            // check if msghandler exists
    [msg:override[msg];                                                   // apply any override function defined in code/cmedecoder/override.q for this msgtype
     @[value;(.cme[msg[`MsgType]];msg);                                   // if handler exists, pass & catch errors
          {[msg;x]                                                        // on error, display error message
          .lg.w[`msg] each .util.strdict msg;                             // show failed msg as warning (error will exit process by default)
          .lg.e[`msg;"Error parsing message: ",x];}[msg]                  // show error message (exit process by default)
      ]
    ];
    [.lg.w[`msg;"Missing msg handler: ",string msg[`MsgType]]             // if no handler, display warning about missing handler
     .lg.w[`msg] each .util.strdict msg                                   // also display failed message as warning
    ]
  ];
 }

/ extract gz file to pipe & process
pipegz:{[gzfile]
  .lg.o[`pipegz;"Unzipping and piping to fifo"];
  system"rm -f fifo && mkfifo fifo";                                      // remove any existing fifo, make a new one
  system"zcat ",(1_ string gzfile)," > fifo &";                           // use zcat to extract to fifo
  .lg.o[`pipegz;"Unzipped, parsing"];
  @[.Q.fps[{msg each x}];`:fifo;                                          // use .Q.fps to process file from fifo, catch error & display msg
    {.lg.e[`.proc.pipegz;"Reading form fifo failed, possible corrupt gz file: ",x]}];
  system"rm -f fifo";                                                     // remove fifo when done with it
 }

/ process one log file
logfile:{[logfile]
  if[()~key hsym logfile;                                                 // check file exists
     .lg.e[`logfile;"Logile: ",(string logfile)," not found"];            // error message if not
     :()                                                                  // return early, nothing to do
  ];
  .lg.o[`logfile;"Processing file: ",(string logfile)," with size: ",.util.fmtsize hcount hsym logfile];
  $[logfile like "*.gz";                                                  // check if file is gz compressed
      pipegz[logfile];                                                    // pass compressed files to pipegz
      .Q.fs[{msg each x}] hsym logfile;                                   // for uncompressed files, process directly with .Q.fs
    ];
  .lg.o[`logfile;"Finished processing file: ",string logfile];
 }

\d .

.schema.init[]                                                            // set up empty schemas for processing
.parse.init[]                                                             // parse FIX spec & create tables/dicts for use in processing

.lg.o[`load;"Attempting to load existing definitions & status tables"];
sym:@[get;hsym `$getenv[`DBDIR],"/sym";                                   // attempt to load sym file
      {.lg.w[`load;"Failed to load sym file"]}]                           // warn if unable
.raw.definitions:select from @[get;hsym `$getenv[`DBDIR],"/rawdefinitions/";                    // attempt to load existing definitions table for further updates
                               {.lg.w[`load;"No definitions table found"];.schema.definitions}] // warn if unable
.raw.status:select from @[get;hsym `$getenv[`DBDIR],"/rawstatus/";                              // attempt to load existing status table for further updates
                          {.lg.w[`load;"No status table found"];.schema.status}]                // warn if unable

if[`files in key .proc.params;                                            // if files are passed in cmd line args, begin processing
 .cme.logfile each hsym `$.proc.params[`files];                           // process each file in turn
 if[0 = count .raw.definitions;                                           // if no definitions after processing files, won't be able to make accurate book, warn
    .lg.w[`definition;"No definitions table found. Cannot build accurate book"]
 ];
 .cme.book .raw.quote;                                                    // process raw quote table into book table
 df:`sym xcol select underlying:first SecurityGroup,first DisplayFactor by Symbol from .raw.definitions;  // get underlying and display factor from definitions table
 trade:?[.raw.trade;();0b;.schema.trfieldmaps] lj df;                     // join underlying & display factor to user-friendly trade table
 trade:delete DisplayFactor from update price*DisplayFactor from trade;   // apply diplayfactor to trade table and remove
 writedown[];                                                             // save tables to disk
 ];

if[not `debug in key .proc.params;                                        // if not running in debug mode, exit on completion
 exit 0;
 ];

/
Example Usage

> q torq.q -load code/processes/cmedecoder.q -proctype cmedecoder -procname cmedecoder -files sample/sample_20170101.log
> q torq.q -load code/processes/cmedecoder.q -proctype cmedecoder -procname cmedecoder -files /tmp/CME/CME_DATA/xcme_md_6s_fut_20161012-r-00447.gz
