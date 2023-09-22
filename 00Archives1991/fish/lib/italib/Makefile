#  Makefile for italib.l

AS	= \usr\pds\HAS.X -i $(INCLUDE) # -d
LIB	= \bin\LIB.X

OBJS = memmoved.o memmovei.o reverse.o rotate.o
INCLUDE = .

%.o : %.s
	$(AS) $<

ita.l : $(OBJS)
	$(LIB) $@ $?

###
.PHONY : clean
clean :
	-rm -f *.l *.o
