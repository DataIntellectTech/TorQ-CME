// the following code allows users a place to add custom fields before the entries are inserted into the associated tables
\d .cme

/ Simple Override set up to allow custom fields to be added.
/ This file should be customized to users needs.
overridedict:enlist[`]!enlist[{x}];                                       // empty dict for override function (key: msgtype)
override:{[msg]overridedict[msg`MsgType][msg]};                           // lookup override function based on msgtype & apply

/ handle missing fields for incr refresh
missingfields:{[x]
  if[not `TransactTime in key x;x[`TransactTime]:x[`SendingTime]];        // if no TransactTime, use SendingTime
  if[not `MatchEventIndicator in key x;x[`MatchEventIndicator]:0x0];      // if no MEI, use 0x0
  :x;                                                                     // return updated msg
 };

overridedict[`MARKET_DATA_INCREMENTAL_REFRESH]:missingfields;             // add missingfields function as override for incr refresh msgs
