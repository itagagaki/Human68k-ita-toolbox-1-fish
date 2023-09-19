static int offset = 0;
static char *buf[100];

main()
{
  int offset, bytes, ret;
  char ch;

  while (1)
    {
      printf("a(lloc),r(ealloc),f(ree),d(ump) ");
      do
	scanf("%c", &ch);
      while (ch == '\n');
      switch (ch)
	{
	case 'a':
	case 'A':
	  for (offset = 0; offset < 100; offset++)
	    if (buf[offset] == 0)
	      break;
	  if (offset == 100)
	    {
	      printf("これ以上確保は出来ません。\n");
	      continue;
	    }
	  printf("何バイト確保しますか？ ");
	  scanf("%d", &bytes);
	  ret = malloc(bytes);
	  printf("リターンコード %8X\n", ret);
	  if (ret > 0)
	    buf[offset] = ret;
	  break;

	case 'r':
	case 'R':
	  printf("何番をリサイズしますか？ ");
	  scanf("%d", &offset);
	  printf("何バイト確保しますか？ ");
	  scanf("%d", &bytes);
	  if (0 <= offset && offset < 100 && buf[offset])
	    {
	      ret = realloc(buf[offset], bytes);
	      printf("リターンコード %8X\n", ret);
	      if (ret > 0)
		buf[offset] = ret;
	    }
	  break;

	case 'f':
	case 'F':
	  printf("何番を開放しますか？ ");
	  scanf("%d", &offset);
	  if (0 <= offset && offset < 100 && buf[offset])
	    printf("リターンコード %8X\n", free(buf[offset]));
	  buf[offset] = 0;
	  break;

	case 'd':
	case 'D':
	  for (offset = 0; offset < 100; offset++)
	    if (buf[offset])
	      printf("%2d %8X\n", offset, buf[offset]);
	  debug_mdump();
	  break;
	}
    }
}
