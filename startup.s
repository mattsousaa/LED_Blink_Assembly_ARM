/*
Bare metal BeagleBone Green example for turning on led USR0.
*/

//Registers
.equ WDT_BASE, 0x44E35000
.equ UART0_BASE, 0x44E09000
.equ ARM_CODE_IMPLEMENTOR, 0x41000000
.equ ARM_CODE_PRI_PAR_NUM, 0x0000C080
.equ SUPPORT_THUMB, 0x00000030
.equ SUPPORT_ARM, 0x00000001
.equ L1_D, 0xE00FE01A
.equ L1_I, 0x200FE01A
.equ L2_D, 0xF03FE03A

_start:
    /* init */
    	mrs r0, cpsr
    	bic r0, r0, #0x1F @ clear mode bits
    	orr r0, r0, #0x13 @ set SVC mode
    	orr r0, r0, #0xC0 @ disable FIQ and IRQ
    	msr cpsr, r0

	bl .disable_wdt
	
.read_main_id_register:

	mrc p15, 0, r0, c0, c0, 0

	mov r1, #0xFF000000
	and r1, r0, r1
	
	ldr r2, =ARM_CODE_IMPLEMENTOR
	cmp r1, r2
	
	bleq .print_arm

	movw r1, #0x0000FFF0
	and r1, r0, r1
	
	ldr r2, =ARM_CODE_PRI_PAR_NUM
	cmp r1, r2
	
	bleq .print_part_number

.read_processor_feature_reg:

	mrc p15, 0, r0, c0, c1, 0
	
	mov r1, #0x000000F0
	and r1, r0, r1

	ldr r2, =SUPPORT_THUMB
	cmp r1, r2

	bleq .print_thumb


	mov r1, #0x0000000F
	and r1, r0, r1

	ldr r2, =SUPPORT_ARM
	cmp r1, r2

	bleq .print_ARM
	
.read_cache_size:

	mov r0, #0x0
	mcr p15, 2, r0, c0, c0, 0 	
	
	mrc p15, 1, r0, c0, c0, 0	
	ldr r1, =L1_D
	cmp r0, r1

	bleq .print_L1_D

	mov r0, #0x1
	mcr p15, 2, r0, c0, c0, 0 	
	
	mrc p15, 1, r0, c0, c0, 0	
	ldr r1, =L1_I
	cmp r0, r1

	bleq .print_L1_I

	mov r0, #0x2
	mcr p15, 2, r0, c0, c0, 0 	
	
	mrc p15, 1, r0, c0, c0, 0	
	ldr r1, =L2_D
	cmp r0, r1

	bleq .print_L2_D


	b .fim	
	

/********************************************************
Imprime r0
********************************************************/
.uart_putc:

	stmfd sp!, {r0-r2,lr}
	ldr r1, =UART0_BASE

.wait_tx_fifo_empty:

	ldr r2, [r1, #0x14]
	and r2, r2, #(1<<5)
	cmp r2, #0
	beq .wait_tx_fifo_empty

	strb r0, [r1]
	ldmfd sp!, {r0-r2,pc}

.disable_wdt:
 
   	stmfd sp!,{r0-r1,lr}
    	ldr r0, =WDT_BASE
    
    	ldr r1, =0xAAAA
    	str r1, [r0, #0x48]
    	bl .poll_wdt_write

    	ldr r1, =0x5555
    	str r1, [r0, #0x48]
    	bl .poll_wdt_write

    	ldmfd sp!,{r0-r1,pc}

.poll_wdt_write:
 
   	ldr r1, [r0, #0x34]
    	and r1, r1, #(1<<4)
    	cmp r1, #0
    	bne .poll_wdt_write
    	bx lr

.fim:

	b .fim

.print_arm:
    	stmfd sp!,{r0-r2,lr}
    	adr r1, implementor
	b .print

.print_part_number:
     	stmfd sp!,{r0-r2,lr}
    	adr r1, variant
	b .print   

.print_thumb:
	stmfd sp!,{r0-r2,lr}
    	adr r1, tumb_support
	b .print

.print_ARM:
	stmfd sp!, {r0-r2,lr}
	adr r1, support_ARM
	b .print

.print_L1_D:
	stmfd sp!, {r0-r2,lr}
	adr r1, cache_l1_d_size
	b .print

.print_L1_I:
	stmfd sp!, {r0-r2,lr}
	adr r1, cache_l1_i_size
	b .print

.print_L2_D:
	stmfd sp!, {r0-r2,lr}
	adr r1, cache_l2_d_size
	b .print

.print:
    ldrb r0,[r1],#1
    and r0, r0, #0xff
    cmp r0, #0
    beq .end_print
    bl .uart_putc
    b .print
    
.end_print:
    ldmfd sp!,{r0-r2,pc}

implementor: 	.asciz "ARM "
variant: 	.asciz "Cortex-A8 "
tumb_support:	.asciz "\n\rSupport to Tumb2 "
support_ARM:	.asciz "\n\rSupport to ARM "
cache_l1_d_size:.asciz "\n\rCache L1 D: 32KB"
cache_l1_i_size:.asciz " - Cache L1 I: 32KB "
cache_l2_d_size:.asciz "\n\rCache L2: 256KB"
