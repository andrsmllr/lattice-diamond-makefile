# Author: andrsmllr
# Description:
#   Makefile for HDL synthesis with Lattice Diamond / Synplify.
#   Tested on Windows 10 x64 + Cygwin x64 + Lattice Diamond 3.10
#
#   The default folder structure is assumed as
#   <prj_root>/
#     +-build   : build folder
#       +-bit   : bitgen artefacts, bitfile for FPGA programming drops here
#       +-map   : map artefacts
#       +-ngd   : ngdbuild artefacts
#       +-par   : place & route artefacts
#       +-syn   : synthesis artefacts
#     +-constr  : synthesis constraints (*.sdc).
#     +-hdl     : HDL sources (*.v)
#     +-inc     : include files (*.vh)
#     Makefile  : this file
#
# TODO:
#   move synthesis options, part, package, etc. to make variables.
#   support more options
#   get rid of all those realpath --relative-to substitutions

PRJ_ROOT=.
SEP=/
Q="

TOP=test3
ARCHITECTURE=MachXO3L
DEVICE=LCMXO3L-6900C
PERFORMANCE_GRADE=5
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

BUILD_PATH=${PRJ_ROOT}${SEP}build

# Synplify synthesis.
USE_SYNPLIFY=
SYNP_TOOL=/cygdrive/c/lattice_diamond/diamond/3.10_x64/bin/nt64/synpwrap.exe
SYNP_FOLDER=${BUILD_PATH}${SEP}synp
SYNP_SCRIPT=${SYNP_FOLDER}${SEP}${TOP}_synp.tcl
SYNP_NETLIST=${SYNP_FOLDER}${SEP}${TOP}.edif
SYNP_LOG=${SYNP_FOLDER}${SEP}${TOP}.synp.log
EDIF2NGO_TOOL=${DIAMOND_PATH}${SEP}edif2ngd.exe

# Diamond synthesis.
SYN_TOOL=${DIAMOND_PATH}${SEP}synthesis.exe
SYN_FOLDER=${BUILD_PATH}${SEP}syn
SYN_FILES_VLOG=$(shell find ${HDL_PATH} \( -name "*.v" -o -name "*.sv" \) -exec realpath --relative-to=${SYN_FOLDER} {} \;)
SYN_FILES_VHDL=$(shell find ${HDL_PATH} \( -name "*.vhd" -o -name "*.vhdl" \) -exec realpath --relative-to=${SYN_FOLDER} {} \;)
SYN_OPT.HDL_PARAMS=
SYN_OPT.SDC=${CONSTR_FILES}
SYN_OPT.OPTIMIZATION=balanced
SYN_SCRIPT=${SYN_FOLDER}${SEP}${TOP}_syn.tcl
SYN_NETLIST=${SYN_FOLDER}${SEP}${TOP}.ngo
SYN_PREF_FILE=${SYN_FOLDER}${SEP}${TOP}.lpf
SYN_LOG=${SYN_FOLDER}${SEP}${TOP}.syn.log

NGD_TOOL=${DIAMOND_PATH}${SEP}ngdbuild.exe
NGD_FOLDER=${BUILD_PATH}${SEP}ngdbld
NGD_SCRIPT=${NGD_FOLDER}${SEP}${TOP}_ngdbuild.tcl
NGD_NETLIST=${NGD_FOLDER}${SEP}${TOP}.ngd
NGD_LOG=${NGD_FOLDER}${SEP}${TOP}.ngd.log

MAP_TOOL=${DIAMOND_PATH}${SEP}map.exe
MAP_FOLDER=${BUILD_PATH}${SEP}map
MAP_SCRIPT=${MAP_FOLDER}${SEP}${TOP}_map.tcl
MAP_NETLIST=${MAP_FOLDER}${SEP}${TOP}.ncd
MAP_PREF_FILE=${MAP_FOLDER}${SEP}${TOP}.prf
MAP_LOG=${MAP_FOLDER}${SEP}${TOP}.map.log

PAR_TOOL=${DIAMOND_PATH}${SEP}par.exe
PAR_FOLDER=${BUILD_PATH}${SEP}par
PAR_SCRIPT=${PAR_FOLDER}${SEP}${TOP}_par.tcl
PAR_NETLIST=${PAR_FOLDER}${SEP}${TOP}.ncd
PAR_LOG=${PAR_FOLDER}${SEP}${TOP}.par.log

BITGEN_TOOL=${DIAMOND_PATH}${SEP}bitgen.exe
BITGEN_FOLDER=${BUILD_PATH}${SEP}bit
BITGEN_SCRIPT=${BITGEN_FOLDER}${SEP}${TOP}_bit.tcl
BITFILE=${BITGEN_FOLDER}${SEP}${TOP}.bit
BITGEN_LOG=${BITGEN_FOLDER}${SEP}${TOP}.bitgen.log

.DEFAULT_GOAL=${BITFILE}

.PHONY: help
help:
	@echo $(Q)Usage: make <target>$(Q)
	@echo $(Q)  where target is one of$(Q)
	@echo $(Q)    ${SYN_NETLIST}$(Q)
	@echo $(Q)    ${SYNP_NETLIST} (only with USE_SYNPLIFY)$(Q)
	@echo $(Q)    ${NGD_NETLIST}$(Q)
	@echo $(Q)    ${MAP_NETLIST}$(Q)
	@echo $(Q)    ${PAR_NETLIST}$(Q)
	@echo $(Q)    ${BITFILE} (default)$(Q)

.PHONY: folders
folders:
	$(shell mkdir -p ${SYN_FOLDER} $(if ${USE_SYNPLIFY},${SYNP_FOLDER},) ${NGD_FOLDER} ${MAP_FOLDER} ${PAR_FOLDER} ${BITGEN_FOLDER})

${SYNP_SCRIPT}: ${HDL_FILES} ${CONSTR_FILES}
	$(shell mkdir -p ${SYNP_FOLDER})
	$(shell printf $(Q)#-- Synplify project file.\n$(Q) > ${SYNP_SCRIPT})
	$(shell printf $(Q)#device options\n$(Q) >> ${SYNP_SCRIPT})
	$(shell printf $(Q)set_option -technology MACHXO3L\n$(Q) >> ${SYNP_SCRIPT})
	$(shell printf $(Q)set_option -part LCMXO3L_6900C\n$(Q) >> ${SYNP_SCRIPT})
	$(shell printf $(Q)set_option -package BG256C\n$(Q) >> ${SYNP_SCRIPT})
	$(shell printf $(Q)set_option -speed_grade -5\n$(Q) >> ${SYNP_SCRIPT})
	$(shell printf $(Q)#compilation/mapping options\n$(Q) >> ${SYNP_SCRIPT})
	$(shell printf $(Q)set_option -symbolic_fsm_compiler true\n$(Q) >> ${SYNP_SCRIPT})
	$(shell printf $(Q)set_option -resource_sharing true\n$(Q) >> ${SYNP_SCRIPT})
	$(shell printf $(Q)#use verilog 2001 standard option\n$(Q) >> ${SYNP_SCRIPT})
	$(shell printf $(Q)set_option -vlog_std v2001\n$(Q) >> ${SYNP_SCRIPT})
	$(shell printf $(Q)#map options\n$(Q) >> ${SYNP_SCRIPT})
	$(shell printf $(Q)set_option -frequency 100\n$(Q) >> ${SYNP_SCRIPT})
	$(shell printf $(Q)set_option -maxfan 1000\n$(Q) >> ${SYNP_SCRIPT})
	$(shell printf $(Q)set_option -auto_constrain_io 0\n$(Q) >> ${SYNP_SCRIPT})
	$(shell printf $(Q)set_option -disable_io_insertion false\n$(Q) >> ${SYNP_SCRIPT})
	$(shell printf $(Q)set_option -retiming false\n$(Q) >> ${SYNP_SCRIPT})
	$(shell printf $(Q)set_option -pipe true\n$(Q) >> ${SYNP_SCRIPT})
	$(shell printf $(Q)set_option -force_gsr false\n$(Q) >> ${SYNP_SCRIPT})
	$(shell printf $(Q)set_option -compiler_compatible 0\n$(Q) >> ${SYNP_SCRIPT})
	$(shell printf $(Q)set_option -dup 1\n$(Q) >> ${SYNP_SCRIPT})
	$(shell for f in ${CONSTR_FILES}; do \
    printf $(Q)add_file -constraint $$(realpath $$f --relative-to ${SYN_FOLDER})\n$(Q) >> ${SYNP_SCRIPT}; \
  done)
	$(shell printf $(Q)set_option -default_enum_encoding default\n$(Q) >> ${SYNP_SCRIPT})
	$(shell printf $(Q)#simulation options\n$(Q) >> ${SYNP_SCRIPT})
	$(shell printf $(Q)#timing analysis options\n$(Q) >> ${SYNP_SCRIPT})
	$(shell printf $(Q)#automatic place and route (vendor) options\n$(Q) >> ${SYNP_SCRIPT})
	$(shell printf $(Q)set_option -write_apr_constraint 1\n$(Q) >> ${SYNP_SCRIPT})
	$(shell printf $(Q)#synplifyPro options\n$(Q) >> ${SYNP_SCRIPT})
	$(shell printf $(Q)set_option -fix_gated_and_generated_clocks 1\n$(Q) >> ${SYNP_SCRIPT})
	$(shell printf $(Q)set_option -update_models_cp 0\n$(Q) >> ${SYNP_SCRIPT})
	$(shell printf $(Q)set_option -resolve_multiple_driver 0\n$(Q) >> ${SYNP_SCRIPT})
	$(shell printf $(Q)#-- add_file options\n$(Q) >> ${SYNP_SCRIPT})
	$(shell printf $(Q)set_option -include_path $(shell realpath ${INCLUDE_PATH} --relative-to ${SYN_FOLDER})\n$(Q) >> ${SYNP_SCRIPT})
	$(shell for f in ${HDL_FILES}; do \
    printf $(Q)add_file -verilog $$(realpath $$f --relative-to ${SYN_FOLDER})\n$(Q) >> ${SYNP_SCRIPT}; \
  done)
	$(shell printf $(Q)#-- top module name\n$(Q) >> ${SYNP_SCRIPT})
	$(shell printf $(Q)set_option -top_module ${TOP}\n$(Q) >> ${SYNP_SCRIPT})
	$(shell printf $(Q)#-- set result format/file last\n$(Q) >> ${SYNP_SCRIPT})
	$(shell printf $(Q)project -result_file $(shell realpath ${SYNP_NETLIST} --relative-to ${SYN_FOLDER})\n$(Q) >> ${SYNP_SCRIPT})
	$(shell printf $(Q)#-- error message log file\n$(Q) >> ${SYNP_SCRIPT})
	$(shell printf $(Q)project -SYN_LOG $(shell realpath ${SYNP_LOG} --relative-to ${SYN_FOLDER})\n$(Q) >> ${SYNP_SCRIPT})
	$(shell printf $(Q)#-- set any command lines input by customer\n$(Q) >> ${SYNP_SCRIPT})
	$(shell printf $(Q)#-- run Synplify with 'arrange HDL file'\n$(Q) >> ${SYNP_SCRIPT})
	$(shell printf $(Q)project -run -clean\n$(Q) >> ${SYNP_SCRIPT})

${SYNP_NETLIST}: ${SYNP_SCRIPT}
	cd ${SYNP_FOLDER} && ${SYNP_TOOL} \
    -prj $(shell realpath ${SYNP_SCRIPT} --relative-to ${SYNP_FOLDER})
	${EDIF2NGO_TOOL} \
    -l ${ARCHITECTURE} \
    -d ${DEVICE} \
    -cbn \
    ${SYNP_NETLIST} \
    ${SYN_NETLIST}

${SYN_NETLIST}: ${HDL_FILES} ${CONSTR_FILES}
	cd ${SYN_FOLDER} && ${SYN_TOOL} \
    -a ${ARCHITECTURE} \
    -d ${DEVICE} \
    -s ${PERFORMANCE_GRADE} \
    -t ${PACKAGE} \
    -top ${TOP} \
    -optimization_goal ${SYN_OPT.OPTIMIZATION} \
    $(if ${SYN_OPT.HDL_PARAMS},-hdl_param ${SYN_OPT.HDL_PARAMS},) \
    $(if ${INCLUDE_PATH},-p $(shell realpath ${INCLUDE_PATH} --relative-to=${SYN_FOLDER}),) \
    $(if ${SYN_FILES_VLOG},-ver ${SYN_FILES_VLOG},) \
    $(if ${SYN_FILES_VHDL},-vhd ${SYN_FILES_VHDL},) \
    $(if ${SYN_LOG},-logfile $(shell realpath ${SYN_LOG} --relative-to=${SYN_FOLDER}),) \
    $(if ${CONSTR_FILES},-sdc $(shell realpath ${CONSTR_FILES} --relative-to=${SYN_FOLDER}),) \
    -lpf 1 \
    -ngo $(shell realpath ${SYN_NETLIST} --relative-to=${SYN_FOLDER})
    # -ngd $(shell realpath ${NGD_NETLIST} --relative-to=${SYN_FOLDER})

${NGD_NETLIST}: $(if ${USE_SYNPLIFY},${SYNP_NETLIST},${SYN_NETLIST})
	cd ${NGD_FOLDER} && ${NGD_TOOL} \
    -a ${ARCHITECTURE} \
    -d ${DEVICE} \
    $(shell realpath ${SYN_NETLIST} --relative-to=${NGD_FOLDER}) \
    $(shell realpath ${NGD_NETLIST} --relative-to=${NGD_FOLDER})
  
${MAP_NETLIST}: ${NGD_NETLIST}
	cd ${MAP_FOLDER} && ${MAP_TOOL} \
    -a ${ARCHITECTURE} \
    -p ${DEVICE} \
    -s ${PERFORMANCE_GRADE} \
    -t ${PACKAGE} \
    $(shell realpath ${NGD_NETLIST} --relative-to=${MAP_FOLDER}) \
    -o $(shell realpath ${MAP_NETLIST} --relative-to=${MAP_FOLDER}) \
    -pr $(shell realpath ${MAP_PREF_FILE} --relative-to=${MAP_FOLDER})

${PAR_NETLIST}: ${MAP_NETLIST}
	cd ${PAR_FOLDER} && ${PAR_TOOL} \
    -w \
    $(shell realpath ${MAP_NETLIST} --relative-to=${PAR_FOLDER}) \
    $(shell realpath ${PAR_NETLIST} --relative-to=${PAR_FOLDER})

${BITFILE}: ${PAR_NETLIST}
	cd ${BITGEN_FOLDER} && ${BITGEN_TOOL} \
    -w \
    $(shell realpath ${PAR_NETLIST} --relative-to=${BITGEN_FOLDER}) \
    $(shell realpath ${BITFILE} --relative-to=${BITGEN_FOLDER})

.PHONY: all
ALL: ${BITFILE} folders

.PHONY: clean
clean:
	-rm -rf ${SYN_FOLDER}${SEP}* ${SYNP_FOLDER}${SEP}* ${NGD_FOLDER}${SEP}* \
    ${MAP_FOLDER}${SEP}* ${PAR_FOLDER}${SEP}* ${BITGEN_FOLDER}${SEP}*
