	INCLUDE		STM32F4xx.s
		
LED_BLUE			EQU				GPIO_ODR_OD15
	
	AREA		SRAM1,		NOINIT,			READWRITE
	SPACE		0x400
Stack_Top
	
	AREA		RESET,		DATA,		READONLY
	DCD			Stack_Top				;[0x000-0x003]
	DCD			Start_Init				;[0x004-0x007]
	SPACE		0xC4
	DCD			SPI1_IRQHandler
	SPACE		0xB8 - 0x08				;[0x008-0x117]
	DCD			TIM7_IRQHandler		;[0x118-0x11B]
	
	AREA		PROGRAM,	CODE,		READONLY
	ENTRY

Start_Init
	LDR			R0,			=RCC_BASE
	LDR			R1,			[R0,		#RCC_AHB1ENR]
	ORR			R1,			R1,			#(RCC_AHB1ENR_GPIOAEN + RCC_AHB1ENR_GPIOEEN)
	ORR			R1,			R1,			#RCC_APB1ENR_TIM7EN
	STR			R1,			[R0,		#RCC_AHB1ENR]
	
	LDR			R1,			[R0,		#RCC_APB2ENR]
	ORR			R1,			R1,			#RCC_APB2ENR_SPI1EN
	STR			R1,			[R0,		#RCC_APB2ENR]
	
	LDR			R0,			=GPIOA_BASE
	LDR			R1,			[R0,		#GPIO_MODER]
	BFC			R1,			#GPIO_MODER_MODER5_Pos,		#6
	ORR			R1,			R1,			#(GPIO_MODER_MODER5_1 + GPIO_MODER_MODER6_1 + GPIO_MODER_MODER7_1)
	STR			R1,			[R0,		#GPIO_MODER]
	
	LDR			R1,			[R0,		#GPIO_AFRL]
	BFC			R1,			#GPIO_AFRL_AFSEL5_Pos,		#12
	ORR			R1,			R1,			#(5 << GPIO_AFRL_AFSEL5_Pos)
	ORR			R1,			R1,			#(5 << GPIO_AFRL_AFSEL6_Pos)
	ORR			R1,			R1,			#(5 << GPIO_AFRL_AFSEL7_Pos)
	STR			R1,			[R0,		#GPIO_AFRL]
	
	LDR			R0,			=GPIOE_BASE
	LDR			R1,			[R0,		#GPIO_MODER]
	AND			R1,			R1,			#~GPIO_MODER_MODER3
	ORR			R1,			R1,			#GPIO_MODER_MODER3_0
	STR			R1,			[R0,		#GPIO_MODER]
	
	LDR			R1,			[R0,		#GPIO_ODR]
	ORR			R1,			R1,			#GPIO_ODR_OD3
	STR			R1,			[R0,		#GPIO_ODR]
	
	LDR			R0,			=SPI1_BASE
	LDR			R1,			[R0,		#SPI_CR2]
	ORR			R1,			R1,			#(SPI_CR2_RXNEIE + SPI_CR2_ERRIE)
	STR			R1,			[R0,		#SPI_CR2]
	
	LDR			R1,			[R0,		#SPI_CR1]
	AND			R1,			R1,			#~SPI_CR1_BR
	ORR			R1,			R1,			#(SPI_CR1_DFF + SPI_CR1_SSM + SPI_CR1_SSI)
	ORR			R1,			R1,			#SPI_CR1_MSTR
	STR			R1,			[R0,		#SPI_CR1]
	
	LDR			R2,			=NVIC_BASE
	LDR			R1,			[R2,		#NVIC_ISER1]
	ORR			R1,			R1,			#(1 << (SPI1_IRQn - 32))
	STR			R1,			[R2,		#NVIC_ISER1]
	
	LDR			R1,			[R0,		#SPI_CR1]
	ORR			R1,			R1,			#SPI_CR1_SPE
	STR			R1,			[R0,		#SPI_CR1]
	
	LDR			R0,			=GPIOE_BASE
	LDR			R1,			[R0,		#GPIO_ODR]
	AND			R1,			R1,			#~GPIO_ODR_OD3
	STR			R1,			[R0,		#GPIO_ODR]
	
	LDR			R1,			=0x8F00
	STR			R1,		[R0,		#SPI_DR]	
	
;tim7
	LDR			R0,			=TIM7_BASE
	
;TIM7 IRQ Enable
	LDR			R1,			[R0,		#TIM_DIER]
	ORR			R1,			R1,			#TIM_DIER_UIE
	STR			R1,			[R0,		#TIM_DIER]
	
	;PSC = 1000 - 1
	;CNT = 0
	;ARR = 16000
	LDR			R0,			=TIM7_BASE
	LDR			R1,			=1000 - 1
	STR			R1,			[R0,		#TIM_PSC]
	
	LDR			R1,			=16000
	STR			R1,			[R0,		#TIM_ARR]
	
	LDR			R1,			=0
	STR			R1,			[R0,		#TIM_CNT]

;NVIC TIM7 IRQ Enable
	LDR			R2,			=NVIC_BASE
	LDR			R1,			[R2,		#NVIC_ISER1]
	ORR			R1,			R1,			#(1 << (TIM7_IRQn - 32))
	STR			R1,			[R2,		#NVIC_ISER1]
	
	
	
	
	
;TIM7 Enable
	LDR			R1,			[R0,		#TIM_CR1]
	ORR			R1,			R1,			#TIM_CR1_CEN
	STR			R1,			[R0,		#TIM_CR1]
;	\|/
Main_Loop
	B			Main_Loop
	
SPI1_IRQHandler
	LDR			R0,			=GPIOE_BASE
	LDR			R1,			[R0,		#GPIO_ODR]
	ORR			R1,			R1,			#GPIO_ODR_OD3
	STR			R1,			[R0,		#GPIO_ODR]

	LDR			R0,			=SPI1_BASE
	LDR			R1,			[R0,		#SPI_DR]
	
	BX			LR
	
TIM7_IRQHandler
	LDR			R0,			=TIM7_BASE				; !!!
	LDR			R1,			[R0,		#TIM_SR]
	AND			R1,			R1,			#~TIM_SR_UIF
	STR			R1,			[R0,		#TIM_SR]
	
	
	
	BX			LR

	END