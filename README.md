# CME Datamine

## Parsing Historical Data from the Chicago Mercantile Exchange

The Chicago Mercantile Exchange (CME) is an American financial and commodity derivative exchange, offering a highly liquid market for futures and options on currencies, interest rates, indices and commodities. It is the largest exchange of futures and options in the world, and as such contains a wealth of useful market data.

The CME makes available for purchase historical and realtime market data in the form of FIX/FAST format messages from its CME Globex trading platform. These messages are used to track the level-aggregated status of orders (i.e. level 2 data), trades executed, book updates, and information on individual securities and security groups.

The Globex data available historically can be of use in transaction cost analysis of previously executed trades, inter-market comparison of derivative prices and liquidity, feeding algorithmic trading systems, or determination of the market risk of holdings. However, first it must be converted from the raw FIX messages provided by the CME Globex Market Data Platform, which may contain complex level 2 market information in multiple sections of a single message, into a more useful, manageable format. 

This codebase presents a method for processing historical data from the CME, building and maintaining an order book, and writing this data to disk in a variety of approaches suited to query efficiency, space efficiency or a balance between the two. Our example data set is FX futures contracts of 11 major currency pairs, but this method should equally apply to all historical CME market data.

## Requirements


Basic knowledge of the q programming language and linux commands is assumed.
This system has been tested on KDB v3.4, release date 2016.12.23 on a x86_64 system running Ubuntu 14.04

### Software Requirements


- KDB v3.4+
- Python
- zcat (optional, needed for gzipped logfiles)

### Data Requirements


This software is designed to process CME MDP 3.0 FIX historical data (FIX Version 4.4), this data is not provided by this software and can be obtained from [CME Group](https://datamine.cmegroup.com/)

A sample file is available [here](https://github.com/jonathonmcmurray/cme/blob/master/sample/sample.log).


## Capabilities


### The CME parser is designed to complete the following tasks:


- Parse CME MDP 3.0 FIX messages from both extracted and gzipped files on disk.
- Store these messages as raw Quote, Trade and Security Definition tables (with the raw CME FIX data fields).
- Build an order book from the Quote table with as many levels as the Security Definition states.
- Derive more traditional user-friendly Quote and Trade tables from the above tables.
- Save these tables to disk.


### Features of the CME parser:


- The parser is designed to process files as quickly as possible in order for the data to be available quickly after it is published.
- Reads data in from the file in chunks to minimize memory usage while parsing data.
- The codebase is reasonably flexible to small changes in CME specification, in case of updates to the CME MDP format.
- Allows for flexibility on how the data is stored on disk.
	- Narrow Book table takes up less space on disk, but has less granularity in the data.
	- Wide Book table takes up more space on disk, but can retain more data about the order and state of the book at given time.
	- Optionally store raw CME messages as quote, trade and security definition tables on disk.
- The process can be started easily from the command line and passed paths of files in either explicit or wildcard format.
- The process can be monitored by reading log files split into out (information messages), err (Errors) and usage (Inter-process communication).

### Limitations:


- The parser can only process raw and gzipped CME MDP 3.0 FIX log files, if the data is compressed in a different format the files will need to be manually decompressed.
- The parser cannot process real time data, it is designed to parse CME FIX MDP 3.0 historical datamine logfiles. If you would like information on how to parse, store and query realtime cme data, please contact [AquaQ](mailto:info@aquaq.co.uk).

## Getting Started:

- These bash commands will give directions on downloading TorQ and our FIX message package. The FIX package will be placed on top of the base TorQ package.
	
1. Make a directory to check the git repos into, and a directory to deploy the system to.

		~/cme$ mkdir git deploy
		~cme$ ls
		deploy  git
	
2. Change to the git directory and clone the FIX parser and TorQ repositories.

		~/cme$ cd git
		~/cme/git$ git clone https://github.com/AquaQAnalytics/TorQ-CME.git
		~/cme/git$ git clone https://github.com/AquaQAnalytics/TorQ.git
		~/cme/git$ ls
		TorQ-CME  TorQ
	
3. Change to the deploy directory and copy the contents of TorQ into it.

		~/cme/git$ cd ../deploy/
 		~/cme/deploy$ cp -r ../git/TorQ/* ./
	
4. Copy the contents of the FIX parsers repo into the same directory, allowing overwrites.

		~/cme/deploy$ cp -r ../git/TorQ-CME/* ./

You should have a of combination each directories content included in the deploy direcotry:

	~/cme/deploy$ ls
	aquaq-torq-brochure.pdf  code  config  decoder.q  docs  html  lib  LICENSE  logs  mkdocs.yml  README.md  sample  setenv.sh  spec  tests  torq.q
	

The processing of files is called in a similar manner to other TorQ processes (note environment variables must be set with setenv.sh below):
```
~/cme/git$ . setenv.sh
~/cme/git$ cmedecoder -files sample/sample_20170101.log
```

`cmedecoder` is an alias defined in setenv.sh for convenience. The expanded version of the same command is shown below:

```
~/cme/git$ q torq.q -load code/process/cmedecoder.q -proctype cmedecoder -procname cmedecoder -files sample/sample_20170101.log
```
The above will process the sample logfile provided and save the data to `hdb`.
To load the hdb simply run from your TorQ directory `q hdb`.

## Data Handling
The FIX message categories within the CME needed to maintain market information are "d" and "X" - security definition and market data incremental refresh, respectively. The security information includes the standard FIX header, and then identifies the instrument and its features, including those used in maintaining the book (MarketDepth:264, used to maintain book depth, and DisplayFactor:9787, used to convert the FIX message prices to real market values). These messages may contain multiple repeated blocks, e.g. for multiple underlying securities in spread instruments, which must be accounted for in processing. An example definition message is shown below.
```
1128=9^A9=511^A35=d^A49=SAMPLE^A75=20161009^A34=1281^A52=20030124045450030397440^A5799=00000000^A980=A^A779=20161009160533273752621^A1180=314^A1300=62^A55=6SH0^A48=24929^A22=8^A200=202003^A1151=6S^A6937=6S^A167=FUT^A461=FFCXSX^A9779=N^A462=4^A207=XCME^A15=USD^A1142=F^A562=1^A1140=9999^A969=1.0^A1146=0.0^A9787=1.0E-4^A1141=1^A1022=GBX^A264=10^A864=2^A865=5^A1145=20150316-21:49:00.000000000^A865=7^A1145=20200316-14:16:00.000000000^A870=1^A871=24^A872=00000000000001000010000000001111^A996=CHF^A1147=125000^A1149=11501.0^A1148=10701.0^A1143=60.0^A1150=11101.0^A731=00000011^A10=240^A60=20030124045450030397440
```

A market data incremental refresh message contains information on quotes and trades executed, including multiple repeated blocks (NoMDEntries: 268) which contain the market actions resulting in an event, e.g. multiple book level updates to account for a trade eliminating multiple orders. The information in the repeated blocks is separated out in this case and the surrounding information (time, security etc) duplicated, while keeping MsgSeqNum:34 and RptSeq:83 which allow tracking of event ordering. Each full message can then be pushed to the appropriate location based on the MDUpdateAction:279 which indicates the event type (0 - bid; 1 - ask; 2 - trade; ... ), and the order book can be maintained based on the changes indicated in this message type. An example market data incremental refresh message is shown below.

```
1128=9^A9=180^A35=X^A49=SAMPLE^A75=20161011^A34=2344^A52=20010525125902582648128^A60=20010525125902582648128^A5799=10000100^A268=1^A279=0^A269=1^A48=173595^A55=6SZ6^A83=354045^A270=10270.0^A271=3^A346=1^A1023=3^A10=086
```
## Case Study

To create the book, define four schemas to store the data parsed from the raw FIX message format:

1. Market Data Security Status (msgType = f)
```
q)meta rawstatus
c                    | t f a
---------------------| -----
MsgSeqNum            | i
TransactTime         | p
TradingDate          | d
MatchEventIndicator  | i
SecurityGroup        | s
SecurityTradingStatus| s
HaltReasonChar       | s
SecurityTradingEvent | s
```

2. Quote (Market Data Incremental Refresh where MDEntryType = 0/1)
```
q)meta rawquote
c                  | t f a
-------------------| -----
date               | d
Symbol             | s   p
TradeDate          | d
MsgSeqNum          | i
TransactTime       | p
MatchEventIndicator| i
MDUpdateAction     | s
MDEntryType        | s
SecurityID         | i
RptSeq             | i
MDEntryPx          | f
MDEntrySize        | f
NumberOfOrders     | i
MDPriceLevel       | i
```

3. Trade (Market Data Incremental Refresh where MDEntryType = 2)
```
q)meta rawtrade
c                  | t f a
-------------------| -----
date               | d
Symbol             | s   p
TradeDate          | d
MsgSeqNum          | i
TransactTime       | p
MatchEventIndicator| i
MDUpdateAction     | s
SecurityID         | i
RptSeq             | i
MDEntryPx          | f
MDEntrySize        | f
NumberOfOrders     | i
AggressorSide      | s
```

4. Security Definition (msgType = d)
```
q)meta rawdefinitions
c                   | t f a
--------------------| -----
TradeDate           | d
LastUpdateTime      | p
MatchEventIndicator | i
SecurityUpdateAction| s
MarketSegmentID     | i
Symbol              | s
SecurityID          | i
MaturityMonthYear   | m
SecurityGroup       | s
SecurityType        | s
UnderlyingProduct   | i
SecurityExchange    | s
Currency            | s
MarketDepth         | i
DisplayFactor       | f
```

Once data has been parsed and placed in the appropriate tables it is possible to generate a book of quotes and trades. Depending on user requirements, there are scripts to build both a wide book and a tall book. 

The wide book format stores a nested list of prices and sizes up to the maximum market depth at each point in time for the data. The user may then query the data over a time range or an exact time to generate a view of the book at that point. 

In contrast, the tall book stores only what has changed on each update for the appropriate side. The table is thus smaller, since only the level which has been changed (and those below in the case of a "NEW" or "DELETE" MDUpdateAction) on a single side must be changed with each message. A sample of the tall book, showing a single entry at level 3, and an appropriate query to return a book for a single sym at a certain time are show below:

```
~/deploy$ q torq.q -load decoder.q -proctype decoder -procname decoder -files sample/sample_20170101.log -debug -tallbook
	...
	...
	...
q)book
date       time                          sym  side  level orders size price msgseq rptseq matchevent
----------------------------------------------------------------------------------------------------
2017.01.01 2017.01.01D01:10:58.905415920 6SZ6 OFFER 3     1      3    10270 2344   354045 132
2017.01.01 2017.01.01D01:10:58.905415920 6SZ6 OFFER 4                       2344   354045 132
2017.01.01 2017.01.01D01:10:58.905415920 6SZ6 OFFER 5                       2344   354045 132
2017.01.01 2017.01.01D01:10:58.905415920 6SZ6 OFFER 6                       2344   354045 132
2017.01.01 2017.01.01D01:10:58.905415920 6SZ6 OFFER 7                       2344   354045 132
2017.01.01 2017.01.01D01:10:58.905415920 6SZ6 OFFER 8                       2344   354045 132
2017.01.01 2017.01.01D01:10:58.905415920 6SZ6 OFFER 9                       2344   354045 132
2017.01.01 2017.01.01D01:10:58.905415920 6SZ6 OFFER 10                      2344   354045 132
..

q)select by side,level from book where date=2017.01.01, time<=07:05:00.0, sym=`6SZ6
side  level| date       time                          sym  orders size price msgseq rptseq matchevent
-----------| ----------------------------------------------------------------------------------------
BID   1    | 2017.01.01 2017.01.01D00:31:33.384676725 6SZ6 1      1    10215 2060   358920 132
BID   2    | 2017.01.01 2017.01.01D00:14:21.855551221 6SZ6 13     23   10214 2611   358963 132
BID   3    | 2017.01.01 2017.01.01D00:31:33.384676725 6SZ6 11     21   10213 2060   358920 132
BID   4    | 2017.01.01 2017.01.01D00:31:33.384676725 6SZ6 11     21   10212 2060   358920 132
BID   5    | 2017.01.01 2017.01.01D00:31:33.384676725 6SZ6 11     21   10211 2060   358920 132
BID   6    | 2017.01.01 2017.01.01D00:31:33.384676725 6SZ6 12     35   10210 2060   358920 132
BID   7    | 2017.01.01 2017.01.01D00:31:33.384676725 6SZ6 8      44   10209 2060   358920 132
BID   8    | 2017.01.01 2017.01.01D00:31:33.384676725 6SZ6 11     36   10208 2060   358920 132
BID   9    | 2017.01.01 2017.01.01D00:31:33.384676725 6SZ6 9      26   10207 2060   358920 132
BID   10   | 2017.01.01 2017.01.01D03:32:25.585326361 6SZ6 5      21   10205 3737   358923 132
..
```

Similarly, a sample of the wide book is shown below

```
~/deploy$ q torq.q -load decoder.q -proctype decoder -procname decoder -files sample/sample_20170101.log -debug
	...
	...
	...
~/deploy$ q hdb
q)10 sublist select from book
date       sym  time                          bprice                                                                bsize                      aprice                                      ..
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------..
2017.01.01 6SH7 2017.01.01D12:47:06.545756971 1.0268 1.0267 1.0266 1.0265 1.0264 1.0263 1.0262 1.0261 1.026  1.0259 3 5 6 4  4  4  4  3  36 11 1.0272 1.0273 1.0274 1.0275 1.0276 1.0277 1...
2017.01.01 6SH7 2017.01.01D04:07:46.761071942 1.0267 1.0266 1.0265 1.0264 1.0263 1.0262 1.0261 1.026  1.0259 1.0258 5 6 4 37 4  3  11 36 11 53 1.0272 1.0273 1.0274 1.0275 1.0276 1.0277 1...
2017.01.01 6SH7 2017.01.01D01:18:39.077345929 1.0268 1.0267 1.0266 1.0265 1.0264 1.0263 1.0262 1.0261 1.026  1.0259 6 6 4 4  37 3  3  11 36 11 1.0274 1.0275 1.0276 1.0277 1.0278 1.0279 1...
2017.01.01 6SH7 2017.01.01D00:07:02.427603074 1.0268 1.0267 1.0266 1.0265 1.0264 1.0263 1.0262 1.0261 1.026  1.0259 5 5 3 3  3  11 3  11 3  3  1.0272 1.0274 1.0275 1.0276 1.0277 1.0278 1...
2017.01.01 6SH7 2017.01.01D04:24:36.588750868 1.0268 1.0267 1.0266 1.0265 1.0264 1.0263 1.0262 1.0261 1.026  1.0259 5 6 4 4  37 4  3  11 36 11 1.0272 1.0273 1.0274 1.0275 1.0276 1.0277 1...
2017.01.01 6SH7 2017.01.01D09:32:24.001122966 1.0268 1.0267 1.0266 1.0265 1.0264 1.0263 1.0262 1.0261 1.026  1.0259 3 5 6 4  4  4  4  3  36 11 1.0272 1.0273 1.0274 1.0275 1.0276 1.0277 1...
2017.01.01 6SH7 2017.01.01D10:32:35.416123137 1.0269 1.0268 1.0267 1.0266 1.0265 1.0264 1.0263 1.0262 1.0261 1.026  3 3 5 5  3  3  11 3  11 3  1.0274 1.0275 1.0276 1.0277 1.0278 1.0279 1...
2017.01.01 6SH7 2017.01.01D11:05:35.588591217 1.0266 1.0265 1.0264 1.0263 1.0262 1.0261 1.026  1.0259 1.0258 1.0257 5 5 3 3  3  11 3  11 3  3  1.0272 1.0273 1.0274 1.0275 1.0276 1.0277 1...
2017.01.01 6SH7 2017.01.01D05:57:25.396454768 1.0268 1.0267 1.0266 1.0265 1.0264 1.0263 1.0262 1.0261 1.026  1.0259 5 6 4 4  37 12 3  11 36 3  1.0274 1.0275 1.0276 1.0277 1.0278 1.0279 1...
```


https://github.com/AquaQAnalytics/TorQ
