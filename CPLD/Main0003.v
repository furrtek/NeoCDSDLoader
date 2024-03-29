// CPLD logic for Neo CD SD Loader Rev. E, production version (CPLD0003)
// This is fully compatible with Rev. D and Rev. C.
// This is compatible with Proto Rev. B with some added wires for nSROMOE_IN and nSROMOE_OUT.
// ONLY compatible with firmware V0.09 (console-to-MCU channel is word-wide now)
// furrtek 2020

module sdloader_cpld (
	input CLK_68KCLK,
	input CLK_MCU,
	
	inout [15:0] M68K_DATA,
	inout [23:1] M68K_ADDR,
	output nFLASH_OE,
	output nFLASH_WE,
	input nFLASH_BUSY,
	
	input nRESET,
	input nHALT,
	input M68K_RW,
	input LDS,
	input UDS,
	input nAS,
	
	output DATA_DIR,
	output ADDR_DIR,
	output nDATA_OE,
	output nADDR_OE,
	
	input nSROMOE_IN,
	output nSROMOE_OUT,
	
	inout [4:0] CPLD,
	inout [15:0] MCU_D,
	
	output nCDDA_SWITCH
);

	// CPLD[0] is always a CPLD input, MCU output.
	
	// When CPLD[0] is low: RUN mode.
	//		Let console run, isolate MCU from flash.
	//		CPLD[1] is a CPLD output, MCU input. Indicates transfer pending.
	//		CPLD[2] is a CPLD input, MCU output. Indicates MCU wants to read a -byte-.
	//		CPLD[3] is a CPLD output, MCU input. Indicates exec pending.
	//		CPLD[4] is a CPLD output, MCU input. Low: console read last word in FIFO, high: console wrote a -byte-.
	//		MCUCLK is used by the MCU to signal transfer done.
	
	// When CPLD[0] is high: MCU mode. Let MCU talk to flash.
	// 	When CPLD[1] is low: do nothing
	// 	When CPLD[1] is high: write to flash
	//		CPLD[2] is a CPLD input, MCU output. Indicates MCU wants the read -word- on its bus.
	// 	When CPLD[3] is low: do nothing
	// 	When CPLD[3] is high: reset state at posedge CLK_MCU
	// 	When CPLD[4] is low: reading is done from the flash
	// 	When CPLD[4] is high: reading is done from the console BIOS
	// 	Address is set by sending a reset, and clocking the LSBs in a -word-, then the MSBs.
	
	reg [18:1] INTERNAL_ADDR;
	reg STATE_ADDR;
	reg READ_PREV;
	reg WRITE_PREV;
	reg GOT_CLK_MCU, GOT_CLK_MCU_PREV, GOT_CLK_MCU_PREV_PREV;
	reg DATA_PENDING;
	reg EXEC_PENDING;
	reg [15:0] CONSOLE_TO_MCU;
	reg [15:0] MCU_TO_CONSOLE[0:3];	// 4-word FIFO
	reg TRANSFER_TYPE;
	reg [15:0] READBACK_REG;
	reg RUN_STOCK;	// 0=Run SD loader 1=Run console as stock
	reg [2:0] STATUS_BITS;
	reg [11:0] PATCH_ADDR;				// Word address (real address >> 1)
	reg [1:0] COUNTRY_CODE;
	reg PATCH_EN;
	wire PATCH_MATCH;
	
	//reg FIFO_DIR;	// 0=MCU to console, 1=Console to MCU
	reg [1:0] FIFO_GET;
	reg [1:0] FIFO_PUT;
	reg [1:0] FIFO_GET_COUNT;
	reg [1:0] FIFO_PUT_COUNT;
	reg REFILL_PENDING;
	
	// Decode C1Exxx
	wire READ = M68K_RW & (M68K_ADDR[23:12] == 12'hC1E);
	wire WRITE = ~M68K_RW & (M68K_ADDR[23:12] == 12'hC1E);
	
	// $C1E0xx
	wire READ_DATA = READ & ~nAS & (M68K_ADDR[11:8] == 4'h0);
	
	// $C1E2xx
	wire READ_STAT = READ & ~nAS & (M68K_ADDR[11:8] == 4'h2);
	
	wire MODE = CPLD[0];
	
	assign CPLD[0] = 1'bz;
	assign CPLD[1] = MODE ? 1'bz : TRANSFER_TYPE ? DATA_PENDING : REFILL_PENDING;
	assign CPLD[2] = 1'bz;
	assign CPLD[3] = MODE ? 1'bz : EXEC_PENDING;
	assign CPLD[4] = MODE ? 1'bz : TRANSFER_TYPE;
	
	// Is this what caused problems ?
	/*always @(posedge nAS) begin
		// Write to C1E0xx
		if (WRITE & (M68K_ADDR[11:8] == 4'h0))
			CONSOLE_TO_MCU <= M68K_DATA;
	end*/
	always @(posedge nAS)
	begin
		// Write to C1E0xx
		if (~M68K_RW & (M68K_ADDR[23:12] == 12'hC1E) & (M68K_ADDR[11:8] == 4'h0))
			CONSOLE_TO_MCU <= {M68K_DATA[7:0], M68K_DATA[15:8]};	// Do endianness change
	end
	
	// Is this what caused problems ?
	/*always @(negedge nAS) begin
		// Latch status bits
		STATUS_BITS <= {REFILL_PENDING, EXEC_PENDING, DATA_PENDING};
	end*/
	
	always @(negedge CLK_68KCLK or negedge nRESET) begin
		if (!nRESET) begin
			READ_PREV <= 1'b0;
			WRITE_PREV <= 1'b0;
			GOT_CLK_MCU_PREV <= 1'b0;
			GOT_CLK_MCU_PREV_PREV <= 1'b0;
			DATA_PENDING <= 0;
			EXEC_PENDING <= 0;
			REFILL_PENDING <= 0;
		end else begin
			READ_PREV <= READ_DATA;
			WRITE_PREV <= WRITE;
			
			//if (nAS)
			//begin
				// Metastability issue here because of different clock domains, we need 2 stages
				GOT_CLK_MCU_PREV <= GOT_CLK_MCU;
				GOT_CLK_MCU_PREV_PREV <= GOT_CLK_MCU_PREV;
				if (GOT_CLK_MCU_PREV != GOT_CLK_MCU_PREV_PREV) begin
					// MCU ack'd pending signals, clear them
					// These must NOT be updated when nAS is low
					DATA_PENDING <= 0;
					EXEC_PENDING <= 0;
					
					// Does this need to be synchronized ?
					FIFO_PUT_COUNT <= FIFO_PUT_COUNT + 1'b1;
					if (FIFO_PUT_COUNT == 2'd3)
						REFILL_PENDING <= 0;
				end
			//end
		
			if (~READ_PREV & READ_DATA) begin
				if (M68K_ADDR[11:8] == 4'h0) begin
					// Read from $C1E0xx (CPLDREG_DATA)
					TRANSFER_TYPE <= 0;	// Read
					READBACK_REG <= MCU_TO_CONSOLE[FIFO_GET];
					FIFO_GET <= FIFO_GET + 1'b1;
					FIFO_GET_COUNT <= FIFO_GET_COUNT + 1'b1;
					if (FIFO_GET_COUNT == 2'd3)
						REFILL_PENDING <= 1;	// FIFO now empty !
				end
			end
			//else
			if (~WRITE_PREV & WRITE) begin
				
				if (M68K_ADDR[11:8] == 4'h0) begin
					// Write to $C1E0xx (CPLDREG_DATA)
					TRANSFER_TYPE <= 1;	// Write
					DATA_PENDING <= 1;
				end else if (M68K_ADDR[11:8] == 4'h1) begin
					// Write to $C1E1xx (CPLDREG_EXEC)
					EXEC_PENDING <= 1;
					REFILL_PENDING <= 1;	// FIFO now empty !
					// Resync FIFO pointers
					FIFO_GET <= FIFO_PUT;
					FIFO_GET_COUNT <= 2'd0;
					FIFO_PUT_COUNT <= 2'd0;
				end
			end
		end
	end
	
	always @(posedge CLK_MCU) begin
		if (MODE) begin
			// MCU mode
			if (!CPLD[3]) begin
				if (!STATE_ADDR)
					INTERNAL_ADDR[16:1] <= MCU_D;			// LSBs first
				else
					INTERNAL_ADDR[18:17] <= MCU_D[1:0];	// Then MSBs
				
				STATE_ADDR <= ~STATE_ADDR;
			end else begin
				// Reset STATE_ADDR, and also allow setting PATCH_ADDR, COUNTRY_CODE, PATCH_EN and RUN_STOCK
				STATE_ADDR <= 0;
				// AAAAAAAA AAAACCES		A=PATCH_ADDR CC=COUNTRY_CODE E=PATCH_EN S=RUN_STOCK
				PATCH_ADDR <= MCU_D[15:4];
				COUNTRY_CODE <= MCU_D[3:2];
				PATCH_EN <= MCU_D[1];
				RUN_STOCK <= MCU_D[0];
			end
		end else begin
			// RUN mode
			MCU_TO_CONSOLE[FIFO_PUT] <= {MCU_D[7:0], MCU_D[15:8]};	// Do endianness change
			FIFO_PUT <= FIFO_PUT + 1'b1;
		end
	end
	
	always @(negedge CLK_MCU or negedge nRESET) begin
		if (!nRESET) begin
			GOT_CLK_MCU <= 1'b0;
		end else begin
			if (!MODE)
				GOT_CLK_MCU <= ~GOT_CLK_MCU;
		end
	end
	
	assign MCU_D = MODE ?
							CPLD[2] ?
								M68K_DATA :						// MCU mode, MCU read, flash or console BIOS
								16'bzzzzzzzzzzzzzzzz :		// MCU mode, idle
							CPLD[2] ?
								CONSOLE_TO_MCU :				// RUN mode, MCU reads latched byte
								16'bzzzzzzzzzzzzzzzz;		// RUN mode, idle
	
	wire MCU_WRITE = CPLD[1] & ~CPLD[2];
	wire MCU_READ = ~CPLD[1] & CPLD[2];
	
	// nRESET is used for nADDR_OE to make sure the console is held in reset
	// when the MCU wants to set the external address
	assign nADDR_OE = MODE ?
								~(MCU_READ & CPLD[4] & ~nRESET) :	// MCU mode, MCU read, console BIOS select
								1'b0;							// RUN mode, address always comes in
	
	// 0: Comes in
	// 1: Goes out
	assign ADDR_DIR = MODE ?
								1'b1 :	// MCU mode, always goes out
								1'b0;		// RUN mode, console sets address
	
	assign PATCH_MATCH = (M68K_ADDR == {11'b1100_0000_110, PATCH_ADDR}) & PATCH_EN & ~nSROMOE_IN;
	
	assign nDATA_OE = MODE ?
								~(MCU_READ & CPLD[4]) :	// MCU mode, MCU read, console BIOS select
								RUN_STOCK ?
									PATCH_MATCH ? 1'b0 :	// RUN mode, stock mode, patch address match, output patch instruction
									1'b1 :					// RUN mode, stock mode, no data output
								nSROMOE_IN;					// RUN mode, loader enabled, console decides

	// 0: Comes in
	// 1: Goes out
	assign DATA_DIR = MODE ?
								1'b0 :	// MCU mode, can only come in
								M68K_RW;	// RUN mode, console decides

	assign M68K_ADDR = MODE ?
								{5'b00000, INTERNAL_ADDR[18:1]} :	// MCU mode, MCU sets address
								23'bzzzzzzz_zzzzzzzz_zzzzzzzz;		// RUN mode, console sets address
	
	assign M68K_DATA = MODE ?
								MCU_WRITE ?
									MCU_D :							// MCU mode, MCU write
									16'bzzzzzzzz_zzzzzzzz :		// MCU mode, read or idle
								// Is this what caused problems ?
								//READ_STAT ? {13'b0000000_00000, STATUS_BITS} :	// RUN mode, read reg, let CPLD talk
								READ_STAT ? {13'b0000000_00000, REFILL_PENDING, EXEC_PENDING, DATA_PENDING} :	// RUN mode, read reg, let CPLD talk
									READ_DATA ? READBACK_REG :							// RUN mode, read reg, let CPLD talk
										PATCH_MATCH ? {14'b0111_001_0_000000, COUNTRY_CODE} :	// RUN mode, read patched instruction (moveq.l #COUNTRY_CODE,d1), let CPLD talk
										16'bzzzzzzzz_zzzzzzzz;	// RUN mode, read flash, let flash talk
	
	assign nFLASH_WE = ~(MODE & MCU_WRITE);		// MCU mode, MCU write
	
	assign nFLASH_OE = MODE ?
								~(MCU_READ & ~CPLD[4]) :		// MCU mode, MCU read, flash select
								(~M68K_RW | nSROMOE_IN | READ_STAT | READ_DATA);		// RUN mode, let console chose
	
	assign nSROMOE_OUT = MODE ?
								~(MCU_READ & CPLD[4] & ~nRESET) :	// MCU mode, MCU read, console BIOS select
								RUN_STOCK ? 
									PATCH_MATCH ? 1'b1:		// RUN mode, stock mode, patch address read match, OE disabled
									nSROMOE_IN :				// RUN mode, stock mode, OE pass-through
								1'b1;								// RUN mode, loader enabled, OE always disabled
	
	assign nCDDA_SWITCH = ~RUN_STOCK;
	
endmodule
