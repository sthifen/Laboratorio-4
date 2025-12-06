`timescale 1ns/1ps

module tb_temp_sensor_system;

    //==========================================================================
    // Clock and Reset
    //==========================================================================
    logic clk_100MHz;
    logic btnC;
    
    // Generate 100 MHz clock (10ns period)
    initial begin
        clk_100MHz = 0;
        forever #5 clk_100MHz = ~clk_100MHz;
    end
    
    //==========================================================================
    // DUT Signals
    //==========================================================================
    logic        btnL, btnR, btnU, btnD;
    logic [15:0] sw;
    wire         SCL, SDA;
    logic        TMP_INT, TMP_CT;
    logic [15:0] led;
    logic [7:0]  AN;
    logic [7:0]  SEG;
    
    //==========================================================================
    // DUT Instantiation
    //==========================================================================
    top_pcpi_led_fpga dut (
        .clk_100MHz(clk_100MHz),
        .btnC(btnC),
        .btnL(btnL),
        .btnR(btnR),
        .btnU(btnU),
        .btnD(btnD),
        .sw(sw),
        .SCL(SCL),
        .SDA(SDA),
        .TMP_INT(TMP_INT),
        .TMP_CT(TMP_CT),
        .led(led),
        .AN(AN),
        .SEG(SEG)
    );
    
    //==========================================================================
    // Helper Functions for Display Decoding
    //==========================================================================
    function string decode_7seg(input logic [7:0] seg);
        // Decodifica segmentos a dígito
        // Formato: {dp, g, f, e, d, c, b, a}
        case(seg[6:0])
            7'b0111111: return "0";
            7'b0000110: return "1";
            7'b1011011: return "2";
            7'b1001111: return "3";
            7'b1100110: return "4";
            7'b1101101: return "5";
            7'b1111101: return "6";
            7'b0000111: return "7";
            7'b1111111: return "8";
            7'b1101111: return "9";
            7'b1110111: return "A";
            7'b1111100: return "b";
            7'b0111001: return "C";
            7'b1011110: return "d";
            7'b1111001: return "E";
            7'b1110001: return "F";
            default: return " ";
        endcase
    endfunction
    
    //==========================================================================
    // Monitor Temperature Display
    //==========================================================================
    logic [31:0] last_sevenseg_value;
    logic [31:0] current_temp_raw;
    real current_temp_celsius;
    
    initial begin
        last_sevenseg_value = 32'hFFFFFFFF;
        forever begin
            @(posedge clk_100MHz);
            
            // Capturar valor del display cuando cambia
            if (dut.sevenseg_reg != last_sevenseg_value) begin
                last_sevenseg_value = dut.sevenseg_reg;
                $display("[%0t] Display Updated: 0x%08h", $time, dut.sevenseg_reg);
            end
            
            // Monitorear lecturas de temperatura
            if (dut.temp_inst.data_ready_flag) begin
                current_temp_raw = dut.temp_inst.temp_tenths;
                current_temp_celsius = real'(current_temp_raw) / 10.0;
                $display("[%0t] Temperature Reading: %0d.%0d°C (raw: %0d)", 
                         $time, 
                         current_temp_raw / 10,
                         current_temp_raw % 10,
                         current_temp_raw);
            end
        end
    end
    
    //==========================================================================
    // Monitor Core Activity
    //==========================================================================
    integer instr_count;
    logic [31:0] last_pc;
    
    initial begin
        instr_count = 0;
        last_pc = 32'h0;
        
        // Esperar reset
        @(posedge dut.resetn);
        
        forever begin
            @(posedge clk_100MHz);
            
            // Contar instrucciones ejecutadas
            if (dut.core_inst.instr_addr_o != last_pc) begin
                last_pc = dut.core_inst.instr_addr_o;
                instr_count++;
                
                // Mostrar primeras 50 instrucciones para debug
                if (instr_count <= 50) begin
                    $display("[%0t] PC=0x%08h | Instr=0x%08h", 
                             $time, 
                             dut.core_inst.instr_addr_o,
                             dut.instr_data);
                end
            end
        end
    end
    
    //==========================================================================
    // Monitor Peripheral Accesses
    //==========================================================================
    initial begin
        forever begin
            @(posedge clk_100MHz);
            
            if (dut.data_req && dut.data_ready) begin
                if (dut.data_we) begin
                    // Write operation
                    case (dut.data_addr)
                        32'h0000_2008: $display("[%0t] WRITE SEVENSEG: 0x%08h", $time, dut.data_wdata);
                        32'h0000_2018: $display("[%0t] WRITE TIMER_CTRL: 0x%08h", $time, dut.data_wdata);
                        32'h0000_201C: $display("[%0t] WRITE TIMER_DATA: %0d cycles", $time, dut.data_wdata);
                        32'h0000_2030: $display("[%0t] WRITE TEMP_CTRL: 0x%08h", $time, dut.data_wdata);
                        default: ;
                    endcase
                end else begin
                    // Read operation
                    case (dut.data_addr)
                        32'h0000_2030: $display("[%0t] READ TEMP_CTRL: 0x%08h", $time, dut.data_rdata);
                        32'h0000_2034: $display("[%0t] READ TEMP_DATA: %0d (%.1f°C)", 
                                                $time, dut.data_rdata, real'(dut.data_rdata) / 10.0);
                        32'h0000_201C: begin
                            if (dut.data_rdata == 0)
                                $display("[%0t] Timer expired!", $time);
                        end
                        default: ;
                    endcase
                end
            end
        end
    end
    
    //==========================================================================
    // Test Sequence
    //==========================================================================
    initial begin
        $display("=" * 70);
        $display("Temperature Sensor System Testbench");
        $display("=" * 70);
        $display("Memory Map:");
        $display("  0x2008 - Seven Segment Display");
        $display("  0x2018 - Timer Control");
        $display("  0x201C - Timer Data");  
        $display("  0x2030 - Temperature Control (bit[0]=start, bit[1]=data_ready)");
        $display("  0x2034 - Temperature Data (in tenths of °C)");
        $display("=" * 70);
        
        // Initialize inputs
        btnC = 1;
        btnL = 0;
        btnR = 0;
        btnU = 0;
        btnD = 0;
        sw = 16'h0000;
        TMP_INT = 0;
        TMP_CT = 0;
        
        // Hold reset for 100ns
        #100;
        btnC = 0;
        
        $display("[%0t] Reset released", $time);
        
        // Wait for system to initialize
        #1000;
        
        $display("[%0t] System initialized, starting temperature monitoring...", $time);
        
        // Simulate for enough time to see multiple temperature readings
        // En modo simulación, el sensor cambia cada 2000 ciclos @ 10MHz
        // 2000 ciclos = 200us
        // Esperar ~10 lecturas = 2ms
        #50000000;  // 50ms de simulación
        
        $display("=" * 70);
        $display("Simulation Summary:");
        $display("  Total instructions executed: %0d", instr_count);
        $display("  Final temperature: %.1f°C", current_temp_celsius);
        $display("  Final display value: 0x%08h", last_sevenseg_value);
        $display("=" * 70);
        
        $finish;
    end
    
    //==========================================================================
    // Timeout watchdog
    //==========================================================================
    initial begin
        #100000000;  // 100ms timeout
        $display("ERROR: Simulation timeout!");
        $finish;
    end
    
    //==========================================================================
    // Waveform dump (opcional, comentar si no se necesita)
    //==========================================================================
    // initial begin
    //     $dumpfile("tb_temp_sensor_system.vcd");
    //     $dumpvars(0, tb_temp_sensor_system);
    // end

endmodule
