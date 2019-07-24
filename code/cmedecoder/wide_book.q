//build book in the "wide" format

.cme.widebook:{[tab]
 t:update MDEntryPx^MDEntryPx*DisplayFactor from tab lj select first DisplayFactor by Symbol from .raw.definitions;
 / extract prices & sizes from book column
 t:update bprice:{exec price from x where side=`BID}'[book],
        bsize:{exec size from x where side=`BID}'[book],
        aprice:{exec price from x where side=`OFFER}'[book],
        asize:{exec size from x where side=`OFFER}'[book]
 from 

 / create temporary book column
 update book:{[state;action;px;lvl;sz;sd;mtch;sym]
  `level xasc $[action=`CHANGE;
    state upsert (lvl;sd;px;sz);
   action=`NEW;
    delete from ((update level+1 from state where level>=lvl,side=sd) upsert (lvl;sd;px;sz)) where level > .raw.dfltlvl^exec last MarketDepth from .raw.definitions where Symbol = sym;
   action=`DELETE;
    update level-1 from (delete from state where level=lvl,side=sd) where level>lvl,side=sd;
   action=`DELETETHRU;
    delete from state where side=sd;
  /action=`DELETEFROM
    update level-lvl from (delete from state where level<=lvl,side=sd) where level>lvl,side=sd
   ]}\[([level:();side:()] price:();size:());MDUpdateAction;MDEntryPx;MDPriceLevel;MDEntrySize;MDEntryType;MatchEventIndicator;Symbol]
 by Symbol
 from update SecurityDesc^Symbol from t;
   
 / delete temporary book column
 t:0!select by MsgSeqNum from delete book from t;
 `..book upsert ?[t;();0b;.schema.qtfieldmaps] lj `sym xcol select underlying:first SecurityGroup by Symbol from .raw.definitions
  }
