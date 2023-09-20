*  FCBの構造（Human68k v2.01以降）

.offset 0
FCB_USECOUNT:	ds.b	1	* handle use count (0:no use)
FCB_FLAG:	ds.b	1
FCB_DEVADDR:	ds.l	1	* devadr (device driver or DPB)
FCB_SEEKPOS:	ds.l	1	* seek data pos 現在のシーク位置
FCB_SHAREPOS:	ds.l	1	* share_pos シェア管理領域のアドレス
FCB_OPENMODE:	ds.b	1	* open_mode
FCB_DIRNO:	ds.b	1	* ディレクトリセクター内何番目
FCB_SECFAT:	ds.b	1	* データFAT内セクターオフセット
FCB_FATSEC:	ds.b	1	* FAT先頭からのセクターオフセット
FCB_FATPOS:	ds.w	1	* data のFAT番号
FCB_DATASEC:	ds.l	1	* 現在のデータのセクター位置
FCB_DATAADDR:	ds.l	1	* 現在のデータのiobufアドレス
FCB_DIRSEC:	ds.l	1	* ディレクトリのセクター位置
FCB_NEXTPOS:	ds.l	1	* next data pos
FCB_NAME1:	ds.b	8	* name1
FCB_EXT:	ds.b	3	* ext
FCB_ATTR:	ds.b	1	* atr
FCB_NAME2:	ds.b	10	* name2
FCB_TIME:	ds.w	1	* time
FCB_DATE:	ds.w	1	* date
FCB_FAT:	ds.w	1	* start fat
FCB_SIZE:	ds.l	1	* filelen
FCB_FAT_BUFF:	ds.w	14	* ディスク内FAT番号1, ファイル内FAT番号1
				* ディスク内FAT番号2, ファイル内FAT番号2
				*    . . .
				* ディスク内FAT番号7, ファイル内FAT番号7
FCBBUFSIZE:

*  FCB_FLAG のビット

FCB_FLAGBIT_IO			equ	7

FCB_FLAGBIT_FILE_DIRTY		equ	6
FCB_FLAGBIT_FILE_SPECIAL	equ	5

FCB_FLAGBIT_IO_EOF		equ	6
FCB_FLAGBIT_IO_RAW		equ	5
FCB_FLAGBIT_IO_CLOCK		equ	3
FCB_FLAGBIT_IO_NULL		equ	2
FCB_FLAGBIT_IO_CONOUT		equ	1
FCB_FLAGBIT_IO_CONINP		equ	0

FCB_FLAG_DRIVEMASK		equ	$0f

