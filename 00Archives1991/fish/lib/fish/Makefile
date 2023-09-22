#  Makefile for fish.l

AS	= \usr\pds\HAS.X -i $(INCLUDE) # -d
LIB	= \bin\LIB.X

OBJS  = decargs.o encargs.o
INCLUDE = .

%.o : %.s
	$(AS) $<

fish.l : $(OBJS)
	$(LIB) $@ $?

###
.PHONY : clean
clean :
	-rm -f *.l *.o
