		.offset	0
*
pool_head:			* 各 pool の先頭
next_pool_offset:		* 次の pool へのオフセット
		ds.w	1	* 必ず 2 の倍数である
				* 0 なら終わりを表わす dummy pool
				* 2 は broken pool、現在は一切生成しない
pool_buffer_head:		* 4 以上は used pool か free pool
				*   その区別は別のチェインで free だけを繋ぐ
				*   そのリストになければ used で pool_buffer_head
				*   から next_pool_offset - 2 bytes 使用中
next_free_offset:		* free は next_free_offset でチェインする
		ds.w	1	* 必ず 2 の倍数である
				* 0 なら次の free pool が無い事を示す
free_pool_buffer_head:
*
		.offset	0
*
lake_head:			* 各 lake の先頭
lake_size:			* lake のサイズ
		ds.l	1	*
next_lake_ptr:			* 次の pool へのポインタ
		ds.l	1	* 0 なら次の pool は無し
head_pool:			* next_free_offset を格納する為の free pool
		ds.b	free_pool_buffer_head
				* next_pool_offset には調度 free_pool_buffer_head が
				* next_free_offset には free pool へ
				* のオフセットが入る
lake_buffer_head:		* ここから実際の pool のチェインが入り
				* 一番最後には dummy pool が入る
