SEMANTICS_DIR = semantics
SCRIPTS_DIR = scripts
PARSER_DIR = parser
LIBC_DIR = libc
TESTS_DIR = tests
PARSER = $(PARSER_DIR)/cparser
DIST_DIR = dist
KCCFLAGS = 
TORTURE_TEST_DIR = tests/gcc-torture

FILES_TO_DIST = \
	$(SCRIPTS_DIR)/query-kcc-prof \
	$(SCRIPTS_DIR)/analyzeProfile.pl \
	$(SCRIPTS_DIR)/kcc \
	$(SCRIPTS_DIR)/xml-to-k \
	$(SCRIPTS_DIR)/program-runner \
	$(PARSER_DIR)/cparser \

.PHONY: default check-vars semantics clean fast semantics-fast $(DIST_DIR) $(SEMANTICS_DIR)/settings.k test-build

default: dist

fast: $(DIST_DIR)/lib/libc.so $(DIST_DIR)/c11-kompiled/c11-kompiled/context.bin

check-vars:
	@if ! ocaml -version > /dev/null 2>&1; then echo "ERROR: You don't seem to have ocaml installed.  You need to install this before continuing.  Please see INSTALL.md for more information."; false; fi
	@if ! gcc-4.8 -v > /dev/null 2>&1; then echo "ERROR: You don't seem to have gcc 4.8 installed.  You need to install this before continuing.  Please see INSTALL.md for more information."; false; fi
	@if ! kompile --version > /dev/null 2>&1; then echo "ERROR: You don't seem to have kompile installed.  You need to install this before continuing.  Please see INSTALL.md for more information."; false; fi
	@if ! krun --version > /dev/null 2>&1; then echo "ERROR: You don't seem to have krun installed.  You need to install this before continuing.  Please see INSTALL.md for more information."; false; fi
	@perl $(SCRIPTS_DIR)/checkForModules.pl

$(DIST_DIR)/c11-kompiled/c11-kompiled/context.bin $(DIST_DIR)/c11-translation-kompiled/c11-translation-kompiled/context.bin: $(FILES_TO_DIST) semantics-fast | check-vars
	@mkdir -p $(DIST_DIR)
	@mkdir -p $(DIST_DIR)/lib
	@cp -r $(LIBC_DIR)/includes $(DIST_DIR)
	@cp $(FILES_TO_DIST) $(DIST_DIR)
	@cp --preserve=timestamps -r $(SEMANTICS_DIR)/c11-translation-kompiled $(DIST_DIR)
	@cp --preserve=timestamps -r $(SEMANTICS_DIR)/c11-kompiled $(DIST_DIR)

$(DIST_DIR)/c11-nd-kompiled/c11-nd-kompiled/context.bin $(DIST_DIR)/c11-nd-thread-kompiled/c11-nd-thread-kompiled/context.bin: semantics
	@cp -r $(SEMANTICS_DIR)/c11-nd-kompiled $(DIST_DIR)
	@cp -r $(SEMANTICS_DIR)/c11-nd-thread-kompiled $(DIST_DIR)

$(DIST_DIR)/lib/libc.so: $(DIST_DIR)/c11-translation-kompiled/c11-translation-kompiled/context.bin $(wildcard $(LIBC_DIR)/src/*) $(SCRIPTS_DIR)/kcc
	@echo "Translating the standard library... ($(LIBC_DIR))"
	$(DIST_DIR)/kcc -s -shared -o $(DIST_DIR)/lib/libc.so $(wildcard $(LIBC_DIR)/src/*.c) $(KCCFLAGS) -I $(LIBC_DIR)/src/
	@echo "Done."

$(DIST_DIR): test-build $(DIST_DIR)/c11-nd-kompiled/c11-nd-kompiled/context.bin $(DIST_DIR)/c11-nd-thread-kompiled/c11-nd-thread-kompiled/context.bin

test-build: fast
	@echo "Testing kcc..."
	echo '#include <stdio.h>\nint main(void) {printf("x"); return 42;}\n' | $(DIST_DIR)/kcc - -o $(DIST_DIR)/testProgram.compiled
	$(DIST_DIR)/testProgram.compiled 2> /dev/null > $(DIST_DIR)/testProgram.out; test $$? -eq 42
	grep x $(DIST_DIR)/testProgram.out > /dev/null
	@echo "Done."
	@echo "Cleaning up..."
	@rm -f $(DIST_DIR)/testProgram.compiled
	@rm -f $(DIST_DIR)/testProgram.out
	@echo "Done."

parser/cparser:
	@echo "Building the C parser..."
	@$(MAKE) -C $(PARSER_DIR)

semantics-fast: check-vars $(SEMANTICS_DIR)/settings.k
	@$(MAKE) -C $(SEMANTICS_DIR) fast

$(SEMANTICS_DIR)/settings.k:
	@diff $(LIBC_DIR)/semantics/settings.k $(SEMANTICS_DIR)/settings.k > /dev/null || cp $(LIBC_DIR)/semantics/settings.k $(SEMANTICS_DIR)

semantics: check-vars $(SEMANTICS_DIR)/settings.k
	@$(MAKE) -C $(SEMANTICS_DIR) all

test: gcc-torture

gcc-torture: dist
	@$(MAKE) -C $(TORTURE_TEST_DIR) test

clean:
	-$(MAKE) -C $(PARSER_DIR) clean
	-$(MAKE) -C $(SEMANTICS_DIR) clean
	-$(MAKE) -C $(TESTS_DIR) clean
	@-rm -rf $(DIST_DIR)
	@-rm -f ./*.tmp ./*.log ./*.cil ./*-gen.maude ./*.gen.maude ./*.pre.gen ./*.prepre.gen ./a.out ./*.kdump ./*.pre.pre $(SEMANTICS_DIR)/settings.k
