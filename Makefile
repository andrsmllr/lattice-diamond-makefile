# Author: andrsmllr
# Description:
#   Makefile for HDL synthesis with Lattice Diamond / Synplify.
#   Tested on Windows 10 x64 + Cygwin x64 + Lattice Diamond 3.10
#
#   The default folder structure is assumed as
#   <project>/
#            +-constr  : synthesis constraints (*.sdc).
#            +-hdl     : HDL sources (*.v)
#            +-inc     : include files (*.h)
#            +-netlist : netlist output
#            +-synth   : synthesis workdir
#            Makefile  : this file
#
# TODO:
#   move synthesis options, part, package, etc. to make variables.
#   support more options

PRJ_ROOT=.
SEP=/
Q="

TOP=test3
SYNTH_PRJ_FOLDER=${PRJ_ROOT}${SEP}synth
SYNTH_PRJ_FILE=${SYNTH_PRJ_FOLDER}${SEP}${TOP}.prj
LOG_FILE=${SYNTH_PRJ_FOLDER}${SEP}${TOP}.srr
NETLIST=${SYNTH_PRJ_FOLDER}${SEP}${TOP}.edif
SYNTH_TOOL=/cygdrive/c/lattice_diamond/diamond/3.10_x64/bin/nt64/synpwrap.exe

HDL_PATH=${PRJ_ROOT}${SEP}hdl
HDL_FILES=$(shell find ${HDL_PATH} -name "*.v" -o -name "*.sv")
CONSTR_FOLDER=${PRJ_ROOT}${SEP}constr
CONSTR_FILES=$(shell find ${CONSTR_FOLDER} -name "*.sdc")
INCLUDE_PATH=${PRJ_ROOT}${SEP}inc

.DEFAULT_GOAL=${NETLIST}

.PHONY: help
help:
	@echo $(Q)Usage: make ${NETLIST}$(Q)

${SYNTH_PRJ_FILE}: ${HDL_FILES} ${CONSTR_FILES}
	$(shell mkdir -p ${SYNTH_PRJ_FOLDER})
	$(shell printf $(Q)#-- Synplify project file.\n$(Q) > ${SYNTH_PRJ_FILE})
	$(shell printf $(Q)#device options\n$(Q) >> ${SYNTH_PRJ_FILE})
	$(shell printf $(Q)set_option -technology MACHXO3L\n$(Q) >> ${SYNTH_PRJ_FILE})
	$(shell printf $(Q)set_option -part LCMXO3L_6900C\n$(Q) >> ${SYNTH_PRJ_FILE})
	$(shell printf $(Q)set_option -package BG256C\n$(Q) >> ${SYNTH_PRJ_FILE})
	$(shell printf $(Q)set_option -speed_grade -5\n$(Q) >> ${SYNTH_PRJ_FILE})
	$(shell printf $(Q)#compilation/mapping options\n$(Q) >> ${SYNTH_PRJ_FILE})
	$(shell printf $(Q)set_option -symbolic_fsm_compiler true\n$(Q) >> ${SYNTH_PRJ_FILE})
	$(shell printf $(Q)set_option -resource_sharing true\n$(Q) >> ${SYNTH_PRJ_FILE})
	$(shell printf $(Q)#use verilog 2001 standard option\n$(Q) >> ${SYNTH_PRJ_FILE})
	$(shell printf $(Q)set_option -vlog_std v2001\n$(Q) >> ${SYNTH_PRJ_FILE})
	$(shell printf $(Q)#map options\n$(Q) >> ${SYNTH_PRJ_FILE})
	$(shell printf $(Q)set_option -frequency 100\n$(Q) >> ${SYNTH_PRJ_FILE})
	$(shell printf $(Q)set_option -maxfan 1000\n$(Q) >> ${SYNTH_PRJ_FILE})
	$(shell printf $(Q)set_option -auto_constrain_io 0\n$(Q) >> ${SYNTH_PRJ_FILE})
	$(shell printf $(Q)set_option -disable_io_insertion false\n$(Q) >> ${SYNTH_PRJ_FILE})
	$(shell printf $(Q)set_option -retiming false\n$(Q) >> ${SYNTH_PRJ_FILE})
	$(shell printf $(Q)set_option -pipe true\n$(Q) >> ${SYNTH_PRJ_FILE})
	$(shell printf $(Q)set_option -force_gsr false\n$(Q) >> ${SYNTH_PRJ_FILE})
	$(shell printf $(Q)set_option -compiler_compatible 0\n$(Q) >> ${SYNTH_PRJ_FILE})
	$(shell printf $(Q)set_option -dup 1\n$(Q) >> ${SYNTH_PRJ_FILE})
	$(shell for f in ${CONSTR_FILES}; do \
    printf $(Q)add_file -constraint $$(realpath $$f --relative-to ${SYNTH_PRJ_FOLDER})\n$(Q) >> ${SYNTH_PRJ_FILE}; \
  done)
	$(shell printf $(Q)set_option -default_enum_encoding default\n$(Q) >> ${SYNTH_PRJ_FILE})
	$(shell printf $(Q)#simulation options\n$(Q) >> ${SYNTH_PRJ_FILE})
	$(shell printf $(Q)#timing analysis options\n$(Q) >> ${SYNTH_PRJ_FILE})
	$(shell printf $(Q)#automatic place and route (vendor) options\n$(Q) >> ${SYNTH_PRJ_FILE})
	$(shell printf $(Q)set_option -write_apr_constraint 1\n$(Q) >> ${SYNTH_PRJ_FILE})
	$(shell printf $(Q)#synplifyPro options\n$(Q) >> ${SYNTH_PRJ_FILE})
	$(shell printf $(Q)set_option -fix_gated_and_generated_clocks 1\n$(Q) >> ${SYNTH_PRJ_FILE})
	$(shell printf $(Q)set_option -update_models_cp 0\n$(Q) >> ${SYNTH_PRJ_FILE})
	$(shell printf $(Q)set_option -resolve_multiple_driver 0\n$(Q) >> ${SYNTH_PRJ_FILE})
	$(shell printf $(Q)#-- add_file options\n$(Q) >> ${SYNTH_PRJ_FILE})
	$(shell printf $(Q)set_option -include_path $(shell realpath ${INCLUDE_PATH} --relative-to ${SYNTH_PRJ_FOLDER})\n$(Q) >> ${SYNTH_PRJ_FILE})
	$(shell for f in ${HDL_FILES}; do \
    printf $(Q)add_file -verilog $$(realpath $$f --relative-to ${SYNTH_PRJ_FOLDER})\n$(Q) >> ${SYNTH_PRJ_FILE}; \
  done)
	$(shell printf $(Q)#-- top module name\n$(Q) >> ${SYNTH_PRJ_FILE})
	$(shell printf $(Q)set_option -top_module ${TOP}\n$(Q) >> ${SYNTH_PRJ_FILE})
	$(shell printf $(Q)#-- set result format/file last\n$(Q) >> ${SYNTH_PRJ_FILE})
	$(shell printf $(Q)project -result_file $(shell realpath ${NETLIST} --relative-to ${SYNTH_PRJ_FOLDER})\n$(Q) >> ${SYNTH_PRJ_FILE})
	$(shell printf $(Q)#-- error message log file\n$(Q) >> ${SYNTH_PRJ_FILE})
	$(shell printf $(Q)project -log_file $(shell realpath ${LOG_FILE} --relative-to ${SYNTH_PRJ_FOLDER})\n$(Q) >> ${SYNTH_PRJ_FILE})
	$(shell printf $(Q)#-- set any command lines input by customer\n$(Q) >> ${SYNTH_PRJ_FILE})
	$(shell printf $(Q)#-- run Synplify with 'arrange HDL file'\n$(Q) >> ${SYNTH_PRJ_FILE})
	$(shell printf $(Q)project -run -clean\n$(Q) >> ${SYNTH_PRJ_FILE})

${NETLIST}: ${SYNTH_PRJ_FILE}
	cd ${SYNTH_PRJ_FOLDER} && ${SYNTH_TOOL} -prj $(shell realpath ${SYNTH_PRJ_FILE} --relative-to ${SYNTH_PRJ_FOLDER})

.PHONY: clean
clean:
	-rm -rf ${SYNTH_PRJ_FOLDER}*
