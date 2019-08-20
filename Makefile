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
Q='
QQ="

TOP=top
ARCHITECTURE=MachXO3L
DEVICE=LCMXO3L-6900C
PERFORMANCE_GRADE=5
PACKAGE=CABGA256
LIBRARY=work

HDL_PATH=${PRJ_ROOT}${SEP}hdl
HDL_FILES=$(shell find ${HDL_PATH} -name "*.v" -o -name "*.sv")
HDL_FILES_VLOG=$(shell find ${HDL_PATH} -name "*.v" -o -name "*.sv")
CONSTR_FOLDER=${PRJ_ROOT}${SEP}constr
CONSTR_FILE=$(shell find ${CONSTR_FOLDER} -name "*.sdc")
PREF_FILE=$(shell find ${CONSTR_FOLDER} -name "*.lpf")
INCLUDE_PATH=${PRJ_ROOT}${SEP}inc

DIAMOND_PATH=/cygdrive/c/lattice_diamond/diamond/3.10_x64/ispfpga/bin/nt64
DIAMOND_PATH2=/cygdrive/c/lattice_diamond/diamond/3.10_x64/bin/nt64/

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
SYN_OPT.SDC=${CONSTR_FILE}
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
TIMING_TOOL=${DIAMOND_PATH}${SEP}trce.exe
TIMING_REPORT=${PAR_FOLDER}${SEP}${TOP}.tim.log
IOTIMING_TOOL=${DIAMOND_PATH}${SEP}iotiming.exe
IOTIMING_REPORT=${PAR_FOLDER}${SEP}${TOP}.iotim.log
SSOANA_TOOL=${DIAMOND_PATH}${SEP}ssoana.exe
SSOANA_REPORT=${PAR_FOLDER}${SEP}${TOP}.ssoana.log

BITGEN_TOOL=${DIAMOND_PATH}${SEP}bitgen.exe
BITGEN_FOLDER=${BUILD_PATH}${SEP}bit
BITGEN_SCRIPT=${BITGEN_FOLDER}${SEP}${TOP}_bit.tcl
# .bit file is for SRAM programming, .jed file for NVCM programming.

BITGEN_BITFILE=${BITGEN_FOLDER}${SEP}${TOP}.bit
BITGEN_JEDFILE=${BITGEN_FOLDER}${SEP}${TOP}.jed
BITGEN_LOG=${BITGEN_FOLDER}${SEP}${TOP}.bitgen.log

PROGRAM_TOOL=${DIAMOND_PATH2}${SEP}pgrcmd.exe
PROGRAM_FILE=${BITGEN_FOLDER}${SEP}${TOP}.xcf
PROGRAM_LOG=${BITGEN_FOLDER}${SEP}${TOP}.program.log

.DEFAULT_GOAL=${BITGEN_BITFILE}

.PHONY: help
help:
	@echo $(Q)Usage: make <target>$(Q)
	@echo $(Q)  where target is one of$(Q)
	@echo $(Q)    ${SYN_NETLIST}$(Q)
	@echo $(Q)    ${SYNP_NETLIST} (only with USE_SYNPLIFY)$(Q)
	@echo $(Q)    ${NGD_NETLIST}$(Q)
	@echo $(Q)    ${MAP_NETLIST}$(Q)
	@echo $(Q)    ${PAR_NETLIST}$(Q)
	@echo $(Q)    ${BITGEN_BITFILE} (default)$(Q)

${SYNP_SCRIPT}: ${HDL_FILES} ${CONSTR_FILE}
	$(shell mkdir -p ${SYNP_FOLDER})
	$(shell printf ${QQ}#-- Synplify project file.\n${QQ} > ${SYNP_SCRIPT})
	$(shell printf ${QQ}#device options\n${QQ} >> ${SYNP_SCRIPT})
	$(shell printf ${QQ}set_option -technology MACHXO3L\n${QQ} >> ${SYNP_SCRIPT})
	$(shell printf ${QQ}set_option -part LCMXO3L_6900C\n${QQ} >> ${SYNP_SCRIPT})
	$(shell printf ${QQ}set_option -package BG256C\n${QQ} >> ${SYNP_SCRIPT})
	$(shell printf ${QQ}set_option -speed_grade -5\n${QQ} >> ${SYNP_SCRIPT})
	$(shell printf ${QQ}#compilation/mapping options\n${QQ} >> ${SYNP_SCRIPT})
	$(shell printf ${QQ}set_option -symbolic_fsm_compiler true\n${QQ} >> ${SYNP_SCRIPT})
	$(shell printf ${QQ}set_option -resource_sharing true\n${QQ} >> ${SYNP_SCRIPT})
	$(shell printf ${QQ}#use verilog 2001 standard option\n${QQ} >> ${SYNP_SCRIPT})
	$(shell printf ${QQ}set_option -vlog_std v2001\n${QQ} >> ${SYNP_SCRIPT})
	$(shell printf ${QQ}#map options\n${QQ} >> ${SYNP_SCRIPT})
	$(shell printf ${QQ}set_option -frequency 100\n${QQ} >> ${SYNP_SCRIPT})
	$(shell printf ${QQ}set_option -maxfan 1000\n${QQ} >> ${SYNP_SCRIPT})
	$(shell printf ${QQ}set_option -auto_constrain_io 0\n${QQ} >> ${SYNP_SCRIPT})
	$(shell printf ${QQ}set_option -disable_io_insertion false\n${QQ} >> ${SYNP_SCRIPT})
	$(shell printf ${QQ}set_option -retiming false\n${QQ} >> ${SYNP_SCRIPT})
	$(shell printf ${QQ}set_option -pipe true\n${QQ} >> ${SYNP_SCRIPT})
	$(shell printf ${QQ}set_option -force_gsr false\n${QQ} >> ${SYNP_SCRIPT})
	$(shell printf ${QQ}set_option -compiler_compatible 0\n${QQ} >> ${SYNP_SCRIPT})
	$(shell printf ${QQ}set_option -dup 1\n${QQ} >> ${SYNP_SCRIPT})
	$(shell for f in ${CONSTR_FILE}; do \
    printf ${QQ}add_file -constraint $$(realpath $$f --relative-to ${SYN_FOLDER})\n${QQ} >> ${SYNP_SCRIPT}; \
  done)
	$(shell printf ${QQ}set_option -default_enum_encoding default\n${QQ} >> ${SYNP_SCRIPT})
	$(shell printf ${QQ}#simulation options\n${QQ} >> ${SYNP_SCRIPT})
	$(shell printf ${QQ}#timing analysis options\n${QQ} >> ${SYNP_SCRIPT})
	$(shell printf ${QQ}#automatic place and route (vendor) options\n${QQ} >> ${SYNP_SCRIPT})
	$(shell printf ${QQ}set_option -write_apr_constraint 1\n${QQ} >> ${SYNP_SCRIPT})
	$(shell printf ${QQ}#synplifyPro options\n${QQ} >> ${SYNP_SCRIPT})
	$(shell printf ${QQ}set_option -fix_gated_and_generated_clocks 1\n${QQ} >> ${SYNP_SCRIPT})
	$(shell printf ${QQ}set_option -update_models_cp 0\n${QQ} >> ${SYNP_SCRIPT})
	$(shell printf ${QQ}set_option -resolve_multiple_driver 0\n${QQ} >> ${SYNP_SCRIPT})
	$(shell printf ${QQ}#-- add_file options\n${QQ} >> ${SYNP_SCRIPT})
	$(shell printf ${QQ}set_option -include_path $(shell realpath ${INCLUDE_PATH} --relative-to ${SYN_FOLDER})\n${QQ} >> ${SYNP_SCRIPT})
	$(shell for f in ${HDL_FILES}; do \
    printf ${QQ}add_file -verilog $$(realpath $$f --relative-to ${SYN_FOLDER})\n${QQ} >> ${SYNP_SCRIPT}; \
  done)
	$(shell printf ${QQ}#-- top module name\n${QQ} >> ${SYNP_SCRIPT})
	$(shell printf ${QQ}set_option -top_module ${TOP}\n${QQ} >> ${SYNP_SCRIPT})
	$(shell printf ${QQ}#-- set result format/file last\n${QQ} >> ${SYNP_SCRIPT})
	$(shell printf ${QQ}project -result_file $(shell realpath ${SYNP_NETLIST} --relative-to ${SYN_FOLDER})\n${QQ} >> ${SYNP_SCRIPT})
	$(shell printf ${QQ}#-- error message log file\n${QQ} >> ${SYNP_SCRIPT})
	$(shell printf ${QQ}project -SYN_LOG $(shell realpath ${SYNP_LOG} --relative-to ${SYN_FOLDER})\n${QQ} >> ${SYNP_SCRIPT})
	$(shell printf ${QQ}#-- set any command lines input by customer\n${QQ} >> ${SYNP_SCRIPT})
	$(shell printf ${QQ}#-- run Synplify with 'arrange HDL file'\n${QQ} >> ${SYNP_SCRIPT})
	$(shell printf ${QQ}project -run -clean\n${QQ} >> ${SYNP_SCRIPT})

${SYNP_NETLIST}: ${SYNP_SCRIPT}
	cd ${SYNP_FOLDER} && ${SYNP_TOOL} \
    -prj $(shell realpath ${SYNP_SCRIPT} --relative-to ${SYNP_FOLDER})
	${EDIF2NGO_TOOL} \
    -l ${ARCHITECTURE} \
    -d ${DEVICE} \
    -cbn \
    ${SYNP_NETLIST} \
    ${SYN_NETLIST}

${SYN_NETLIST}: ${HDL_FILES} ${CONSTR_FILE}
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
    $(if ${CONSTR_FILE},-sdc $(shell realpath ${CONSTR_FILE} --relative-to=${SYN_FOLDER}),) \
    -lpf 1 \
    -ngo $(shell realpath ${SYN_NETLIST} --relative-to=${SYN_FOLDER})
    #-lpf $(shell realpath ${PREF_FILE} --relative-to=${SYN_FOLDER}) \
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
    $(shell realpath ${PREF_FILE} --relative-to=${MAP_FOLDER}) \
    -o $(shell realpath ${MAP_NETLIST} --relative-to=${MAP_FOLDER}) \
    -pr $(shell realpath ${MAP_PREF_FILE} --relative-to=${MAP_FOLDER})

${PAR_NETLIST}: ${MAP_NETLIST}
	cd ${PAR_FOLDER} && ${PAR_TOOL} \
    -w \
    $(shell realpath ${MAP_NETLIST} --relative-to=${PAR_FOLDER}) \
    $(shell realpath ${PAR_NETLIST} --relative-to=${PAR_FOLDER})

${BITGEN_BITFILE}: ${PAR_NETLIST}
	cd ${BITGEN_FOLDER} && ${BITGEN_TOOL} \
    -w \
    $(shell realpath ${PAR_NETLIST} --relative-to=${BITGEN_FOLDER}) \
    $(shell realpath ${BITGEN_BITFILE} --relative-to=${BITGEN_FOLDER})
	cd ${BITGEN_FOLDER} && ${BITGEN_TOOL} \
    -w \
    -jedec \
    $(shell realpath ${PAR_NETLIST} --relative-to=${BITGEN_FOLDER}) \
    $(shell realpath ${BITGEN_JEDFILE} --relative-to=${BITGEN_FOLDER})

${PROGRAM_FILE}: ${BITGEN_BITFILE}
# Double quotes which must be printed as such need to be escaped.
	cd ${BITGEN_FOLDER}
	$(shell printf ${QQ}<?xml version='1.0' encoding='utf-8' ?>\n${QQ} > ${PROGRAM_FILE})
	$(shell printf ${QQ}<!DOCTYPE		ispXCF	SYSTEM	\"IspXCF.dtd\" >\n${QQ} >> ${PROGRAM_FILE})
	$(shell printf ${QQ}<ispXCF version=\"3.9.0\">\n${QQ} >> ${PROGRAM_FILE})
	$(shell printf ${QQ}  <Comment></Comment>\n${QQ} >> ${PROGRAM_FILE})
	$(shell printf ${QQ}  <Chain>\n${QQ} >> ${PROGRAM_FILE})
	$(shell printf ${QQ}    <Comm>JTAG</Comm>\n${QQ} >> ${PROGRAM_FILE})
	$(shell printf ${QQ}    <Device>${QQ} >> ${PROGRAM_FILE})
	$(shell printf ${QQ}      <SelectedProg value=\"TRUE\"/>\n${QQ} >> ${PROGRAM_FILE})
	$(shell printf ${QQ}      <Pos>1</Pos>\n${QQ} >> ${PROGRAM_FILE})
	$(shell printf ${QQ}      <Vendor>Lattice</Vendor>\n${QQ} >> ${PROGRAM_FILE})
	$(shell printf ${QQ}      <Family>${ARCHITECTURE}</Family>\n${QQ} >> ${PROGRAM_FILE})
	$(shell printf ${QQ}      <Name>${DEVICE}</Name>\n${QQ} >> ${PROGRAM_FILE})
	$(shell printf ${QQ}      <IDCode>0x412bd043</IDCode>\n${QQ} >> ${PROGRAM_FILE})
	$(shell printf ${QQ}      <Package>All</Package>\n${QQ} >> ${PROGRAM_FILE})
	$(shell printf ${QQ}      <PON>${DEVICE}</PON>\n${QQ} >> ${PROGRAM_FILE})
	$(shell printf ${QQ}      <Bypass>\n${QQ} >> ${PROGRAM_FILE})
	$(shell printf ${QQ}        <InstrLen>8</InstrLen>\n${QQ} >> ${PROGRAM_FILE})
	$(shell printf ${QQ}        <InstrVal>11111111</InstrVal>\n${QQ} >> ${PROGRAM_FILE})
	$(shell printf ${QQ}        <BScanLen>1</BScanLen>\n${QQ} >> ${PROGRAM_FILE})
	$(shell printf ${QQ}        <BScanVal>0</BScanVal>\n${QQ} >> ${PROGRAM_FILE})
	$(shell printf ${QQ}      </Bypass>\n${QQ} >> ${PROGRAM_FILE})
	$(shell printf ${QQ}      <File>$$(realpath ${BITGEN_BITFILE} --relative-to ${BITGEN_FOLDER})</File>\n${QQ} >> ${PROGRAM_FILE})
	$(shell printf ${QQ}      <FileTime>08/20/19 20:08:50</FileTime>\n${QQ} >> ${PROGRAM_FILE})
	$(shell printf ${QQ}      <Operation>SRAM Erase,Program,Verify</Operation>\n${QQ} >> ${PROGRAM_FILE})
	$(shell printf ${QQ}      <Option>\n${QQ} >> ${PROGRAM_FILE})
	$(shell printf ${QQ}        <SVFVendor>JTAG STANDARD</SVFVendor>\n${QQ} >> ${PROGRAM_FILE})
	$(shell printf ${QQ}        <IOState>HighZ</IOState>\n${QQ} >> ${PROGRAM_FILE})
	$(shell printf ${QQ}        <PreloadLength>664</PreloadLength>\n${QQ} >> ${PROGRAM_FILE})
	$(shell printf ${QQ}        <IOVectorData>0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF</IOVectorData>\n${QQ} >> ${PROGRAM_FILE})
	$(shell printf ${QQ}        <Usercode>0x00000000</Usercode>\n${QQ} >> ${PROGRAM_FILE})
	$(shell printf ${QQ}        <AccessMode>SRAM</AccessMode>\n${QQ} >> ${PROGRAM_FILE})
	$(shell printf ${QQ}      </Option>\n${QQ} >> ${PROGRAM_FILE})
	$(shell printf ${QQ}    </Device>\n${QQ} >> ${PROGRAM_FILE})
	$(shell printf ${QQ}  </Chain>\n${QQ} >> ${PROGRAM_FILE})
	$(shell printf ${QQ}  <ProjectOptions>\n${QQ} >> ${PROGRAM_FILE})
	$(shell printf ${QQ}    <Program>SEQUENTIAL</Program>\n${QQ} >> ${PROGRAM_FILE})
	$(shell printf ${QQ}    <Process>ENTIRED CHAIN</Process>\n${QQ} >> ${PROGRAM_FILE})
	$(shell printf ${QQ}    <OperationOverride>No Override</OperationOverride>\n${QQ} >> ${PROGRAM_FILE})
	$(shell printf ${QQ}    <StartTAP>TLR</StartTAP>\n${QQ} >> ${PROGRAM_FILE})
	$(shell printf ${QQ}    <EndTAP>TLR</EndTAP>\n${QQ} >> ${PROGRAM_FILE})
	$(shell printf ${QQ}    <VerifyUsercode value=\"FALSE\"/>\n${QQ} >> ${PROGRAM_FILE})
	$(shell printf ${QQ}    <TCKDelay>1</TCKDelay>\n${QQ} >> ${PROGRAM_FILE})
	$(shell printf ${QQ}  </ProjectOptions>\n${QQ} >> ${PROGRAM_FILE})
	$(shell printf ${QQ}  <CableOptions>\n${QQ} >> ${PROGRAM_FILE})
	$(shell printf ${QQ}    <CableName>USB2</CableName>\n${QQ} >> ${PROGRAM_FILE})
	$(shell printf ${QQ}    <PortAdd>FTUSB-0</PortAdd>\n${QQ} >> ${PROGRAM_FILE})
	$(shell printf ${QQ}    <USBID>Lattice XO3L Starter Kit A Location 0000 Serial A</USBID>\n${QQ} >> ${PROGRAM_FILE})
	$(shell printf ${QQ}  </CableOptions>\n${QQ} >> ${PROGRAM_FILE})
	$(shell printf ${QQ}</ispXCF>\n${QQ} >> ${PROGRAM_FILE})

${TIMING_REPORT}: ${PAR_NETLIST}
	cd ${PAR_FOLDER} && ${TIMING_TOOL} \
    -clockdomain \
    -sethld \
    -setuphold \
    -e 100 \
    $(shell realpath ${PAR_NETLIST} --relative-to=${PAR_FOLDER}) \
    $(shell realpath ${MAP_PREF_FILE} --relative-to=${PAR_FOLDER}) \
    -o $(shell realpath ${TIMING_REPORT} --relative-to=${PAR_FOLDER})

${IOTIMING_REPORT}: ${PAR_NETLIST}
	cd ${PAR_FOLDER} && ${IOTIMING_TOOL} \
    -s \
    $(shell realpath ${PAR_NETLIST} --relative-to=${PAR_FOLDER}) \
    $(shell realpath ${MAP_PREF_FILE} --relative-to=${PAR_FOLDER}) \
    -o $(shell realpath ${IOTIMING_REPORT} --relative-to=${PAR_FOLDER})

${SSOANA_REPORT}: ${PAR_NETLIST}
	cd ${PAR_FOLDER} && ${SSOANA_TOOL} \
    -d ${DEVICE} \
    -p ${PACKAGE} \
    -o $(shell realpath ${SSOANA_REPORT} --relative-to=${PAR_FOLDER}) \
    $(shell realpath ${PAR_NETLIST} --relative-to=${PAR_FOLDER}) \
    $(shell realpath ${SYN_PREF_FILE} --relative-to=${PAR_FOLDER})

.PHONY: timing
timing: ${TIMING_REPORT} ${IOTIMING_REPORT}

.PHONY: program
program: ${PROGRAM_FILE}
	cd ${BITGEN_FOLDER} && ${PROGRAM_TOOL} \
    -infile $(shell realpath ${PROGRAM_FILE} --relative-to=${BITGEN_FOLDER}) \
    -logile $(shell realpath ${PROGRAM_LOG} --relative-to=${BITGEN_FOLDER}) \
    -cabletype USB2 \
    -portaddress FTUSB-0 \
    -TCK 2

.PHONY: folders
folders:
	$(shell mkdir -p ${SYN_FOLDER} $(if ${USE_SYNPLIFY},${SYNP_FOLDER},) ${NGD_FOLDER} ${MAP_FOLDER} ${PAR_FOLDER} ${BITGEN_FOLDER})

.PHONY: all
ALL: ${BITGEN_BITFILE} folders

.PHONY: clean
clean:
	-rm -rf ${SYN_FOLDER}${SEP}* ${SYNP_FOLDER}${SEP}* ${NGD_FOLDER}${SEP}* \
    ${MAP_FOLDER}${SEP}* ${PAR_FOLDER}${SEP}* ${BITGEN_FOLDER}${SEP}*
