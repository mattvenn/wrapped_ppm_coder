`default_nettype none
`ifdef FORMAL
    `define MPRJ_IO_PADS 38    
`endif

//`define USE_WB  0
//`define USE_LA  1
`define USE_IO  1
//`define USE_MEM 0
//`define USE_IRQ 0

// update this to the name of your module
module wrapped_ppm_coder(
`ifdef USE_POWER_PINS
    inout vccd1,	// User area 1 1.8V supply
    inout vssd1,	// User area 1 digital ground
`endif
    input wire wb_clk_i,            // clock, runs at system clock
 // wishbone interface
`ifdef USE_WB
    input wire wb_rst_i,            // main system reset
    input wire wbs_stb_i,           // wishbone write strobe
    input wire wbs_cyc_i,           // wishbone cycle
    input wire wbs_we_i,            // wishbone write enable
    input wire [3:0] wbs_sel_i,     // wishbone write word select
    input wire [31:0] wbs_dat_i,    // wishbone data in
    input wire [31:0] wbs_adr_i,    // wishbone address
    output wire wbs_ack_o,          // wishbone ack
    output wire [31:0] wbs_dat_o,   // wishbone data out
`endif
    // Logic Analyzer Signals
    // only provide first 32 bits to reduce wiring congestion
`ifdef USE_LA
    input  wire [31:0] la1_data_in,  // from PicoRV32 to your project
    output wire [31:0] la1_data_out, // from your project to PicoRV32
    input  wire [31:0] la1_oenb,     // output enable bar (low for active)
`endif

    // IOs
`ifdef USE_IO
    input  wire [`MPRJ_IO_PADS-1:0] io_in,  // in to your project
    output wire [`MPRJ_IO_PADS-1:0] io_out, // out fro your project
    output wire [`MPRJ_IO_PADS-1:0] io_oeb, // out enable bar (low active)
`endif

    // IRQ
`ifdef USE_IRQ
    output wire [2:0] user_irq,          // interrupt from project to PicoRV32
`endif

`ifdef USE_CLK2
    // extra user clock
    input wire user_clock2,
`endif
    
    // active input, only connect tristated outputs if this is high
    input wire active
);

    // all outputs must be tristated before being passed onto the project
    wire buf_wbs_ack_o;
    wire [31:0] buf_wbs_dat_o;
    wire [31:0] buf_la1_data_out;
    wire [`MPRJ_IO_PADS-1:0] buf_io_out;
    wire [`MPRJ_IO_PADS-1:0] buf_io_oeb;
    wire [2:0] buf_user_irq;

    `ifdef FORMAL
    // formal can't deal with z, so set all outputs to 0 if not active
    `ifdef USE_WB
    assign wbs_ack_o    = active ? buf_wbs_ack_o    : 1'b0;
    assign wbs_dat_o    = active ? buf_wbs_dat_o    : 32'b0;
    `endif
    `ifdef USE_LA
    assign la1_data_out = active ? buf_la1_data_out  : 32'b0;
    `endif
    `ifdef USE_IO
    assign io_out       = active ? buf_io_out       : {`MPRJ_IO_PADS{1'b0}};
    assign io_oeb       = active ? buf_io_oeb       : {`MPRJ_IO_PADS{1'b0}};
    `endif
    `ifdef USE_IRQ
    assign user_irq     = active ? buf_user_irq          : 3'b0;
    `endif
    `include "properties.v"
    `else
    // tristate buffers
    
    `ifdef USE_WB
    assign wbs_ack_o    = active ? buf_wbs_ack_o    : 1'bz;
    assign wbs_dat_o    = active ? buf_wbs_dat_o    : 32'bz;
    `endif
    `ifdef USE_LA
    assign la1_data_out  = active ? buf_la1_data_out  : 32'bz;
    `endif
    `ifdef USE_IO
    assign io_out       = active ? buf_io_out       : {`MPRJ_IO_PADS{1'bz}};
    assign io_oeb       = active ? buf_io_oeb       : {`MPRJ_IO_PADS{1'bz}};
    `endif
    `ifdef USE_IRQ
    assign user_irq     = active ? buf_user_irq          : 3'bz;
    `endif
    `endif

    // permanently set oeb so that outputs are always enabled: 0 is output, 1 is high-impedance
    assign buf_io_oeb = {`MPRJ_IO_PADS{1'b0}};

    // Instantiate your module here, 
    // connecting what you need of the above signals. 
    // Use the buffered outputs for your module's outputs.

    ppmCoder4_8 ppmCoder4_8(   
    // inputs
     .v16dfc8(wb_clk_i),         // clk. reloj del sistema (12 Mhz Alhambra II )
     .v7d096c(io_in[8 ]),        // b_0. bit 0 ADC externo (LSB)
     .v0c9cd1(io_in[9 ]),        // b_1. bit 1 
     .vb77d06(io_in[10]),        // b_2. bit 2
     .v533a8a(io_in[11]),        // b_3. bit 3
     .v2d3df4(io_in[12]),        // b_4. bit 4
     .v70ac2f(io_in[13]),        // b_5. bit 5
     .v86dc1e(io_in[14]),        // b_6. bit 6
     .vc8cc9c(io_in[15]),        // b_7. bit 7
     .ve27382(io_in[16]),        // b_8. bit 8
     .v9bc276(io_in[17]),        // b_9. bit 9
     .v0ee52d(io_in[18]),        // b_10. bit 10
     .v22ffe7(io_in[19]),        // b_11. bit 11
     .v778dbe(io_in[20]),        // L_bits. Longitud bits  0 = 8 bits 1 = 12 bits ADC
     .v1bc7bb(io_in[21]),        // Ganancia ADC.  0 = 1 a 2 ms   1 = 0.6 a 2.4 ms
     .v1a29fb(io_in[22]),        // Canales. 0 = 4 canales  1 = 8 canales
     .vff1f51(io_in[23]),        // ADC_ok. señal de fin de conversión ADC externo
     .v003794(io_in[24]),        // Reset.  señal de reset 

     // outputs
     .v58d645(buf_io_out[25]),       // PPM_iv. Señal de salida del pulsos PPM en modo invertido
     .v7294e9(buf_io_out[26]),       // Start. Envío de señal de inicio de la conversión del ADC externo
     .v4b477d(buf_io_out[27]),       // Sel_0
     .v1f8e7b(buf_io_out[28]),       // Sel_1
     .v7cb71c(buf_io_out[29])        // Sel_2  [Sel_0 a Sel_2] selección del canal de entrada en el ADC 
 );

endmodule 
`default_nettype wire
