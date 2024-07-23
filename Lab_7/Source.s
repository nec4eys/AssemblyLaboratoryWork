	INCLUDE 	STM32F4xx.s
	
	AREA		SRAM1,		NOINIT,		READWRITE
	SPACE		0x400
Stack_Top
	
	AREA		RESET,		DATA,		READONLY
	DCD			Stack_Top			;[0x000-0x003]
	DCD			Start_Init			;[0x004-0x007]	
	SPACE		0xD4				;[0x008-0x0D3];?
	DCD			USART3_IRQHandler	;[0x0DC-0x0E0]
		
	AREA		PROGRAM,	CODE,		READONLY
	ENTRY
	
Start_Init
	LDR			R0,			=RCC_BASE
	LDR			R1,			[R0,		#RCC_APB1ENR]
	ORR			R1,			R1,			#RCC_APB1ENR_USART3EN 
	STR			R1,			[R0,		#RCC_APB1ENR]
	
	LDR			R1,			[R0,		#RCC_AHB1ENR]
	ORR			R1,			R1,			#RCC_AHB1ENR_GPIOBEN
	STR			R1,			[R0,		#RCC_AHB1ENR]
	
	LDR			R0,			=GPIOB_BASE
	;USART conect to moder10 and moder11 p.63/203 
	LDR			R1,			[R0,		#GPIO_MODER]
	BFC			R1,			#GPIO_MODER_MODER10_Pos,		#4
	ORR			R1,			R1,			#(GPIO_MODER_MODER10_1 + GPIO_MODER_MODER11_1);on alternativ function
	STR			R1,			[R0,		#GPIO_MODER]
	
	LDR			R1,			[R0,		#GPIO_OSPEEDR] ; for speed choice
	ORR			R1,			R1,			#(GPIO_OSPEEDR_OSPEED10 + GPIO_OSPEEDR_OSPEED11)
	STR			R1,			[R0,		#GPIO_OSPEEDR]
	
	;p.63/203 ;AFRH - 8-15, AFRL - 0-7
	LDR			R1,			[R0,		#GPIO_AFRH]
	BFC			R1,			#GPIO_AFRH_AFSEL10_Pos,		#8
	ORR			R1,			R1,			#(7 << GPIO_AFRH_AFSEL10_Pos);datasheet(63/203)
	ORR			R1,			R1,			#(7 << GPIO_AFRH_AFSEL11_Pos);<< 7 - AF7
	STR			R1,			[R0,		#GPIO_AFRH]

	;Setting USART
	;USART1 BR = , 2 stop bits, no parity
	;F_APB2 = 50 Mhz
	;BRR = (16 MHz - (115200/2)) / 115200 = 138
	
	
	LDR			R4,			=SRAM1_BASE
	MOV			R1,			#0
	STR			R1,			[R4]
	
	LDR			R0,			=USART3_BASE
	
	LDR			R1,			=138
	STR			R1,			[R0,		#USART_BRR]
	
	;RE- poluchit information, TE - peredacha information
	;RXNE - on prerivanie for RE, TCIE - on prerivanie for TE
	LDR			R1,			[R0,		#USART_CR1]
	ORR			R1,			R1,			#(USART_CR1_RE + USART_CR1_TE); p.1010
	ORR			R1,			R1,			#(USART_CR1_RXNEIE + USART_CR1_TCIE)
	ORR			R1,			R1,			#USART_CR1_UE; << ENABLE;?
	STR			R1,			[R0,		#USART_CR1]
	
	LDR			R2,			=NVIC_BASE
	LDR			R1,			[R2,		#NVIC_ISER1];p.373/1751
	ORR			R1,			R1,			#(1 << (USART3_IRQn - 32))
	STR			R1,			[R2,		#NVIC_ISER1]
	
	;MOV			R4,			#0
	
;	\|/
Main_Loop	
	B 			Main_Loop
	
	
USART3_IRQHandler
	; 
	
	
	;rxne - in byte
	;tc and txe - out byte
	;ore fe pe - error (maybe not use)
	
	
	;LDR			R5,			=SRAM1_BASE

	LDR			R0,			=USART3_BASE
	LDR			R1,			[R0,		#USART_SR]
	
	
	;IN THIS PART WE THINK THAT HAPPENED: IN OR OUT
	AND			R2,			R1,			#USART_SR_TC
	CMP			R2,			#0			;if we end out byte from mk
	BNE			USART3_IRQHandler_TC
	
	AND			R2,			R1,			#USART_SR_RXNE
	CMP			R2,			#0			;if we in byte to mk
	BNE			USART3_IRQHandler_RXNE
	
	
	BX 			LR
	

USART3_IRQHandler_TC
	
	;TC = 0
	AND			R1,			R1,			#~USART_SR_TC
	STR			R1,			[R0,		#USART_SR]
	
	LDRB		R5,			[R4],		#1
	
	CMP			R5,			#0x00
	LDREQ		R4,			=SRAM1_BASE
	BXEQ		LR
	
	STR			R5,			[R0,		#USART_DR]
	
	BX 			LR

USART3_IRQHandler_RXNE
	LDR			R2,			[R0,		#USART_DR];berem to chto peredalu c pk
	;STR			R2,			[R0,		#USART_DR]

	STRB		R2,			[R4],		#1;LOAD TO SRAM
	AND			R5,			R4,			#0xFF
	
	CMP			R5,			#10; IF R5 == 10: GO TO OUT DATA FROM SRAM
	BXLO		LR
	;
	
	;BX			LR
;	\|/
Start_Send;START TO OUT FROM MK
	MOV			R5,			#0
	STR			R5,			[R4]
	LDR			R4,			=SRAM1_BASE	
	LDRB		R5,			[R4],		#1
	STR			R5,			[R0,		#USART_DR]
	
	BX			LR
	
	END