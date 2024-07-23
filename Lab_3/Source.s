	INCLUDE 		STM32F4xx.s

LED_GR				EQU				GPIO_ODR_OD12
LED_OR				EQU				GPIO_ODR_OD13
LED_RED				EQU				GPIO_ODR_OD14
LED_BLUE			EQU				GPIO_ODR_OD15

	AREA			SRAM1,			NOINIT,			READWRITE
	SPACE			0x500
Stack_Top

	AREA			RESET,			DATA,			READONLY
	DCD				Stack_Top
	DCD				Start_Init
	SPACE			0x58-0x08
	DCD				EXTI0_IRQHandler
	
	AREA			PROGRAM,		CODE,			READONLY
	ENTRY

Start_Init
;RCC
	LDR			R0, 			=RCC_BASE
	LDR			R1,		 		[R0, 		#RCC_AHB1ENR]
	ORR			R1,				R1,			#RCC_AHB1ENR_GPIODEN ;???
	STR 		R1,		 		[R0, 		#RCC_AHB1ENR]
	
;EXTI0
	LDR			R0, 			=EXTI_BASE
	
	LDR			R1,		 		[R0, 		#EXTI_RTSR]
	ORR			R1,				R1,			#EXTI_RTSR_TR0
	STR 		R1,		 		[R0, 		#EXTI_RTSR]
	
	LDR			R1,		 		[R0, 		#EXTI_IMR]
	ORR			R1,				R1,			#EXTI_IMR_MR0
	STR 		R1,		 		[R0, 		#EXTI_IMR] 

;NVIC
	LDR			R0, 			=NVIC_BASE
	LDR			R1,		 		[R0, 		#NVIC_ISER0]
	ORR			R1,				R1,			#(1 << EXTI0_IRQn)
	STR 		R1,		 		[R0, 		#NVIC_ISER0]

;GPIOD ???
	LDR			R0, 			=GPIOD_BASE
	LDR			R1, 			[R0, 		#GPIO_MODER] 
	ORR			R1, 			R1,			#(GPIO_MODER_MODER15_0 + GPIO_MODER_MODER14_0)
	ORR			R1, 			R1,			#(GPIO_MODER_MODER13_0 + GPIO_MODER_MODER12_0)
	STR 		R1,		 		[R0, 		#GPIO_MODER] 

;	ORR			R1,				R1,			#GPIO_ODR_OD14


	LDR			R10,			=0

Main_Loop
	B			Main_Loop

EXTI0_IRQHandler
	LDR			R0, 			=EXTI_BASE
	LDR			R1,		 		[R0, 		#EXTI_PR]
	AND			R2,				R1,			#EXTI_PR_PR0
	CMP			R2,				#0
	BXEQ		LR	
	STR 		R2,		 		[R0, 		#EXTI_PR] 
	
	ADD			R10,			R10,			#1
	CMP			R10,			#8
	LDREQ		R10,			=0
	
;switch [0-7]
	LDR			R0, 			=GPIOD_BASE
	LDR			R1, 			[R0, 		#GPIO_ODR]
	BFC			R1,				#GPIO_ODR_OD12_Pos,		#4
		
	CMP			R10,			#1
	ORREQ		R1,				R1,			#LED_BLUE
	
	CMP			R10,			#2
	ORREQ		R1,				R1,			#(LED_BLUE + LED_GR)
	
	CMP			R10,			#3
	ORREQ		R1,				R1,			#(LED_BLUE + LED_GR + LED_OR)
	
	CMP			R10,			#4
	ORREQ		R1,				R1,			#(LED_BLUE + LED_GR + LED_OR + LED_RED)
	
	CMP			R10,			#5
	ORREQ		R1,				R1,			#(LED_RED + LED_GR + LED_OR)
	
	CMP			R10,			#6
	ORREQ		R1,				R1,			#(LED_RED + LED_OR)
	
	CMP			R10,			#7
	ORREQ		R1,				R1,			#LED_RED
	
	STR 		R1,		 		[R0, 		#GPIO_ODR]
	
	BX			LR
	
	END