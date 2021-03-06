/*
 * Copyright (c) 2019, ARM Limited and Contributors. All rights reserved.
 *
 * SPDX-License-Identifier: BSD-3-Clause
 */

#include <drivers/arm/cci.h>
#include <drivers/arm/gic_common.h>
#include <drivers/arm/gicv2.h>
#include <platform_def.h>

.section .rodata.gic_reg_name, "aS"
gicc_regs:
	.asciz "gicc_hppir", "gicc_ahppir", "gicc_ctlr", ""
gicd_pend_reg:
	.asciz "gicd_ispendr regs (Offsets 0x200 - 0x278)\n"	\
		" Offset:\t\t\tvalue\n"
newline:
	.asciz "\n"
spacer:
	.asciz ":\t\t0x"

.section .rodata.cci_reg_name, "aS"
cci_iface_regs:
	.asciz "cci_snoop_ctrl_cluster0", "cci_snoop_ctrl_cluster1" , ""

	/* ---------------------------------------------
	 * The below macro prints out relevant GIC and
	 * CCI registers whenever an unhandled exception
	 * is taken in BL31.
	 * Clobbers: x0 - x10, x26, x27, sp
	 * ---------------------------------------------
	 */
	.macro plat_crash_print_regs
	mov_imm x26, BASE_GICD_BASE
	mov_imm x27, BASE_GICC_BASE
	/* Load the gicc reg list to x6 */
	adr	x6, gicc_regs
	/* Load the gicc regs to gp regs used by str_in_crash_buf_print */
	ldr	w8, [x27, #GICC_HPPIR]
	ldr	w9, [x27, #GICC_AHPPIR]
	ldr	w10, [x27, #GICC_CTLR]
	/* Store to the crash buf and print to console */
	bl	str_in_crash_buf_print

	/* Print the GICD_ISPENDR regs */
	add	x7, x26, #GICD_ISPENDR
	adr	x4, gicd_pend_reg
	bl	asm_print_str
gicd_ispendr_loop:
	sub	x4, x7, x26
	cmp	x4, #0x280
	b.eq	exit_print_gic_regs
	bl	asm_print_hex

	adr	x4, spacer
	bl	asm_print_str

	ldr	x4, [x7], #8
	bl	asm_print_hex

	adr	x4, newline
	bl	asm_print_str
	b	gicd_ispendr_loop
exit_print_gic_regs:

	adr	x6, cci_iface_regs
	/* Store in x7 the base address of the first interface */
	mov_imm	x7, (PLAT_MT_CCI_BASE + SLAVE_IFACE_OFFSET(	\
			PLAT_MT_CCI_CLUSTER0_SL_IFACE_IX))
	ldr	w8, [x7, #SNOOP_CTRL_REG]
	/* Store in x7 the base address of the second interface */
	mov_imm	x7, (PLAT_MT_CCI_BASE + SLAVE_IFACE_OFFSET(	\
			PLAT_MT_CCI_CLUSTER1_SL_IFACE_IX))
	ldr	w9, [x7, #SNOOP_CTRL_REG]
	/* Store to the crash buf and print to console */
	bl	str_in_crash_buf_print
	.endm
