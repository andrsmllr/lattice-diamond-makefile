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
ARCHITECTURE=MachXO3L
DEVICE=LCMXO3L-6900C
PERFMC_GRADE=5
PACKAGE=CABGA256
LIBRARY=work

HDL_PATH=${PRJ_ROOT}${SEP}hdl
HDL_FILES=$(shell find ${HDL_PATH} -name "*.v" -o -name "*.sv")
HDL_FILES_VLOG=$(shell find ${HDL_PATH} -name "*.v" -o -name "*.sv")
CONSTR_FOLDER=${PRJ_ROOT}${SEP}constr
CONSTR_FILES=$(shell find ${CONSTR_FOLDER} -name "*.sdc")
INCLUDE_PATH=${PRJ_ROOT}${SEP}inc

DIAMOND_PATH=/cygdrive/c/lattice_diamond/diamond/3.10_x64/ispfpga/bin/nt64/
#DIAMOND_PATH=/cygdrive/c/lattice_diamond/diamond/3.10_x64/bin/nt64/

#SYNTH_TOOL=/cygdrive/c/lattice_diamond/diamond/3.10_x64/bin/nt64/synpwrap.exe
#SYNTH_FOLDER=${PRJ_ROOT}${SEP}synth
#SYNTH_SCRIPT=${SYNTH_FOLDER}${SEP}${TOP}_synth.tcl
#SYNTH_NETLIST=${SYNTH_FOLDER}${SEP}${TOP}.edif
#SYNTH_LOG=${SYNTH_FOLDER}${SEP}${TOP}.srp

SYNTH_TOOL=${DIAMOND_PATH}${SEP}synthesis.exe
SYNTH_FOLDER=${PRJ_ROOT}${SEP}syn
SYNTH_FILES_VLOG=$(shell find ${HDL_PATH} \( -name "*.v" -o -name "*.sv" \) -exec realpath --relative-to=${SYNTH_FOLDER} {} \;)
SYNTH_FILES_VHDL=$(shell find ${HDL_PATH} \( -name "*.vhd" -o -name "*.vhdl" \) -exec realpath --relative-to=${SYNTH_FOLDER} {} \;)
SYNTH_OPT.HDL_PARAMS=
SYNTH_OPT.SDC=${CONSTR_FILES}
SYNTH_OPT.OPTIMIZATION=balanced
SYNTH_SCRIPT=${SYNTH_FOLDER}${SEP}${TOP}_syn.tcl
SYNTH_NETLIST=${SYNTH_FOLDER}${SEP}${TOP}.ngo
SYNTH_PREF_FILE=${SYNTH_FOLDER}${SEP}${TOP}.lpf
SYNTH_LOG=${SYNTH_FOLDER}${SEP}${TOP}.syn.log

NGD_TOOL=${DIAMOND_PATH}${SEP}ngdbuild.exe
NGD_FOLDER=${PRJ_ROOT}${SEP}ngdbld
NGD_SCRIPT=${NGD_FOLDER}${SEP}${TOP}_ngdbuild.tcl
NGD_NETLIST=${NGD_FOLDER}${SEP}${TOP}.ngd
NGD_LOG=${NGD_FOLDER}${SEP}${TOP}.ngd.log

MAP_TOOL=${DIAMOND_PATH}${SEP}map.exe
MAP_FOLDER=${PRJ_ROOT}${SEP}map
MAP_SCRIPT=${MAP_FOLDER}${SEP}${TOP}_map.tcl
MAP_NETLIST=${MAP_FOLDER}${SEP}${TOP}.ncd
MAP_LOG=${MAP_FOLDER}${SEP}${TOP}.map.log

PAR_TOOL=${DIAMOND_PATH}${SEP}par.exe
PAR_FOLDER=${PRJ_ROOT}${SEP}par
PAR_SCRIPT=${PAR_FOLDER}${SEP}${TOP}_par.tcl
PAR_NETLIST=${PAR_FOLDER}${SEP}${TOP}.ncd
PAR_LOG=${PAR_FOLDER}${SEP}${TOP}.par.log

BITGEN_TOOL=${DIAMOND_PATH}${SEP}bitgen.exe
BITGEN_FOLDER=${PRJ_ROOT}${SEP}bit
BITGEN_SCRIPT=${BITGEN_FOLDER}${SEP}${TOP}_bit.tcl
BITFILE=${BITGEN_FOLDER}${SEP}${TOP}.bit
BITGEN_LOG=${BITGEN_FOLDER}${SEP}${TOP}.bitgen.log

.DEFAULT_GOAL=${SYNTH_NETLIST}

.PHONY: help
help:
	@echo $(Q)Usage: make ${SYNTH_NETLIST}$(Q)

${SYNTH_SCRIPT}: ${HDL_FILES} ${CONSTR_FILES}
	$(shell mkdir -p ${SYNTH_FOLDER})
	$(shell printf $(Q)#-- Synplify project file.\n$(Q) > ${SYNTH_SCRIPT})
	$(shell printf $(Q)#device options\n$(Q) >> ${SYNTH_SCRIPT})
	$(shell printf $(Q)set_option -technology MACHXO3L\n$(Q) >> ${SYNTH_SCRIPT})
	$(shell printf $(Q)set_option -part LCMXO3L_6900C\n$(Q) >> ${SYNTH_SCRIPT})
	$(shell printf $(Q)set_option -package BG256C\n$(Q) >> ${SYNTH_SCRIPT})
	$(shell printf $(Q)set_option -speed_grade -5\n$(Q) >> ${SYNTH_SCRIPT})
	$(shell printf $(Q)#compilation/mapping options\n$(Q) >> ${SYNTH_SCRIPT})
	$(shell printf $(Q)set_option -symbolic_fsm_compiler true\n$(Q) >> ${SYNTH_SCRIPT})
	$(shell printf $(Q)set_option -resource_sharing true\n$(Q) >> ${SYNTH_SCRIPT})
	$(shell printf $(Q)#use verilog 2001 standard option\n$(Q) >> ${SYNTH_SCRIPT})
	$(shell printf $(Q)set_option -vlog_std v2001\n$(Q) >> ${SYNTH_SCRIPT})
	$(shell printf $(Q)#map options\n$(Q) >> ${SYNTH_SCRIPT})
	$(shell printf $(Q)set_option -frequency 100\n$(Q) >> ${SYNTH_SCRIPT})
	$(shell printf $(Q)set_option -maxfan 1000\n$(Q) >> ${SYNTH_SCRIPT})
	$(shell printf $(Q)set_option -auto_constrain_io 0\n$(Q) >> ${SYNTH_SCRIPT})
	$(shell printf $(Q)set_option -disable_io_insertion false\n$(Q) >> ${SYNTH_SCRIPT})
	$(shell printf $(Q)set_option -retiming false\n$(Q) >> ${SYNTH_SCRIPT})
	$(shell printf $(Q)set_option -pipe true\n$(Q) >> ${SYNTH_SCRIPT})
	$(shell printf $(Q)set_option -force_gsr false\n$(Q) >> ${SYNTH_SCRIPT})
	$(shell printf $(Q)set_option -compiler_compatible 0\n$(Q) >> ${SYNTH_SCRIPT})
	$(shell printf $(Q)set_option -dup 1\n$(Q) >> ${SYNTH_SCRIPT})
	$(shell for f in ${CONSTR_FILES}; do \
    printf $(Q)add_file -constraint $$(realpath $$f --relative-to ${SYNTH_FOLDER})\n$(Q) >> ${SYNTH_SCRIPT}; \
  done)
	$(shell printf $(Q)set_option -default_enum_encoding default\n$(Q) >> ${SYNTH_SCRIPT})
	$(shell printf $(Q)#simulation options\n$(Q) >> ${SYNTH_SCRIPT})
	$(shell printf $(Q)#timing analysis options\n$(Q) >> ${SYNTH_SCRIPT})
	$(shell printf $(Q)#automatic place and route (vendor) options\n$(Q) >> ${SYNTH_SCRIPT})
	$(shell printf $(Q)set_option -write_apr_constraint 1\n$(Q) >> ${SYNTH_SCRIPT})
	$(shell printf $(Q)#synplifyPro options\n$(Q) >> ${SYNTH_SCRIPT})
	$(shell printf $(Q)set_option -fix_gated_and_generated_clocks 1\n$(Q) >> ${SYNTH_SCRIPT})
	$(shell printf $(Q)set_option -update_models_cp 0\n$(Q) >> ${SYNTH_SCRIPT})
	$(shell printf $(Q)set_option -resolve_multiple_driver 0\n$(Q) >> ${SYNTH_SCRIPT})
	$(shell printf $(Q)#-- add_file options\n$(Q) >> ${SYNTH_SCRIPT})
	$(shell printf $(Q)set_option -include_path $(shell realpath ${INCLUDE_PATH} --relative-to ${SYNTH_FOLDER})\n$(Q) >> ${SYNTH_SCRIPT})
	$(shell for f in ${HDL_FILES}; do \
    printf $(Q)add_file -verilog $$(realpath $$f --relative-to ${SYNTH_FOLDER})\n$(Q) >> ${SYNTH_SCRIPT}; \
  done)
	$(shell printf $(Q)#-- top module name\n$(Q) >> ${SYNTH_SCRIPT})
	$(shell printf $(Q)set_option -top_module ${TOP}\n$(Q) >> ${SYNTH_SCRIPT})
	$(shell printf $(Q)#-- set result format/file last\n$(Q) >> ${SYNTH_SCRIPT})
	$(shell printf $(Q)project -result_file $(shell realpath ${SYNTH_NETLIST} --relative-to ${SYNTH_FOLDER})\n$(Q) >> ${SYNTH_SCRIPT})
	$(shell printf $(Q)#-- error message log file\n$(Q) >> ${SYNTH_SCRIPT})
	$(shell printf $(Q)project -SYNTH_LOG $(shell realpath ${SYNTH_LOG} --relative-to ${SYNTH_FOLDER})\n$(Q) >> ${SYNTH_SCRIPT})
	$(shell printf $(Q)#-- set any command lines input by customer\n$(Q) >> ${SYNTH_SCRIPT})
	$(shell printf $(Q)#-- run Synplify with 'arrange HDL file'\n$(Q) >> ${SYNTH_SCRIPT})
	$(shell printf $(Q)project -run -clean\n$(Q) >> ${SYNTH_SCRIPT})

${SYNTH_NETLIST}2: ${SYNTH_SCRIPT}
	$(shell mkdir -p ${SYNTH_FOLDER})
	cd ${SYNTH_FOLDER} && ${SYNTH_TOOL} -prj $(shell realpath ${SYNTH_SCRIPT} --relative-to ${SYNTH_FOLDER})

${SYNTH_NETLIST}: ${HDL_FILES} ${CONSTR_FILES}
	$(shell mkdir -p ${SYNTH_FOLDER})
	cd ${SYNTH_FOLDER} && ${SYNTH_TOOL} \
  -a ${ARCHITECTURE} \
  -d ${DEVICE} \
  -s ${PERFMC_GRADE} \
  -t ${PACKAGE} \
  -p $(shell realpath ${INCLUDE_PATH} --relative-to=${SYNTH_FOLDER}) \
  -top ${TOP} \
  -hdl_param ${SYNTH_OPT.HDL_PARAMS} \
  -ver ${SYNTH_FILES_VLOG} \
  -optimization_goal ${SYNTH_OPT.OPTIMIZATION} \
  -logfile $(shell realpath ${SYNTH_LOG} --relative-to=${SYNTH_FOLDER}) \
  -sdc $(shell realpath ${CONSTR_FILES} --relative-to=${SYNTH_FOLDER}) \
  -lpf 1 \
  -ngd $(shell realpath ${NGD_NETLIST} --relative-to=${SYNTH_FOLDER})
  # -ngo $(shell realpath ${SYNTH_NETLIST} --relative-to=${SYNTH_FOLDER})

${NGD_NETLIST}: ${SYNTH_NETLIST}
	$(shell mkdir -p ${NGD_FOLDER})
	# cd ${NGD_FOLDER} && ${NGD_TOOL} \
  # -a ${ARCHITECTURE} \
  # -d ${DEVICE} \
  # $(shell realpath ${SYNTH_NETLIST} --relative-to=${NGD_FOLDER}) \
  # $(shell realpath ${NGD_NETLIST} --relative-to=${NGD_FOLDER})
  
${MAP_NETLIST}: ${NGD_NETLIST}
	$(shell mkdir -p ${MAP_FOLDER})
	cd ${MAP_FOLDER} && ${MAP_TOOL} \
  $(shell realpath ${NGD_NETLIST} --relative-to=${MAP_FOLDER}) \
  -o $(shell realpath ${MAP_NETLIST} --relative-to=${MAP_FOLDER}) \
  -a ${ARCHITECTURE} \
  -p ${DEVICE} \
  -s ${PERFMC_GRADE} \
  -t ${PACKAGE}

${PAR_NETLIST}: ${MAP_NETLIST}
	$(shell mkdir -p ${PAR_FOLDER})
	cd ${PAR_FOLDER} && ${PAR_TOOL} \
  -w \
  $(shell realpath ${MAP_NETLIST} --relative-to=${PAR_FOLDER}) \
  $(shell realpath ${PAR_NETLIST} --relative-to=${PAR_FOLDER})

${BITFILE}: ${PAR_NETLIST}
	$(shell mkdir -p ${BITGEN_FOLDER})
	cd ${BITGEN_FOLDER} && ${BITGEN_TOOL} \
  -w \
  $(shell realpath ${PAR_NETLIST} --relative-to=${BITGEN_FOLDER}) \
  $(shell realpath ${BITFILE} --relative-to=${BITGEN_FOLDER})

.PHONY: clean
clean:
	-rm -rf ${SYNTH_FOLDER}*
