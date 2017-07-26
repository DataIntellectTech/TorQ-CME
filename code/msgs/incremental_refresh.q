/ functions for handling incremental refresh messages

/ header & cut keys for incremental refresh
.fix.incr.headerkeys:`TradeDate`MsgSeqNum`SendingTime`TransactTime`MatchEventIndicator`NoMDEntries
.fix.incr.cutkey:`MDUpdateAction

\d .cme

/ process a single quote
singlequote:{[msg]
 / pull out relevant fields, fix types and column names, upsert to global quote table
  .raw.quote,:(cols .raw.quote)#(first each flip 0#.raw.quote),msg;
  }

/ process a single trade
singletrade:{[msg]
 / pull out relevant fields, fix types and column names, upsert to global quote table
 .raw.trade,:(cols .raw.trade)#(first each flip 0#.raw.trade),msg;
 } 

/ dictionary of handlers for incremental message MDEntryTypes
.fix.incr.handlers:`BID`OFFER`IMPLIED_BID`IMPLIED_OFFER`TRADE!(.cme.singlequote;.cme.singlequote;.cme.singlequote;.cme.singlequote;.cme.singletrade);

/ process a single incremental refresh message - pass to quote or trade handler, as applicable
singleincr:{[msg]
 / get handler function, default to recording EntryType
 $[msg[`MDEntryType] in key .fix.incr.handlers;
    .fix.incr.handlers[msg[`MDEntryType]];
     {.raw.unhandled,:x[`MDEntryType]}
     / apply returned function to message
   ] msg;
 }

/ process MarketDataIncrementalRefresh message - convert to single messages and pass to handler
MARKET_DATA_INCREMENTAL_REFRESH:{[msg]
 / extract header for this message
 header:{[x;y](key[x] inter key[y])#y}[msg;] .fix.incr.headerkeys!msg .fix.incr.headerkeys;
 / determine where to cut to extract individual quotes/trades
 c:where .fix.incr.cutkey=key msg;
 / generate list of single quotes/trades
 msgs:header,/:(c cut key msg)!'c cut value msg;
 / pass to handler for single messages
 singleincr each msgs;
 }
