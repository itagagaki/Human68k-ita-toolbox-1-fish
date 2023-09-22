MAXWORDLEN	equ	512		*  12以上 MAXPATH以上 32767以下  cshは1024
MAXWORDLISTSIZE	equ	4096		*  MAXWORDLEN以上 (32767-6)/2=16380以下  UNIXは10240
MAXLINELEN	equ	MAXWORDLISTSIZE	*  こうすると行と引数並びとの一時領域を共用できるわけ
MAXWORDS	equ	1024		*  32766以下
MAXSEARCHLEN	equ	31		*  履歴検索文字列の最大長
MAXSUBSTLEN	equ	63		*  履歴置換文字列の最大長
MAXALIASLOOP	equ	20		*  別名ループの最深  0以上65535以下  cshは20
