MODIFYSTATBIT_ERROR	equ	0	*  エラーがあり、メッセージを表示した
MODIFYSTATBIT_OVFLO	equ	1	*  単語リストが長くなり過ぎた（メッセージは表示しない）
MODIFYSTATBIT_FAILED	equ	2	*  failした :s があった（メッセージは表示しない）
MODIFYSTATBIT_X		equ	3	*  :x があった
MODIFYSTATBIT_Q		equ	4	*  :q があった
MODIFYSTATBIT_P		equ	5	*  :p があった
MODIFYSTATBIT_MALLOC	equ	6	*  malloc した
MODIFYSTATBIT_NOMEM	equ	7	*  メモリが足りない（メッセージを表示する）
MODIFYSTATBIT_HISTORY	equ	8	*  !置換の修飾である
MODIFYSTATBIT_QUICK	equ	9	*  ^str1^str2^flag^ である
