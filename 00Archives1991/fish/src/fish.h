STACKSIZE	equ	4096-240	*  スタックの大きさ

DSTACKSIZE	equ	1024		*  ディレクトリ・スタックのデフォルトの大きさ
SHELLVARSIZE	equ	1024		*  シェル変数空間のデフォルトの大きさ
ALIASSIZE	equ	512		*  別名空間のデフォルトの大きさ

MAXWORDLEN	equ	512		*  12以上 MAXPATH以上 32767以下  cshは1024
MAXWORDLISTSIZE	equ	4096		*  MAXWORDLEN以上 (32767-6)/2=16380以下  UNIXは10240
MAXLINELEN	equ	MAXWORDLISTSIZE	*  こうすると行と引数並びとの一時領域を共用できるわけ
MAXWORDS	equ	1024		*  32766以下
MAXSEARCHLEN	equ	31		*  履歴検索文字列の最大長
MAXSUBSTLEN	equ	63		*  履歴置換文字列の最大長
MAXALIASLOOP	equ	20		*  別名ループの最深  0以上65535以下  cshは20

MAXFILES = 1400				* maximum file directory entry
DIRWORK = (MAXFILES+1)*32		* maximum file directory work size
FNAMELEN = 18				* maximum file name length
EXTLEN = 3				* maximum file extension length
NAMEBUF = 24				* file name work size
DOSVER2 = $100*1+74			* os version 2.00 number
DOSVER3 = $100*2+50			* os version 3.00 number
