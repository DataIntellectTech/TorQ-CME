// functions for handling incremental refresh messages

/ header & cut keys for incremental refresh
.fix.incr.headerkeys:`TradeDate`MsgSeqNum`SendingTime`TransactTime`MatchEventIndicator`NoMDEntries
.fix.incr.cutkey:`MDUpdateAction

\d .cme

/ process a single quote
singlequote:{[msg]
  .raw.quote,:(cols .raw.quote)#(first each flip 0#.raw.quote),msg;                                // pull out relevant fields, fix types and column names, upsert to global quote table
 }

/ process a single trade
singletrade:{[msg]
  .raw.trade,:(cols .raw.trade)#(first each flip 0#.raw.trade),msg;                                // pull out relevant fields, fix types and column names, upsert to global quote table
 } 

/ dictionary of handlers for incremental message MDEntryTypes
.fix.incr.handlers:`BID`OFFER`IMPLIED_BID`IMPLIED_OFFER`TRADE!(.cme.singlequote;.cme.singlequote;.cme.singlequote;.cme.singlequote;.cme.singletrade);

/ process a single incremental refresh message - pass to quote or trade handler, as applicable
singleincr:{[msg]
  f:$[msg[`MDEntryType] in key .fix.incr.handlers;                                                 // get handler function, default to recording EntryType
      .fix.incr.handlers[msg[`MDEntryType]];                                                       // if there's a handler function, use it
      {.raw.unhandled,:x[`MDEntryType]}                                                            // else record the EntryType in list of unhandled types
  ];
  f msg;                                                                                           // apply returned function to message
 }

/ process MarketDataIncrementalRefresh message - convert to single messages and pass to handler
MARKET_DATA_INCREMENTAL_REFRESH:{[msg]
  header:{[x;y](key[x] inter key[y])#y}[msg;] .fix.incr.headerkeys!msg .fix.incr.headerkeys;       // extract header for this message
  c:where .fix.incr.cutkey=key msg;                                                                // determine where to cut to extract individual quotes/trades
  msgs:header,/:(c cut key msg)!'c cut value msg;                                                  // generate list of single quotes/trades
  singleincr each msgs;                                                                            // pass to handler for single messages
 }
