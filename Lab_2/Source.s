	INCLUDE				STM32F4xx.s

	AREA			SRAM1,			NOINIT,			READWRITE
	SPACE			0x400
Stack_Top

	AREA			RESET,			DATA,			READONLY
	DCD				Stack_Top
	DCD				Start_Init
	SPACE			0x17C					
	DCD				FPU_IRQHandler			
	
	AREA			PROGRAM,		CODE,			READONLY
	ENTRY

Start_Init
;Enabling FPU
	LDR			R0,			=FPU_BASE
	LDR			R1,			[R0,		#FPU_CPACR]
	ORR			R1,			R1,			#(FPU_CPACR_CP10 + FPU_CPACR_CP11)
	STR			R1,			[R0,		#FPU_CPACR]
	DSB
	ISB
	LDR			R0,			=NVIC_BASE
	LDR			R1,			[R0,		#NVIC_ISER2]
	ORR			R1,			R1,			#(1 << (FPU_IRQn - 64))
	STR			R1,			[R0,		#NVIC_ISER2]
;	\|/
	BL				Lab_2
;	\|/
Main_Loop
	B				Main_Loop
	
Lab_2
;S0 <- 0
	VLDR.F32		S0,				=0.0
	VLDR.F32		S1,				=6.0
	VLDR.F32		S2,				=5.0
	VLDR.F32		S3,				=2.0
	VLDR.F32		S4,				=8.37
	VLDR.F32		S10,			=1.0

;for(int s5 = 1; s5<6; s5++)
;	s6 = 5^S5
;	S7 = s6^0.5
;	s8 = 8.37 * s1
;	s9 = s2/s8
;	s0 = s0 + s9
for_label
	VMOV.F32 			S5, 			#1
;	\|/
for_cycle
	VCMP.F32 			S5, 			S1
	VMRS				APSR_nzcv, 		FPSCR
	BEQ 				for_end
;	\|/
;s6 <- 1
	VMOV.F32		S6,				S10
;	FOR (i=1; i<=R3; i++)
;		{
;		R0 = R0*n
;		}
for_label_1
	VMOV.F32 			S11, 			S10
;	\|/
for_cycle_1
	VCMP.F32 			S11, 			S5
	VMRS				APSR_nzcv, 		FPSCR
	BHI 				for_end_1
	VMUL.F32			S6,				S6,				S2
	VADD.F32 			S11, 			S11, 			S10
	B for_cycle_1	
for_end_1
;	\|/
	VSQRT.F32			S7,				S6
	VMUL.F32			S8,				S4,				S5
	VDIV.F32			S9,				S7,				S8
	VADD.F32			S0,				S0,				S9		
;	\|/
	VADD.F32 			S5, 			S5, 			S10
	B for_cycle	

for_end
	BX				LR

FPU_IRQHandler
	BX			LR

	END