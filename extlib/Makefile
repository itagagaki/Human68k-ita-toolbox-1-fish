OBJECTS = alloc.o realloc.o large.o free.o enlarge.o shrink.o previous.o dump.o \
		Calloc.o Crealloc.o Cfree.o Cmdump.o

all : Extmalloc.a

clean :
	-rm -f $(OBJECTS) Extmalloc.a

$(OBJECTS) : %.o : %.s defines.inc
	has $*

Extmalloc.a : $(OBJECTS)
	har $@ $?
