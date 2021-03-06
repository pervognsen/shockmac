#
# Copyright (C) 2015-2018 Night Dive Studios, LLC.
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
#
#	File:		FloorLoop.s
#
#	Contains:	PowerPC assembly routine to handle lit/clut floor mappers.
#
#	Written by:	Mark Adams
#
# 	PPCAsm FloorLoop.s -o FloorLoop.s.o
#

	; global variables
	import grd_canvas
	
	; external functions
	import .fix_div_asm
	import .fix_mul_asm
	import .fix_mul_asm_safe
	
	toc
		tc grd_canvas[TC], grd_canvas

	csect
	
	
;---------------------------------------------------
; int HandleFloorLitLoop_PPC();  C++ routine
;---------------------------------------------------
		EXPORT	.HandleFloorLoop_PPC
;		EXPORT	.HandleFloorLoop_PPC__FP18grs_tmap_loop_infolllllllUcUlPUcPUc
	
	.HandleFloorLoop_PPC:
;	.HandleFloorLoop_PPC__FP18grs_tmap_loop_infolllllllUcUlPUcPUc:
		mflr     r0
		stmw     r13,-76(SP)
		stw      r0,8(SP)
		stwu     SP,-128(SP)
		mr       r18,r3
		mr       r29,r4
		mr       r30,r5
		mr       r25,r6
		mr       r26,r7
		mr       r16,r8
		mr       r31,r9
		mr       r27,r10
		lbz      r21,187(SP)
		lwz      r22,188(SP)
		lwz      r23,192(SP)
		lwz      r24,196(SP)
		lwz      r17,grd_canvas[TC](RTOC)
		lwz      r13,0(r17)
		lwz      r13,0(r13)		; r13 = grd_bm.bits
		lwz      r14,0(r17)
		lhz      r14,12(r14)	; r14 = gr_row

		lwz      r15,28(r18)	; left.x
		lwz      r12,64(r18)	; right.x
		
OuterLoop:
		addis    r3,r15,1
		subi     r3,r3,1
		clrrwi   r3,r3,16
		addis    r4,r12,1
		subi     r4,r4,1
		clrrwi   r4,r4,16
		sub.     r20,r4,r3
		ble      CheckDMinus
		
		; calc d
		addis    r6,r15,1
		subi     r6,r6,1
		clrrwi   r6,r6,16
		sub      r20,r6,r15
		
		; calc di,du,dv
		lis      r3,256
		mr       r4,r16
		bl       .fix_div_asm
		mr       r28,r3
		
		mr       r3,r27
		mr       r4,r28
		bl       .fix_mul_asm_safe
		addi     r3,r3,255
		srawi    r27,r3,8
		
		srawi    r28,r28,8
		mr       r3,r25
		mr       r4,r28
		bl       .fix_mul_asm_safe
		mr       r25,r3
		
		mr       r3,r26
		mr       r4,r28
		bl       .fix_mul_asm_safe
		mr       r26,r3
		
		
		; calc u,v,i
		mr       r3,r25
		mr       r4,r20
		bl       .fix_mul_asm
		add      r29,r29,r3
		
		mr       r3,r26
		mr       r4,r20
		bl       .fix_mul_asm
		add      r30,r30,r3
		
		mr       r3,r27
		mr       r4,r20
		bl       .fix_mul_asm
		add      r31,r31,r3
		
		; calc x
		addis    r11,r15,1
		addis    r4,r12,1
		subi     r11,r11,1
		subi     r4,r4,1
		srawi    r11,r11,16
		srawi    r4,r4,16
#		extsh    r11,r11
#		extsh    r4,r4
		sub.     r20,r4,r11

		cmpwi	 1,r27,256

		; calc p_dest
		lwz      r9,4(r18)
		mullw    r8,r14,r9
		addis    r10,r15,1

		cmpwi	 2,r27,-256		; moved for scheduling

		subi     r10,r10,1
		srawi    r10,r10,16
#		extsh    r10,r10
		add      r8,r8,r10
		add      r19,r13,r8


		; copy bytes
		ble-     LoopSkip

		bgt+	 1,Skip
		blt+	 2,Skip
		addi	 r31,r31,256
Skip:

		mtctr	 r20
		addi	 r19,r19,-1
CopyLoop:
		rlwinm   r5,r31,24,16,23
		srawi    r6,r29,16
		srawi    r7,r30,16
		clrlwi   r8,r21,24
		slw      r7,r7,r8
		add      r6,r6,r7
		and      r6,r6,r22
		lbzx     r6,r23,r6
		add      r29,r29,r25
		add      r6,r6,r24
		add      r30,r30,r26
		lbzx     r5,r5,r6
		add      r31,r31,r27
		stbu     r5,1(r19)
		bdnz	 CopyLoop	

LoopSkip:
		lwz      r10,100(r18)
		lwz      r11,24(r18)
		add      r11,r11,r10
		stw      r11,24(r18)		; tli->w+=tli->dw
		
		; calc new u,v,i, du,dv,di
		lis      r3,1
		lwz      r4,24(r18)
		bl       .fix_div_asm
		mr       r28,r3
		lwz      r5,52(r18)
		lwz      r4,36(r18)
		add      r4,r4,r5
		stw      r4,36(r18)
		mr       r3,r4
		mr       r4,r28
		bl       .fix_mul_asm_safe
		mr       r29,r3
		lwz      r5,88(r18)
		lwz      r6,72(r18)
		add      r6,r6,r5
		stw      r6,72(r18)
		lwz      r3,72(r18)
		mr       r4,r28
		bl       .fix_mul_asm_safe
		sub      r25,r3,r29
		lwz      r7,56(r18)
		lwz      r8,40(r18)
		add      r8,r8,r7
		stw      r8,40(r18)
		mr       r3,r8
		mr       r4,r28
		bl       .fix_mul_asm_safe
		mr       r30,r3
		lwz      r9,92(r18)
		lwz      r10,76(r18)
		add      r10,r10,r9
		stw      r10,76(r18)
		lwz      r3,76(r18)
		mr       r4,r28
		bl       .fix_mul_asm_safe
		sub      r26,r3,r30
		lwz      r11,60(r18)
		lwz      r4,44(r18)
		add      r4,r4,r11
		stw      r4,44(r18)
		mr       r3,r4
		mr       r4,r28
		bl       .fix_mul_asm_safe
		mr       r31,r3
		lwz      r3,96(r18)
		lwz      r4,80(r18)
		add      r4,r4,r3
		stw      r4,80(r18)
		lwz      r3,80(r18)
		mr       r4,r28
		bl       .fix_mul_asm_safe
		sub      r27,r3,r31

		cmpwi	 r27,256
		bgt+	 Skip2
		cmpwi	 r27,-256
		blt+	 Skip2
		addi	 r31,r31,256
Skip2:

		
		; update left.x & right.x
		lwz      r5,48(r18)
		add      r15,r15,r5
		lwz      r7,84(r18)
		add      r12,r12,r7
		
		sub      r16,r12,r15	; calc new dx
		
		lwz      r11,4(r18)
		addi     r11,r11,1
		stw      r11,4(r18)		; tli->y++

		lwz      r3,0(r18)
		subi     r3,r3,1
		stw      r3,0(r18)		; tli->n--

		cmpwi    r3,0
		bgt+     OuterLoop

		li       r3,0

		stw      r15,28(r18)	; left.x
		stw      r12,64(r18)	; right.x
Done:
		lwz      r0,136(SP)
		addi     SP,SP,128
		mtlr     r0
		lmw      r13,-76(SP)
		blr

CheckDMinus:
		cmpwi    r20,0
		bge      LoopSkip
		li       r3,1
		b        Done


;---------------------------------------------------
; int HandleFloorClutLoop_PPC();  C++ routine
;---------------------------------------------------
		EXPORT	.HandleFloorClutLoop_PPC
;		EXPORT	.HandleFloorClutLoop_PPC__FP18grs_tmap_loop_infolllllUcUlPUcPUc
	
	.HandleFloorClutLoop_PPC:
;	.HandleFloorClutLoop_PPC__FP18grs_tmap_loop_infolllllUcUlPUcPUc:
		mflr     r0
		stmw     r18,-56(SP)
		stw      r0,8(SP)
		stwu     SP,-112(SP)
		mr       r31,r3
		mr       r28,r4
		mr       r29,r5
		mr       r26,r6
		mr       r27,r7
		mr       r18,r8
		mr       r20,r9
		mr       r21,r10
		lwz      r22,168(SP)
		lwz      r23,172(SP)
		lwz      r19,grd_canvas[TC](RTOC)
		lwz      r16,28(r31)
		lwz      r17,64(r31)
	
C_OuterLoop:
		addis    r3,r16,1
		addis    r4,r17,1
		subi     r3,r3,1
		subi     r4,r4,1
		clrrwi   r3,r3,16
		clrrwi   r4,r4,16
		sub.     r30,r4,r3
		ble      C_CheckDMinus
		
		addis    r6,r16,1
		subi     r6,r6,1
		clrrwi   r6,r6,16
		sub      r30,r6,r16
		lis      r3,1
		mr       r4,r18
		bl       .fix_div_asm
		mr       r24,r3
		
		mr       r3,r26
		mr       r4,r24
		bl       .fix_mul_asm_safe
		mr       r26,r3
		
		mr       r3,r27
		mr       r4,r24
		bl       .fix_mul_asm_safe
		mr       r27,r3
		
		mr       r3,r26
		mr       r4,r30
		bl       .fix_mul_asm
		add      r28,r28,r3
		
		mr       r3,r27
		mr       r4,r30
		bl       .fix_mul_asm
		add      r29,r29,r3
		
		addis    r7,r16,1
		subi     r7,r7,1
		srawi    r7,r7,16
#		extsh    r7,r7
		addis    r8,r17,1
		subi     r8,r8,1
		srawi    r8,r8,16
#		extsh    r8,r8
		sub      r30,r8,r7
		
		lwz      r9,0(r19)
		lwz      r10,0(r19)
		lwz      r9,0(r9)
		lhz      r10,12(r10)
		lwz      r11,4(r31)
		mullw    r10,r10,r11
		cmpwi	 r30,0
		addis    r12,r16,1
		subi     r12,r12,1
		srawi    r12,r12,16
#		extsh    r12,r12
		add      r10,r10,r12
		add      r25,r9,r10
		addi     r25,r25,-1
	
		beq-	 C_LoopSkip
		mtctr	 r30
		
C_InnerLoop:		
		srawi    r3,r28,16
		srawi    r4,r29,16
		clrlwi   r5,r20,24
		slw      r4,r4,r5
		add      r3,r3,r4
		and      r3,r3,r21
		add      r28,r28,r26
		lbzx     r3,r22,r3
		add      r29,r29,r27
		lbzx     r3,r23,r3
		stb      r3,0(r25)
		bdnz      C_InnerLoop
		
C_LoopSkip:
		lwz      r7,100(r31)
		lwz      r4,24(r31)
		add      r4,r4,r7
		lis      r3,1
		stw      r4,24(r31)
		bl       .fix_div_asm
		mr       r24,r3
		
		lwz      r9,52(r31)
		lwz      r3,36(r31)
		add      r3,r3,r9
		mr       r4,r24
		stw      r3,36(r31)
		bl       .fix_mul_asm_safe
		mr       r28,r3
		
		lwz      r11,88(r31)
		lwz      r3,72(r31)
		add      r3,r3,r11
		mr       r4,r24
		stw      r3,72(r31)
		bl       .fix_mul_asm_safe
		sub      r26,r3,r28
		
		lwz      r4,56(r31)
		lwz      r3,40(r31)
		add      r3,r3,r4
		mr       r4,r24
		stw      r3,40(r31)
		bl       .fix_mul_asm_safe
		mr       r29,r3
		
		lwz      r6,92(r31)
		lwz      r3,76(r31)
		add      r3,r3,r6
		mr       r4,r24
		stw      r3,76(r31)
		bl       .fix_mul_asm_safe
		sub      r27,r3,r29
		
		lwz      r8,48(r31)
		add      r16,r16,r8
		lwz      r10,84(r31)
		add      r17,r17,r10
		sub      r18,r17,r16
		lwz      r5,0(r31)
		subi     r5,r5,1
		stw      r5,0(r31)
		cmpwi    r5,0
		lwz      r4,4(r31)
		addi     r4,r4,1
		stw      r4,4(r31)
		bgt+     C_OuterLoop
		
		li       r3,0
		stw      r16,28(r31)
		stw      r17,64(r31)
		
C_Done:
		lwz      r0,120(SP)
		addi     SP,SP,112
		mtlr     r0
		lmw      r18,-56(SP)
		blr

C_CheckDMinus:
		cmpwi    r30,0
		bge+     C_LoopSkip
		li       r3,1
		b        C_Done
