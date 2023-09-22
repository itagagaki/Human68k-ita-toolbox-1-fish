* irandom.s  -  整数の一様乱数

*
*  Itagaki Fumihiko   Mar 26 1989
*

*
*    本パッケージは，疑似乱数(pseudorandom numbers)を発生するものである．
*  乱数にはいろいろな種類があるが，なかでも一番基本的なものは一様分布の乱数，
*  すなわち一様乱数である．これは，与えられた範囲のうち，どの値をとる確率も等
*  しい．
*
*    本パッケージの関数 _irandom は，呼び出す度に 0以上 32768未満の整数の一様
*  乱数を返す．
*    最初に一回だけ初期化の手続き init_irandom(seed) を実行しておく．ここで
*  seed は乱数の「種」で 0以上 32768未満の整数とする．このseedの値によって乱
*  数の系列が異なることになる．
*
*  関数 _irandom のアルゴリズムは
*　　　　X[n] = (X[n-55] - X[n-24]) mod m
*  という「引き算法」(subtractive method)であるが，実際には m に 2の累乗であ
*  る 32768 を選び，
*　　　　X[n] = X[n-55]　XOR　X[n-24]
*  としている．つまり，55回前に発生した乱数と 24回前に発生した乱数との排他的
*  論理和を求める．
*    最下位ビット (X[n] mod 2) の周期は正確に (2 pow 55) - 1 であり，これが
*  X[n] の周期の下限になる．
*
*    関数 _irandom は確かに一様乱数を発生し，一つ一つの乱数の分布は悪くはない．
*  しかしながら，発生する乱数に明らかな規則性が認められるかも知れない．そこで
*  これを改良したのが関数 irandom である．関数 irandom は，関数 _irandom を利
*  用しながら規則性をある程度解消した乱数を返す．もし発生する乱数に規則性があ
*  っても構わないならば関数 _irandom を使用しても良いわけだが，関数irandomのオ
*  ーバーヘッドはごく僅かなので，どのような場合にも関数 irandom を使用するのが
*  良いだろう．
*
*    プログラム中で乱数の上限を変えたい場合には，0以上 1未満の実数の一様乱数を
*  発生する関数 random を利用して
*　　　　trunc(random() * m)
*  のようにするか，このパッケージの関数 irandom を利用して
*　　　　(irandom() * m) >> 15
*  のようにする．前者の方が上限を大きく設定することができるが，実数演算が速く
*  ない計算機では後者の方が速度の点でずっと有利である．
*

.include random.h

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
		lea	random_table,a0
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
		move.b	random_index,d0
		addq.b	#1*2,d0
		cmp.b	#55*2,d0
		blo	_irandom_1

		bsr	randomize
		moveq	#0,d0
_irandom_1:
		move.b	d0,random_index
		lea	random_table,a0
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
		move.b	random_position,d2
		lea	random_pool,a0
		move.w	(a0,d2.w),d2
		mulu	#POOLSIZE*2,d2
		clr.w	d2
		swap	d2
		lsl.w	#1,d2
		move.b	d2,random_position
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
*      D0.W   乱数の種 (0..32767)
*
* RETURN
*      none
****************************************************************
.xdef init_irandom

init_irandom:
		movem.l	d0-d4/a0,-(a7)
		lea	random_table,a0
		move.w	d0,54*2(a0)
		moveq	#1,d1
		moveq	#1,d2
init_random_loop1:
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
		blo	init_random_loop1

		bsr	randomize
		bsr	randomize
		bsr	randomize
		move.b	#54*2,random_index

		lea	random_pool,a0
		moveq	#POOLSIZE-1,d1
init_random_loop2:
		bsr	_irandom
		move.w	d0,(a0)+
		dbra	d1,init_random_loop2

		move.b	#(POOLSIZE-1)*2,random_position
		movem.l	(a7)+,d0-d4/a0
		rts

.end
