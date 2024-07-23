	INCLUDE		STM32F4xx.s
	
	AREA		SRAM1,		NOINIT,			READWRITE
	SPACE		0x400
Stack_Top
	
	AREA		RESET,		DATA,		READONLY
	DCD			Stack_Top				;[0x000-0x003]
	DCD			Start_Init				;[0x004-0x007]
	SPACE		0xB8 - 0x08				;[0x008-0x117]
	DCD			TIM4_IRQHandler		;[0x118-0x11B]
	
	AREA		PROGRAM,	CODE,		READONLY
	ENTRY
	
Start_Init
;TIM6 CLK Enable
	LDR			R0,			=RCC_BASE
	LDR			R1,			[R0,		#RCC_APB1ENR]
	ORR			R1,			R1,			#RCC_APB1ENR_TIM4EN
	STR			R1,			[R0,		#RCC_APB1ENR]
;GPIOD CLK Enable
	LDR			R1,			[R0,		#RCC_AHB1ENR]
	ORR			R1,			R1,			#RCC_AHB1ENR_GPIODEN
	STR			R1,			[R0,		#RCC_AHB1ENR]
	
	
	
;PD14 = output
	LDR			R0,			=GPIOD_BASE
	LDR			R1,			[R0,		#GPIO_MODER]
	AND			R1,			R1,			#~GPIO_MODER_MODER14
	ORR			R1,			R1,			#GPIO_MODER_MODER14_1
	STR			R1,			[R0,		#GPIO_MODER]
	LDR			R1,			[R0,		#GPIO_AFRH]
	BFC			R1,			#GPIO_AFRH_AFSEL14_Pos,		#4
	ORR			R1,			R1,			#(2 << GPIO_AFRH_AFSEL14_Pos)
	STR			R1,			[R0,		#GPIO_AFRH]

;TIM4 CH3 = PWM
	LDR			R0,			=TIM4_BASE
	LDR			R1,			[R0,		#TIM_CCMR2]
	ORR			R1,			R1,			#TIM_CCMR2_OC3PE
	AND			R1,			R1,			#~TIM_CCMR2_OC3M
	ORR			R1,			R1,			#(6 << TIM_CCMR2_OC3M_Pos)
	STR			R1,			[R0,		#TIM_CCMR2]
	LDR			R1,			[R0,		#TIM_CCER]
	ORR			R1,			R1,			#TIM_CCER_CC3E
	STR			R1,			[R0,		#TIM_CCER]

;16 MHz = 16 000 000 = 1 sec
; 8 MHz =  8 000 000 = 0.5 sec
;PSC: 8 MHz / psc = [0 .. 65 535]
;! PSC = 1000 => ARR = 8 000
	LDR			R0,			=TIM4_BASE
	LDR			R1,			=10 - 1
	STR			R1,			[R0,		#TIM_PSC]
	
	LDR			R1,			=16000
	STR			R1,			[R0,		#TIM_ARR]
	
	LDR			R1,			=0
	STR			R1,			[R0,		#TIM_CNT]
	
	LDR			R4,			=0
	STR			R4,			[R0,		#TIM_CCR3]
	
;TIM4 IRQ Enable
	LDR			R1,			[R0,		#TIM_DIER]
	ORR			R1,			R1,			#TIM_DIER_UIE
	STR			R1,			[R0,		#TIM_DIER]
;NVIC TIM4 IRQ Enable
	LDR			R2,			=NVIC_BASE
	LDR			R1,			[R2,		#NVIC_ISER0]
	ORR			R1,			R1,			#(1 << (TIM4_IRQn))
	STR			R1,			[R2,		#NVIC_ISER0]
;TIM4 Enable
	LDR			R1,			[R0,		#TIM_CR1]
	ORR			R1,			R1,			#TIM_CR1_CEN
	STR			R1,			[R0,		#TIM_CR1]
	
	LDR			R6,			=5000
	LDR			R7,			=0
	LDR			R8,			=20
	LDR			R9,			=-20
	LDR			R10,		=0

;	\|/
Main_Loop
	B			Main_Loop

TIM4_IRQHandler
	LDR			R0,			=TIM4_BASE				; !!!
	LDR			R1,			[R0,		#TIM_SR]
	AND			R1,			R1,			#~TIM_SR_UIF
	STR			R1,			[R0,		#TIM_SR]

;Code
	
	CMP			R4,			R6
	LDRHS		R10,		=1
	CMP			R4,			R7
	LDREQ		R10,		=0
	
	CMP			R10,		R7
	ADDEQ		R4,			R4,			R8
	ADDNE		R4,			R4,			R9
	
	
	;ADD			R4,			R4,			R2
	STR			R4,			[R0,		#TIM_CCR3]
	
	BX			LR

	END
		
		
		
		
		