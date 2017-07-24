//The following code allows users a place to add custom fields before the entries are inserted into the associated tables

\d .cme

/Simple Override set up to allow custom fields to be added.
/This file should be customized to users needs.
overridedict:(`symbol$())!();
override:{[msg]$[msg[`MsgType] in key overridedict;overridedict[msg[`MsgType]];{[msg]msg}][msg]};

missingfields:{[x]if[not `TransactTime in key x;x[`TransactTime]:x[`SendingTime]];
                  if[not `MatchEventIndicator in key x;x[`MatchEventIndicator]:0x0];
                                x};

overridedict[`MARKET_DATA_INCREMENTAL_REFRESH]:missingfields;
