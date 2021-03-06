TESTS = $(wildcard ./*.c)
GCC_COMPILED_TESTS = ${TESTS:.c=.gcc}
KCC_COMPILED_TESTS = ${TESTS:.c=.kcc}
TEST_RESULTS = ${TESTS:.c=.out}
REFERENCE_TEST_RESULTS = ${TESTS:.c=.ref}
TEST_COMPARISON = ${TESTS:.c=.cmp}

GCC = gcc-4.8 -lm -Wall -Wextra -x c -O0 -m32 -U __GNUC__ -pedantic -std=c11
CHECK_RESULT_COMPILE = if [ $$? -eq 0 ] ; then echo "passed $<"; mv $@.tmp.out $@.out; else echo "failed $<"; cat $@.tmp.out; exit 1; fi
CHECK_RESULT_RUN = if [ $$? -eq 0 ] ; then echo "passed $<"; mv $@.tmp $@; else echo "failed $<"; cat $@.tmp; exit 1; fi

.PHONY: test clean reference
.PRECIOUS: %.kcc %.out

test: ${TEST_RESULTS}

reference: ${REFERENCE_TEST_RESULTS}

compare: ${TEST_COMPARISON}

%.out: %.kcc
	@echo -n "Running $<... "
	@./$< > $@.tmp 2>&1; ${CHECK_RESULT_RUN}

%.kcc: %.c
	@echo -n "Compiling $<... "
	@kcc -o $@ $< > $@.tmp.out 2>&1; ${CHECK_RESULT_COMPILE}

%.gcc: %.c
	@echo -n "Compiling $< (reference)... "
	@${GCC} -o $@ $< > $@.tmp.out 2>&1; ${CHECK_RESULT_COMPILE}

%.ref: %.gcc
	@echo -n "Running $<... "
	@./$< > $@.tmp 2>&1; ${CHECK_RESULT_RUN}

%.cmp: %.out %.ref
	@echo -n "Comparing $^... "
	@diff $^ > $@.tmp 2>&1; ${CHECK_RESULT_RUN}

clean:
	rm -rf *.out *.kcc *.tmp *.gcc *.ref *.cmp
