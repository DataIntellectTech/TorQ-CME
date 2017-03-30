.proc.book:{[qt]
  `..book upsert ([] date:"d"$(); time:"p"$(); sym:"s"$(); side:"s"$(); level:"i"$(); orders:"i"$(); size:"f"$(); price:"f"$(); msgseq:"i"$(); rptseq:"i"$();  matchevent:"i"$());

  bbk:(`oc`qty`pc)!(10#0ni;10#0nf;10#0nf);      /bk in fmt order count, qty, price
  abk:(`oc`qty`pc)!(10#0ni;10#0nf;10#0nf);      /define bid and ask books
  ebk:(`BID`OFFER)!(bbk;abk);               /starting empty book

  bdict:(enlist `)!enlist ebk;                  /book state maintaining dictionary
  
  bk0:{[x;y;z;bk] a:.[bk;(z;::;1_ml);:;-1_'bk[z;;ml:x+til 10-x]];.[a;(z;::;x);:;y]};     /enter data y at position x on side z in book bk and shunt down
  bk1:{[x;y;z;bk] .[bk;(z;::;x);:;y]};                                                   /update at position x with data y on side z
  bk2:{[x;y;z;bk] .[bk;(z;::;ml);:;bk[z;;1_ml:x+til 10-x],'(0Ni;0Nf;0Nf)]};              /delete position x from bk side y
  bk3:{[x;y;z;bk] .[bk;(z;::;::);:;(0Ni;0Nf;0Nf)]};                                      /clear side x
  bk4:{[x;y;z;bk] .[bk;(z;::;::);:;bk[z;::;ml:(x+1)+cl:til 10-x+1],'flip (1+x)#enlist(0Ni;0Nf;0Nf)]}; /delete from
  mdua:(`NEW`CHANGE`DELETE`DELETETHRU`DELETEFROM)!(bk0;bk1;bk2;bk3;bk4);                  /action selection based on MDUpdateAction

  /quote and book processor
  /modify the book based on the update action with the above functions, starting with the previous book state (empty book if none)
  /cl takes the modified levels in this action, then take the modified levels from the new book along with duplicated information from this entry to maintain state
  /push to `quote and put the new book in the book state dict
  qtf:{nbk:mdua[x[`MDUpdateAction]][-1+x`MDPriceLevel;(x`NumberOfOrders;x`MDEntrySize;x`MDEntryPx);x`MDEntryType;tbk:$[sum count each raze tbk:bdict[x`Symbol];tbk;ebk]];
    cl:$[`NEW=x`MDUpdateAction;{(x-1)+til 10-(x-1)}x`MDPriceLevel;1];
    `..book insert ((count cl)#'x`TradeDate`TransactTime`Symbol`MDEntryType),(enlist 1+cl),(value nbk[x`MDEntryType;;cl]),(count cl)#'x`MsgSeqNum`RptSeq`MatchEventIndicator;
    bdict[x`Symbol]::nbk
    };
  
  qtf each qt;
  }
