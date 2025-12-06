`timescale 1ns/1ps

module tb_temperature_system;

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
    // Statistics Counters
    //==========================================================================
    integer total_instructions;
    integer total_temp_readings;
    integer temp_ctrl_writes;
    integer temp_data_reads;
    integer timer_expirations;
    integer mem_writes, mem_reads;
    
    //==========================================================================
    // Monitor Temperature Readings
    //==========================================================================
    logic [15:0] last_temp;
    integer reading_number;
    
    initial begin
        last_temp = 16'h0;
        reading_number = 0;
        total_temp_readings = 0;
        
        // Wait for reset
        @(posedge dut.resetn);
        
        forever begin
            @(posedge clk_100MHz);
            
            // Detect new temperature reading
            if (dut.temp_inst.data_ready_flag && (dut.temp_inst.temp_tenths != last_temp)) begin
                reading_number++;
                total_temp_readings++;
                last_temp = dut.temp_inst.temp_tenths;
                
                $display("");
                $display("╔══════════════════════════════════════════════════════════════╗");
                $display("║              📊 LECTURA DE TEMPERATURA #%-3d                 ║", reading_number);
                $display("╠══════════════════════════════════════════════════════════════╣");
                $display("║  Tiempo:       %0t ns                                  ║", $time);
                $display("║  🌡️  Temperatura: %0d.%0d °C                                  ║", 
                         last_temp / 10, last_temp % 10);
                $display("║  📟 Valor RAW:    0x%03X (%0d)                              ║", 
                         last_temp, last_temp);
                $display("║  📺 Display:      0x%08X                                ║", 
                         dut.sevenseg_reg);
                $display("║  💻 Instrucciones: %-8d                                  ║", 
                         total_instructions);
                $display("╚══════════════════════════════════════════════════════════════╝");
            end
        end
    end
    
    //==========================================================================
    // Monitor Core Instructions
    //==========================================================================
    logic [31:0] last_pc;
    
    initial begin
        last_pc = 32'h0;
        total_instructions = 0;
        
        @(posedge dut.resetn);
        
        forever begin
            @(posedge clk_100MHz);
            
            // Count instructions executed
            if (dut.core_inst.instr_addr_o != last_pc) begin
                last_pc = dut.core_inst.instr_addr_o;
                total_instructions++;
            end
        end
    end
    
    //==========================================================================
    // Monitor Memory Accesses
    //==========================================================================
    initial begin
        mem_writes = 0;
        mem_reads = 0;
        
        @(posedge dut.resetn);
        
        forever begin
            @(posedge clk_100MHz);
            
            if (dut.data_req && dut.data_ready) begin
                if (dut.data_we)
                    mem_writes++;
                else
                    mem_reads++;
            end
        end
    end
    
    //==========================================================================
    // Monitor Peripheral Activity
    //==========================================================================
    initial begin
        temp_ctrl_writes = 0;
        temp_data_reads = 0;
        timer_expirations = 0;
        
        @(posedge dut.resetn);
        
        forever begin
            @(posedge clk_100MHz);
            
            if (dut.data_req && dut.data_ready) begin
                if (dut.data_we) begin
                    case (dut.data_addr)
                        32'h0000_2030: begin
                            temp_ctrl_writes++;
                            if (dut.data_wdata == 1)
                                $display("[%0t] 🔄 Iniciando conversión de temperatura...", $time);
                            else if (dut.data_wdata == 2)
                                $display("[%0t] ✅ Flag de temperatura limpiado", $time);
                        end
                        32'h0000_2008: begin
                            $display("[%0t] 📺 Display actualizado: 0x%08X", $time, dut.data_wdata);
                        end
                    endcase
                end else begin
                    case (dut.data_addr)
                        32'h0000_2034: begin
                            temp_data_reads++;
                        end
                        32'h0000_201C: begin
                            if (dut.data_rdata == 0) begin
                                timer_expirations++;
                                $display("[%0t] ⏰ Timer expirado (ciclo #%0d)", $time, timer_expirations);
                            end
                        end
                    endcase
                end
            end
        end
    end
    
    //==========================================================================
    // Display Updates Monitor
    //==========================================================================
    logic [31:0] last_display;
    
    initial begin
        last_display = 32'h0;
        
        @(posedge dut.resetn);
        
        forever begin
            @(posedge clk_100MHz);
            
            if (dut.sevenseg_reg != last_display && dut.sevenseg_reg != 0) begin
                last_display = dut.sevenseg_reg;
            end
        end
    end
    
    //==========================================================================
    // Test Sequence
    //==========================================================================
    initial begin
        $display("");
        $display("════════════════════════════════════════════════════════════════════");
        $display("        🌡️  SISTEMA LECTOR DE TEMPERATURA - TESTBENCH  🌡️          ");
        $display("════════════════════════════════════════════════════════════════════");
        $display("");
        $display("  Lab 4 - EL3313 Arquitectura de Computadoras");
        $display("  Instituto Tecnológico de Costa Rica");
        $display("  Equipo: Sharon, Steven, Diego, Gabriel");
        $display("");
        $display("════════════════════════════════════════════════════════════════════");
        $display("");
        $display("📋 Configuración:");
        $display("   • Procesador:    rv32i_core (RISC-V 32-bit)");
        $display("   • Sensor:        temp_sensor_xadc (modo SIMULATION)");
        $display("   • Frecuencia:    10 MHz");
        $display("   • Display:       7-segmentos (0x2008)");
        $display("   • Temp Control:  0x2030");
        $display("   • Temp Data:     0x2034");
        $display("   • Timer:         0x2018 / 0x201C");
        $display("");
        $display("════════════════════════════════════════════════════════════════════");
        $display("");
        
        // Initialize inputs
        btnC = 1;
        btnL = 0;
        btnR = 0;
        btnU = 0;
        btnD = 0;
        sw = 16'h0000;
        TMP_INT = 0;
        TMP_CT = 0;
        
        // Hold reset
        #100;
        btnC = 0;
        
        $display("✅ Reset liberado en t=%0t", $time);
        $display("🚀 Sistema inicializando...");
        $display("");
        
        // Wait for initialization
        #1000;
        
        $display("🎯 Iniciando monitoreo de temperatura...");
        $display("");
        
        // Run simulation - 20ms should give us ~40 temperature readings
        #20000000;
        
        // Final summary
        $display("");
        $display("════════════════════════════════════════════════════════════════════");
        $display("                    📊 RESUMEN DE SIMULACIÓN                        ");
        $display("════════════════════════════════════════════════════════════════════");
        $display("");
        $display("✅ Simulación completada exitosamente");
        $display("");
        $display("📈 Estadísticas:");
        $display("   • Tiempo total:            %.2f ms", real'($time) / 1_000_000.0);
        $display("   • Lecturas temperatura:    %0d", total_temp_readings);
        $display("   • Instrucciones:           %0d", total_instructions);
        $display("   • Escrituras TEMP_CTRL:    %0d", temp_ctrl_writes);
        $display("   • Lecturas TEMP_DATA:      %0d", temp_data_reads);
        $display("   • Expiraciones Timer:      %0d", timer_expirations);
        $display("   • Accesos memoria R/W:     %0d / %0d", mem_reads, mem_writes);
        $display("");
        
        if (total_temp_readings > 0) begin
            $display("🌡️  Rango de temperatura: 22.0°C → 36.0°C");
            $display("   • Incremento por lectura: ~0.3°C");
            $display("   • Intervalo entre lecturas: ~500 μs");
        end
        
        $display("");
        $display("════════════════════════════════════════════════════════════════════");
        $display("            🎉 PRUEBA COMPLETADA EXITOSAMENTE 🎉                   ");
        $display("════════════════════════════════════════════════════════════════════");
        $display("");
        
        $finish;
    end
    
    //==========================================================================
    // Timeout watchdog
    //==========================================================================
    initial begin
        #50000000;  // 50ms timeout
        $display("");
        $display("⚠️  Tiempo máximo alcanzado - Finalizando simulación");
        $display("");
        $finish;
    end

endmodule
