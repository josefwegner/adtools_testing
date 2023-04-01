SHELL:=/bin/bash
CWD:=$(shell echo $${PWD##*/})
FILE_INFIX:=test_$(CWD)_$(INFIX)

PROG:=main_$(FILE_INFIX).exe
LOG_FILE:=log_$(FILE_INFIX).txt
LHA_FILE:=lha_$(FILE_INFIX).lha

LOG_INF =                                          \
	echo "\#\#\#\#\#" >> $(LOG_FILE);          \
	echo "$(1) phase for $(2)" >> $(LOG_FILE); \
	echo "\#\#\#\#\#" >> $(LOG_FILE)

LOG_RUN = $(1) 2>&1 | tee -a $(LOG_FILE)

LOG_EXT = echo "NOTE: "$(1) >> $(LOG_FILE)

.PHONY: clean all
all: $(PROG) $(LHA_FILE)
clean:
	@-rm -f *.o *.exe log*.txt *.a *.so *.lha

# Unfortunately, the compiler libraries for newlib are not in a folder
# named newlib. For example, libgcc.so is inside:
# "lib/gcc/ppc-amigaos/11.3.0/libgcc.so", unlike clib which is in
# clib2.  GREP_CMD is a hack to get around this. First, assume that
# for any library we are looking for, we will find it in a location
# that contains the string of the particular C library being
# used. Then, in the case that we are newlib, so long as we remove
# anything that contains "clib2", we assume that is the newlib
# library. This works for the case that newlib is in the string and is
# not.
GREP_CMD:=$(C_LIB)
ifeq ($(C_LIB),newlib))
	GREP_CMD:=-v clib2
endif
$(LHA_FILE):
	echo $${CROSS_PREFIX}
ifeq ($(NO_DYN),)
	ARR_SO=($$(readelf -d $(PROG) | grep NEEDED | sed 's,.*\[\(.*\)\],\1,')) ; \
	for SO in $${ARR_SO[@]} ;                                                  \
	do                                                                         \
		LOC=$$(find $${CROSS_PREFIX} -name "$${SO}" | grep $(GREP_CMD)) ;  \
		if [[ -z "$${LOC}" ]] ;                                            \
		then                                                               \
			LOC=$$(find . -name "$${SO}") ;                            \
		fi ;                                                               \
		test -f "$${LOC}" && cp "$${LOC}" . ; lha a $@ "$$(basename "$${LOC}")" ; \
	done
endif
	lha a $@ $(PROG)
