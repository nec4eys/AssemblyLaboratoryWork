n					EQU				4
	
	AREA			SRAM1,			NOINIT,			READWRITE
	SPACE			0x400
Stack_Top

	AREA			RESET,			DATA,			READONLY
	DCD				Stack_Top
	DCD				Start_Init
	
	AREA			PROGRAM,		CODE,			READONLY
	ENTRY

Start_Init
;	R1 = CONST
	LDR 			R1,				=n
	BL				Test_N

Main_Loop
	B				Main_Loop
	
	
Test_N
;	!R1 = N = 5
;	R0 = R1 ^2
	MUL				R0,				R1,				R1
;	R0 = R1 ^3
	MUL				R0,				R0,				R1
;	R0 = 2 * n^3
	LDR				R2,				=2
	MUL				R0,				R0,				R2
;	R2 = 28
	LDR				R2,				=28
;	R2 = 28 * n
	MUL				R2,				R2,				R1
;	R0 = 2 * n^3 + 28 * n
	ADD				R0,				R0,				R2
;	R2 = 271
	LDR				R2,				=271
;	R0 = 2*n^3 + 28*n - 271
	SUB				R0,				R0,				R2
;	R4 = n / 2
	LDR				R2,				=2
	SDIV			R4,				R1,				R2
	LDR				R3,				=1
	
	PUSH 		{LR}
	BL for_label
	
	LDR				R2,				=75
	SDIV			R2,				R2,				R1
;	R3 = !(n/2) - (75/n)
	SUB				R3,				R3,				R2
;	R4 = (((2*(n^3)) + (28*n) - 271) / (!(n/2) - (75/n))
	SDIV			R4,				R0,				R3
;	R3 = n/2
	LDR				R2,				=2
	SDIV			R3,				R1,				R2
	
	BL for_label_1
	POP			{LR}
	BX			LR
	
;	\|/
;	FOR (i=1; i<=R4; i++)
;	R2 -> i
;	\|/
for_label
	MOV 			R2, 			#1
;	\|/
for_cycle
;	i<=R4;
	CMP 			R2, 			R4
	BHI 			for_end
	MUL				R3,				R3,				R2
	ADD 			R2, 			R2, 			#1
	B for_cycle	

for_end
	MOV 			R2, 			#0
	BX				LR
;	\|/
;	R4 = 75 / n
;	R0 = ("R0")^n/2
;	\|/
for_label_1
;	R1 << R0 
;	R0 = 1
;	FOR (i=1; i<=R3; i++)
;		{
;		R0 = R0*n
;		}
	LDR				R0,				=1
	MOV 			R2, 			#1
;	\|/
for_cycle_1
;	i<=R3;
	CMP 			R2, 			R3
	BHI 			for_end_1
;	R0 = R0*n
	MUL				R0,				R0,				R4
; 	i++
	ADD 			R2, 			R2, 			#1
	
	B 				for_cycle_1
for_end_1
	MOV 			R1, 			#0
	MOV 			R2, 			#0
	MOV 			R3, 			#0
	MOV 			R4, 			#0
;	\|/
	BX				LR
	
	END