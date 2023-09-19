*  DOS _FILES ($FF4E), DOS _NFILES ($FF4F) での受け渡しバッファの構造

ST__MODE	equ	0	*  ds.b 1		*
ST__DRIVENO	equ	1	*  ds.w 1		*
ST__DIRCLS	equ	2	*  ds.w 1		*
ST__DIRFAT	equ	4	*  ds.w 1		* Human68k内部で使用
ST__DIRSEC	equ	6	*  ds.w 1		* 壊すとnfiles($FF4F)できなくなる
ST__DIRPOS	equ	8	*  ds.w 1		*
ST__FILENAME	equ	10	*  ds.b 8		*
ST__EXT		equ	18	*  ds.b 3		*
ST_MODE		equ	21	*  ds.b 1	*  File Mode
ST_TIME		equ	22	*  ds.w 1	*  File Time
ST_DATE		equ	24	*  ds.w 1	*  File Date
ST_SIZE		equ	26	*  ds.l 1	*  File Size
ST_NAME		equ	30	*  ds.b 23	*  Packed Filename

STATBUFSIZE	equ	54	*  53 Byte + Pad Byte

*  ST_MODE のビット

MODEBIT_RDO	equ	0			*  READ ONLY
MODEBIT_HID	equ	1			*  HIDDEN
MODEBIT_SYS	equ	2			*  SYSTEM
MODEBIT_VOL	equ	3			*  VOLUME LABEL
MODEBIT_DIR	equ	4			*  DIRECTORY
MODEBIT_ARC	equ	5			*  ARCHIVE
MODEBIT_LNK	equ	6			*  SYMBOLIC LINK (NOT STANDARD)
MODEBIT_EXE	equ	7			*  EXECUTABLE (NOT STANDARD)

MODEVAL_RDO	equ	$01			*  READ ONLY
MODEVAL_HID	equ	$02			*  HIDDEN
MODEVAL_SYS	equ	$04			*  SYSTEM
MODEVAL_VOL	equ	$08			*  VOLUME LABEL
MODEVAL_DIR	equ	$10			*  DIRECTORY
MODEVAL_ARC	equ	$20			*  ARCHIVE
MODEVAL_LNK	equ	$40			*  SYMBOLIC LINK (NOT STANDARD)
MODEVAL_EXE	equ	$80			*  EXECUTABLE (NOT STANDARD)
MODEVAL_ALL	equ	$FF			*  ALL

*  DOS _DSKFRE での受け渡しバッファの構造

DF_AVAILCLUST	equ	0	*  ds.w 1	*  Number of available clusters
DF_TOTALCLUST	equ	2	*  ds.w 1	*  Number of total clusters
DF_SECT_CLUST	equ	4	*  ds.w 1	*  Number of secters per cluster
DF_BYTE_SECT	equ	6	*  ds.w 1	*  Number of bytes per sector

DFBUFSIZE	equ	8
