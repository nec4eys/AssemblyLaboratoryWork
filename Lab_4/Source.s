	INCLUDE		STM32F4xx.s
		
LED_BLUE			EQU				GPIO_ODR_OD15
	
	AREA		SRAM1,		NOINIT,			READWRITE
	SPACE		0x400
Stack_Top
	
	AREA		RESET,		DATA,		READONLY
	DCD			Stack_Top				;[0x000-0x003]
	DCD			Start_Init				;[0x004-0x007]
	DCD 		NMI_IRQHandler			;[0x008-0x00B] ; Priviazat` obrabotchik prery`vaniia NMI_IRQHandler k vektoru 0x08
	
	AREA		PROGRAM,	CODE,		READONLY
	ENTRY

Timeout_finish
Timeout_PLL_finish
	B			Timeout_finish

Start_Init
;zapusk vnechni ustochnik taktovux cugnalov
;RCC_CR_HSEON = 1
	LDR			R0,			=RCC_BASE
	LDR			R1,			[R0,		#RCC_CR]
	ORR			R1,			R1,			#RCC_CR_HSEON
	STR			R1,			[R0,		#RCC_CR]

	LDR			R2,			=50000
;	\|/
Timeout_start;waiting  Dozhdat`sia vcliucheniia vneshnego istochnika taktovy`kh signalov
	SUB			R2,			R2,			#1
	CMP			R2,			#0
	BEQ			Timeout_finish;yxodut uz timeout'a


;RCC_CR_HSERDY = 1  
	LDR			R1,			[R0,		#RCC_CR]
	AND			R1,			R1,			#RCC_CR_HSERDY
	CMP			R1,			#0
	BEQ			Timeout_start
	
; Nastroit` koe`ffitcienty`
	LDR			R1,			[R0,		#RCC_PLLCFGR] 
;PLL_Out = (HSE / PLLM * PLLN ) / PLLP 
;PLL_Out = (8 MHZ / 4 * 90) / 2 = 90 MHz
; 90 = 5 * my age (18)

	ORR			R1,			R1,			#RCC_PLLCFGR_PLLSRC ;Vy`brat` vneshnii` istochnik  v kachestve osnovnogo dlia PLL
	;clear R1 until 15 bit
	BFC			R1,			#RCC_PLLCFGR_PLLM_Pos,		#15
	ORR			R1,			R1,			#(4 << RCC_PLLCFGR_PLLM_Pos)
	ORR			R1,			R1,			#(90 << RCC_PLLCFGR_PLLN_Pos)
	;PLLP = 00  == 2
	AND			R1,			R1,			#~RCC_PLLCFGR_PLLP 
	STR			R1,			[R0,		#RCC_PLLCFGR]
;	\|/
;PLL ON  Vkluchit PLL
	LDR			R1,			[R0,		#RCC_CR]
	ORR			R1,			R1,			#RCC_CR_PLLON
	STR			R1,			[R0,		#RCC_CR]
	
	LDR			R2,			=50000
;	\|/
PLL_Ready ; Dozhdat`sia vcliucheniia
	SUB			R2,			R2,			#1
	CMP			R2,			#0
	BEQ			Timeout_PLL_finish;yxodut uz timeout'a ;!!!!!!!!!!!!!!!!
	
	LDR			R1,			[R0,		#RCC_CR]
	ORR			R1,			R1,			#RCC_CR_PLLRDY
	STR			R1,			[R0,		#RCC_CR]
	CMP			R1,			#1
	BEQ			PLL_Ready
;	\|/
;memory Nastroit` trebuemoe kolichestvo tciclov zaderzhki dostupa k pamiati
	LDR 		R0,			=FLASH_R_BASE
	
	LDR			R1,			[R0,		#FLASH_ACR]
	ORR			R1,			R1,			#(FLASH_ACR_DCEN + FLASH_ACR_ICEN + FLASH_ACR_PRFTEN) ; Vcliuchit` Cache komand i danny`kh
	AND			R1,			R1,			#~FLASH_ACR_LATENCY
	ORR			R1,			R1,			#FLASH_ACR_LATENCY_2WS ;Razreshit` predvaritel`nuiu vy`borku danny`kh iz pamiati
	STR			R1,			[R0,		#FLASH_ACR]

;Shina Nastroit` preddeliteli taktovy`kh signalov dlia shiny
	LDR			R0,			=RCC_BASE
	
	LDR			R1,			[R0,		#RCC_CFGR]
	ORR			R1,			R1,			#RCC_CFGR_PPRE1_DIV4  
	ORR			R1,			R1,			#RCC_CFGR_PPRE2_DIV2
	AND			R1,			R1,			#~RCC_CFGR_HPRE
	STR			R1,			[R0,		#RCC_CFGR]
	
	LDR			R0,			=RCC_BASE
	LDR			R1,			[R0,		#RCC_AHB1ENR]
	ORR			R1,			R1,			#(RCC_AHB1ENR_GPIOCEN + RCC_AHB1ENR_GPIODEN)
	STR			R1,			[R0,		#RCC_AHB1ENR]
; Vcliuchit` taktirovanie GpioC
	LDR			R0,			=GPIOC_BASE
	LDR			R1,			[R0,		#GPIO_MODER]
	ORR			R1,			R1,			#GPIO_MODER_MODER9_1
	STR			R1,			[R0,		#GPIO_MODER]
	
	LDR			R0, 		=GPIOD_BASE
	LDR			R1, 		[R0, 		#GPIO_MODER] 
	ORR			R1, 		R1,			#GPIO_MODER_MODER15_0
	STR 		R1,		 	[R0, 		#GPIO_MODER]
	
; Nastroit` PC.9 na rabotu v rezhime al`ternativnoi` funktcii ?0 s maksimal`noi` skorost`iu
	LDR			R1,			[R0,		#GPIO_AFRH]
	AND			R1,			R1,			#~GPIO_AFRH_AFSEL9
	ORR			R1,			R1,			#(0 << GPIO_AFRH_AFSEL9_Pos)
	STR			R1,			[R0,		#GPIO_AFRH]
	
	LDR			R1,			[R0,		#GPIO_OSPEEDR]
	ORR			R1,			R1,			#GPIO_OSPEEDR_OSPEED9
	STR			R1,			[R0,		#GPIO_OSPEEDR]
	
	LDR			R0,			=RCC_BASE
; Vcliuchit` vy`vod SYSCLK cherez MCO2
	LDR			R1,			[R0,		#RCC_CFGR]
	AND			R1,			R1,			#~RCC_CFGR_MCO2 ; Vcliuchit` vy`vod SYSCLK cherez MCO2
	ORR			R1,			R1,			#(0 << RCC_CFGR_MCO2_Pos)
	ORR			R1,			R1,			#RCC_CFGR_MCO2PRE ; Ustanovit` preddelitel` MCO2 = 5
	AND			R1,			R1,			#~RCC_CFGR_SW
	ORR			R1,			R1,			#RCC_CFGR_SW_PLL
; Perecliuchit` mikrokontroller na taktirovanie ot PLL
	ORR			R1,			R1,			#RCC_CFGR_SWS_PLL ; 
	STR			R1,			[R0,		#RCC_CFGR]
; Dozhdat`sia perecliucheniia mikrokontrollera na taktirovanie ot PLL
; ono ne nado, on srazu vkluchen

; Vcliuchit` Clock Security System
	LDR			R1,			[R0,		#RCC_CR]
	ORR			R1,			R1,			#RCC_CR_CSSON
	STR			R1,			[R0,		#RCC_CR]
	


;
	
Main_Loop
	B			Main_Loop 
	
; Opisat` obrabotchik prery`vaniia NMI_IRQHandler
NMI_IRQHandler
	LDR			R0,			=RCC_BASE
	
	LDR			R1,			[R0,		#RCC_CIR]
	AND			R2,			R1,			#RCC_CIR_CSSF
	CMP			R2,			#RCC_CIR_CSSF
	BXNE		LR
	ORREQ		R1,			R1,			#RCC_CIR_CSSC
	STR			R1,			[R0,		#RCC_CIR]
	
	LDR			R0, 			=GPIOD_BASE
	LDR			R1, 			[R0, 		#GPIO_ODR]
	BFC			R1,				#GPIO_ODR_OD12_Pos,		#4
	ORR			R1,				R1,			#LED_BLUE
	STR 		R1,		 		[R0, 		#GPIO_ODR]
	
	BX			LR

	END
