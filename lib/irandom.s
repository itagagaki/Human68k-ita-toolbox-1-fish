* irandom.s  -  整数の一様乱数

*
*  Itagaki Fumihiko   26 Mar 1989
*

*
*  Description
*
*          本パッケージは，疑似乱数(pseudo random numbers)を発生するもので
*  ある．乱数にはいろいろな種類があるが，なかでも一番基本的なものは一様分
*  布の乱数，すなわち一様乱数である．これは，与えられた範囲のうち，どの値
*  をとる確率も等しい．
*
*          本パッケージの関数 _irandom は，呼び出す度に 0以上 32768未満の
*  整数の一様乱数を返す．
*
*      関数 _irandom のアルゴリズムは
*
*                   X[n] = (X[n-55] - X[n-24]) mod m
*
*  という「引き算法」(subtractive method)であるが，実際には m に 2の累乗で
*  ある 32768 を選び，
*
*     　              X[n] = X[n-55] XOR X[n-24]
*
*  としている．つまり，55回前に発生した乱数と 24回前に発生した乱数との排他
*  的論理和を求める．最下位ビット (X[n] mod 2) の周期は正確に
*  (2 pow 55) - 1 であり，これが X[n] の周期の下限になる．
*
*          関数 _irandom は確かに一様乱数を発生し，一つ一つの乱数の分布は
*  悪くはない．しかしながら，発生する乱数に明らかな規則性が認められるかも
*  知れない．そこでこれを改良したのが関数 irandom である．関数 irandom は，
*  関数 _irandom を利用しながら規則性をある程度解消した乱数を返す．もし発
*  生する乱数に規則性があっても構わないならば関数 _irandom を使用しても良
*  いわけだが，関数 irandom のオーバーヘッドはごく僅かなので，どのような場
*  合にも関数 irandom を使用するのが良いだろう．
*
*          プログラム中で乱数の上限を変えたい場合には，0以上 1未満の実数の
*  一様乱数を発生する関数 random を利用して
*
*　 　                    (int)trunc(random() * m)
*
*  のようにするか，このパッケージの関数 irandom を利用して
*
*                          (irandom() * m) >> 15
*
*  のようにする．前者の方が上限を大きく設定することができるが，実数演算が
*  速くない計算機では後者の方が速度の点でずっと有利である．
*
*          関数 irandom および _irandom を使用するには，最初に一回だけ初期
*  化の手続き init_irandom(seed,poolsize) を実行しておく．ここで seed は乱
*  数の「種」で 0以上 32768未満の整数とする．この seed の値によって乱数の
*  系列が異なることになる．poolsize は関数 irandom が使用する配列
*  irandom_pool の容量(要素数)を示す．
*
*          本パッケージを利用するには，本パッケージの他に
*
*                  .BSS
*                  irandom_index:       ds.b    1
*                  irandom_position:    ds.b    1
*                  irandom_poolsize:    ds.b    1
*                  irandom_table:       ds.w    55
*                  irandom_pool:        ds.w    (irandom_poolsize)
*
*  が必要である．
*

.xref irandom_index
.xref irandom_position
.xref irandom_poolsize
.xref irandom_table
.xref irandom_pool

.text

****************************************************************
* randomize
*
* CALL
*      none
*
* RETURN
*      none
****************************************************************
randomize:
		movem.l	d0-d1/a0,-(a7)
		lea	irandom_table,a0
		moveq	#23,d1
randomize_loop1:
		move.w	31*2(a0),d0
		eor.w	d0,(a0)+
		dbra	d1,randomize_loop1

		moveq	#30,d1
randomize_loop2:
		move.w	-24*2(a0),d0
		eor.w	d0,(a0)+
		dbra	d1,randomize_loop2

		movem.l	(a7)+,d0-d1/a0
		rts
****************************************************************
* _irandom - 簡単な疑似一様乱数整数
*
* CALL
*      none
*
* RETURN
*      D0.L   簡単な疑似一様乱数整数 (0..32767)
****************************************************************
.xdef _irandom

_irandom:
		move.l	a0,-(a7)
		moveq	#0,d0
		move.b	irandom_index,d0
		addq.b	#1*2,d0
		cmp.b	#55*2,d0
		blo	_irandom_1

		bsr	randomize
		moveq	#0,d0
_irandom_1:
		move.b	d0,irandom_index
		lea	irandom_table,a0
		move.w	(a0,d0.l),d0
		movea.l	(a7)+,a0
		rts
****************************************************************
* irandom - 改良版疑似一様乱数整数
*
* CALL
*      none
*
* RETURN
*      D0.L   改良版疑似一様乱数整数 (0..32767)
****************************************************************
.xdef irandom

irandom:
		movem.l	d1-d2/a0,-(a7)
		moveq	#0,d2
		move.b	irandom_position,d2
		lea	irandom_pool,a0
		move.w	(a0,d2.w),d2
		moveq	#0,d1
		move.b	irandom_poolsize,d1
		mulu	d1,d2
		clr.w	d2
		swap	d2
		lsl.w	#1,d2
		move.b	d2,irandom_position
		move.w	(a0,d2.w),d1
		bsr	_irandom
		move.w	d0,(a0,d2.w)
		moveq	#0,d0
		move.w	d1,d0
		movem.l	(a7)+,d1-d2/a0
		rts
****************************************************************
* init_irandom - 改良版疑似一様乱数整数を初期化する
*
* CALL
*      D0.W   (signed) seed (乱数の種) (0..32767)
*      D1.B   (signed) poolsize (1..63)
*
* RETURN
*      none
*
* NOTE
*      D0.W の MSB は CLR する．
*
*      D1.B が 1 から 63 の範囲に無い場合には 1 から 63 の範囲に
*      クリッピングする．
****************************************************************
.xdef init_irandom

init_irandom:
		movem.l	d0-d4/a0,-(a7)
*
		moveq	#1,d2
		cmp.b	d2,d1
		blt	init_irandom_1

		moveq	#63,d2
		cmp.b	d2,d1
		ble	init_irandom_2
init_irandom_1:
		move.b	d2,d1
init_irandom_2:
		move.b	d1,irandom_poolsize
*
		bclr	#15,d0
		lea	irandom_table,a0
		move.w	d0,54*2(a0)
		moveq	#1,d1
		moveq	#1,d2
init_irandom_loop1:
		moveq	#21,d3
		mulu	d2,d3
		divu	#55,d3
		swap	d3
		lsl.w	#1,d3
		move.w	d1,(a0,d3.w)
		move.w	d1,d4
		sub.w	d0,d1
		neg.w	d1
		bclr	#15,d1
		move.w	d4,d0
		addq.w	#1,d2
		cmp.w	#55,d2
		blo	init_irandom_loop1
*
		bsr	randomize
		bsr	randomize
		bsr	randomize
		move.b	#54*2,irandom_index
*
		lea	irandom_pool,a0
		moveq	#0,d1
		move.b	irandom_poolsize,d1
		subq.w	#1,d1
init_irandom_loop2:
		bsr	_irandom
		move.w	d0,(a0)+
		dbra	d1,init_irandom_loop2
*
		move.b	irandom_poolsize,d0
		subq.b	#1,d0
		lsl.b	#1,d0
		move.b	d0,irandom_position
*
		movem.l	(a7)+,d0-d4/a0
		rts

.end
