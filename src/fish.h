REQUIRED_OSVER	equ	$200			*  2.00以降

EXTMALLOC	equ	1			*  0 = DOS MALLOC,  1 = Ext版 MALLOC

STACKSIZE	equ	4096			*  スタックの大きさ
MINENVSIZE	equ	256			*  最小環境サイズ

DSTACKSIZE	equ	512			*  ディレクトリ・スタックの大きさ
ALIASSIZE	equ	2048			*  別名空間の大きさ
SHELLVARSIZE	equ	2048			*  シェル変数空間の大きさ
KMACROSIZE	equ	1024			*  キー・マクロ空間の大きさ

MAXWORDLISTSIZE	equ	4096			*  MAXWORDLEN+1以上 (32767-14)/2=16376以下  UNIXは10240
MAXLINELEN	equ	MAXWORDLISTSIZE		*  こうすると行と引数並びとの一時領域を共用できるわけ
MAXWORDS	equ	MAXWORDLISTSIZE/2	*  32766以下  cshは 10240/6
MAXWORDLEN	equ	1024			*  12以上 MAXPATH以上 32766以下 MAXWORDLISTSIZE-1以下  cshは1024
MAXSEARCHLEN	equ	31			*  履歴検索文字列の有効先頭文字数（または最大文字数）
MAXSUBSTLEN	equ	63			*  履歴置換文字列の最大文字数
MAXALIASLOOP	equ	20			*  別名ループの最大回数  0以上65535以下  cshは20
MAXIFLEVEL	equ	65535			*  if のネストの最深レベル  0以上65535以下  cshは無制限？
MAXLOOPLEVEL	equ	31			*  while/foreach のネストの最大回数  0以上65535以下  cshは無制限？
MAXSWITCHLEVEL	equ	65535			*  switch のネストの最深  0以上65535以下  cshは無制限？
MAXLABELLEN	equ	31			*  goto/onintrラベルの有効先頭文字数
MAXFUNCNAMELEN	equ	31			*  関数名の最大長

RND_POOLSIZE	equ	61			*  乱数プールサイズ
