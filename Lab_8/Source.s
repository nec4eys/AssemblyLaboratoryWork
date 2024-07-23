	INCLUDE 	STM32F4xx.s
	
	AREA		SRAM1,		NOINIT,		READWRITE
	SPACE		0x400
Stack_Top
	
	AREA		RESET,		DATA,		READONLY
	DCD			Stack_Top			;[0x000-0x003]
	DCD			Start_Init			;[0x004-0x007]	
	SPACE		0x80				;[0x008-0x087]
	DCD			ADC_IRQHandler		;[0x088-0x08B]
	SPACE		0x48				;[0x08C-0x0D3]
	DCD			USART3_IRQHandler	;[0x0D4-0x0D7]
		
	AREA		PROGRAM,	CODE,		READONLY
	ENTRY
	
Start_Init
	LDR			R0,			=RCC_BASE
	;USART3
	LDR			R1,			[R0,		#RCC_APB1ENR]
	ORR			R1,			R1,			#RCC_APB1ENR_USART3EN 
	STR			R1,			[R0,		#RCC_APB1ENR]
	;GPIOA
	LDR			R1,			[R0,		#RCC_AHB1ENR]
	ORR			R1,			R1,			#RCC_AHB1ENR_GPIOAEN
	STR			R1,			[R0,		#RCC_AHB1ENR]
	;GPIOB
	LDR			R1,			[R0,		#RCC_AHB1ENR]
	ORR			R1,			R1,			#RCC_AHB1ENR_GPIOBEN
	STR			R1,			[R0,		#RCC_AHB1ENR]
	;ADC1
	LDR			R1,			[R0,		#RCC_APB2ENR]
	ORR			R1,			R1,			#RCC_APB2ENR_ADC1EN
	STR			R1,			[R0,		#RCC_APB2ENR]
;	
;;
;SETTING ADC1
	LDR			R0,			=ADC1_BASE
	
	LDR			R1,			[R0,		#ADC_CR1]
	ORR			R1,			R1,			#ADC_CR1_EOCIE
	STR			R1,			[R0,		#ADC_CR1]
	
	LDR			R1,			[R0,		#ADC_SQR1]
	AND			R1,			R1,			#~ADC_SQR1_L
	STR			R1,			[R0,		#ADC_SQR1]
	;!
	LDR			R1,			[R0,		#ADC_SQR3]
	AND			R1,			R1,			#~ADC_SQR3_SQ1
	ORR			R1,			R1,			#(1 << ADC_SQR3_SQ1_Pos)
	STR			R1,			[R0,		#ADC_SQR3]	
	;ON/OFF ADC1
	LDR			R1,			[R0,		#ADC_CR2]
	ORR			R1,			R1,			#ADC_CR2_ADON
	STR			R1,			[R0,		#ADC_CR2]
;;
;
	LDR			R2,			=NVIC_BASE
	LDR			R1,			[R2,		#NVIC_ISER0];p.373/1751
	ORR			R1,			R1,			#(1 << (ADC_IRQn))
	STR			R1,			[R2,		#NVIC_ISER0]
	
	;LDR			R1,			[R0,		#ADC_CR2]
	;ORR			R1,			R1,			#ADC_CR2_SWSTART
	;STR			R1,			[R0,		#ADC_CR2]
;
;;
	;SETTING GPIOB
	LDR			R0,			=GPIOB_BASE
	;USART conect to moder6 and moder7 p.63/203 
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
	;BRR = (16 MHz - (115200/2)) / 115200 = 138
	LDR			R0,			=USART3_BASE
	LDR			R1,			=138
	STR			R1,			[R0,		#USART_BRR]
	;RE- poluchit information, TE - peredacha information
	;RXNE - on prerivanie for RE, TCIE - on prerivanie for TE
	LDR			R1,			[R0,		#USART_CR1]
	ORR			R1,			R1,			#(USART_CR1_RE + USART_CR1_TE); p.1010
	ORR			R1,			R1,			#(USART_CR1_RXNEIE + USART_CR1_TCIE)
	ORR			R1,			R1,			#USART_CR1_UE; << ENABLE
	STR			R1,			[R0,		#USART_CR1]
;;
;
	LDR			R2,			=NVIC_BASE
	LDR			R1,			[R2,		#NVIC_ISER1];p.373/1751
	ORR			R1,			R1,			#(1 << (USART3_IRQn - 32))
	STR			R1,			[R2,		#NVIC_ISER1]
;	\|/
Main_Loop
	B			Main_Loop

;?????
ADC_IRQHandler
	;AFTER CONFERTATION WE HAVE NUMBER (BUT WHERE?)
	;THIS DATA HEED TO TRANSLATE TO VOLTAGE
	;AND OUT THIS TO PC (FOR EXAMPLE: STR			R5,			[R0,		#USART_DR])
	BX 			LR
	
USART3_IRQHandler;,TAKE NUMBER TO CHANAL ADC
	;MAYBE TAKE TC (IF WE OUT DATA, WE DON'T TAKE RXNE
	;rxne - in byte
	;tc and txe - out byte
	;ore fe pe - error (maybe not use)

	LDR			R0,			=USART3_BASE
	LDR			R1,			[R0,		#USART_SR]
	
	;IN THIS PART WE THINK THAT HAPPENED: IN OR OUT
	;AND			R2,			R1,			#USART_SR_TC
	;CMP			R2,			#0			;if we end out byte from mk
	;BNE			USART3_IRQHandler_TC
	
	AND			R2,			R1,			#USART_SR_RXNE
	CMP			R2,			#0			;if we in byte to mk
	BNE			USART3_IRQHandler_RXNE
	
	BX 			LR
	
;USART3_IRQHandler_TC
	
	;TC = 0
	;AND			R1,			R1,			#~USART_SR_TC
	;STR			R1,			[R0,		#USART_SR]
	
	;LDRB		R5,			[R4],		#1
	
	;CMP			R5,			#0x00
	;LDREQ		R4,			=SRAM1_BASE
	;BXEQ		LR
	
	;STR			R5,			[R0,		#USART_DR]
	
	;BX 			LR

USART3_IRQHandler_RXNE
	LDR			R1,			[R0,		#USART_DR];berem to chto peredalu c pk
	;RABOTAEM DALEE C DATA
	;TRANSLETE FROM ASKI SIMVOLS (-30) AND IN THIS NUMBER TO ADC_SQR3_SQ1
	;AFTER THIS WE START ADC ONE TO THE ADC_CR2_SWSTART
	;LDR			R1,			[R0,		#ADC_CR2]
	;ORR			R1,			R1,			#ADC_CR2_SWSTART
	;STR			R1,			[R0,		#ADC_CR2]
	
	BX			LR

	END