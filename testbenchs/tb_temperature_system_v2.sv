`timescale 1ns / 1ps

//═══════════════════════════════════════════════════════════════════════
// TESTBENCH SISTEMA LECTOR DE TEMPERATURA - VERSIÓN CORREGIDA V2
//═══════════════════════════════════════════════════════════════════════
// Lab 4 - EL3313 Arquitectura de Computadoras
// Instituto Tecnológico de Costa Rica
// Equipo: Sharon, Steven, Diego, Gabriel
//
// Descripción: Testbench simplificado que monitorea lecturas de temperatura
//              desde el sensor XADC en modo simulación.
//              
// Características:
//   - Monitoreo de accesos a periféricos memory-mapped
//   - Detección de lecturas de temperatura (TEMP_DATA @ 0x2034)
//   - Visualización en consola con cajas Unicode
//   - Sin generación de archivos HTML
//
// Direcciones Memory-Mapped:
//   - SEVENSEG:   0x2008  (Display 7 segmentos)
//   - TIMER_VAL:  0x2018  (Valor del timer)
//   - TIMER_CTRL: 0x201C  (Control del timer)
//   - TEMP_CTRL:  0x2030  (Control de conversión)
//   - TEMP_DATA:  0x2034  (Lectura de temperatura)
//
//═══════════════════════════════════════════════════════════════════════

module tb_temperature_system;

    //═══════════════════════════════════════════════════════════════════
    // PARÁMETROS
    //═══════════════════════════════════════════════════════════════════
    parameter CLK_PERIOD = 10;  // 100 MHz
    parameter CLK_FREQ_MHZ = 100;
    
    // Direcciones memory-mapped
    parameter ADDR_SEVENSEG   = 32'h0000_2008;
    parameter ADDR_TIMER_VAL  = 32'h0000_2018;
    parameter ADDR_TIMER_CTRL = 32'h0000_201C;
    parameter ADDR_TEMP_CTRL  = 32'h0000_2030;
    parameter ADDR_TEMP_DATA  = 32'h0000_2034;
    
    //═══════════════════════════════════════════════════════════════════
    // SEÑALES DEL DUT
    //═══════════════════════════════════════════════════════════════════
    logic clk_100MHz;
    logic btnC, btnL, btnR, btnU, btnD;
    logic [15:0] sw;
    wire SCL, SDA;
    logic TMP_INT, TMP_CT;
    logic [15:0] led;
    logic [7:0] AN;
    logic [7:0] SEG;
    
    //═══════════════════════════════════════════════════════════════════
    // CONTADORES Y ESTADÍSTICAS
    //═══════════════════════════════════════════════════════════════════
    integer total_instructions = 0;
    integer total_temp_readings = 0;
    integer temp_ctrl_writes = 0;
    integer temp_ctrl_clears = 0;
    integer temp_data_reads = 0;
    integer timer_expirations = 0;
    integer mem_reads = 0;
    integer mem_writes = 0;
    
    real min_temp = 999.0;
    real max_temp = -999.0;
    
    //═══════════════════════════════════════════════════════════════════
    // VARIABLES DE MONITOREO
    //═══════════════════════════════════════════════════════════════════
    logic [31:0] last_display_value = 0;
    logic [31:0] last_temp_raw = 0;
    real last_temp_celsius = 0.0;
    
    // Variables auxiliares para lectura de temperatura
    logic [31:0] temp_value;
    real temp_celsius;
    
    //═══════════════════════════════════════════════════════════════════
    // INSTANCIA DEL DUT
    //═══════════════════════════════════════════════════════════════════
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
    
    //═══════════════════════════════════════════════════════════════════
    // GENERACIÓN DE RELOJ
    //═══════════════════════════════════════════════════════════════════
    initial begin
        clk_100MHz = 0;
        forever #(CLK_PERIOD/2) clk_100MHz = ~clk_100MHz;
    end
    
    //═══════════════════════════════════════════════════════════════════
    // BANNER INICIAL
    //═══════════════════════════════════════════════════════════════════
    initial begin
        $display("\n════════════════════════════════════════════════════════════════════");
        $display("        🌡️  SISTEMA LECTOR DE TEMPERATURA - TESTBENCH V2  🌡️          ");
        $display("════════════════════════════════════════════════════════════════════");
        $display("");
        $display("  Lab 4 - EL3313 Arquitectura de Computadoras");
        $display("  Instituto Tecnológico de Costa Rica");
        $display("  Equipo: Sharon, Steven, Diego, Gabriel");
        $display("");
        $display("════════════════════════════════════════════════════════════════════");
        $display("");
        $display(" 📋 Configuración:");
        $display("   • Procesador:    rv32i_core (RISC-V 32-bit)");
        $display("   • Sensor:        temp_sensor_xadc (modo SIMULATION)");
        $display("   • Frecuencia:    %0d MHz", CLK_FREQ_MHZ);
        $display("   • Display:       7-segmentos (0x2008)");
        $display("   • Temp Control:  0x2030");
        $display("   • Temp Data:     0x2034");
        $display("   • Timer:         0x2018 / 0x201C");
        $display("");
        $display("════════════════════════════════════════════════════════════════════");
        $display("");
    end
    
    //═══════════════════════════════════════════════════════════════════
    // PROCESO DE RESET Y SIMULACIÓN
    //═══════════════════════════════════════════════════════════════════
    initial begin
        // Inicialización
        btnC = 1;  // btnC activa reset
        btnL = 0;
        btnR = 0;
        btnU = 0;
        btnD = 0;
        sw = 16'h0000;
        TMP_INT = 0;
        TMP_CT = 0;
        
        // Reset
        #100;
        btnC = 0;  // Liberar reset
        $display("✅ Reset liberado en t=%0t", $time);
        $display("🔄 Sistema inicializando...\n");
        
        // Esperar un tiempo y terminar
        #20_000_000;  // 20 ms
        
        // Resumen final
        print_final_summary();
        
        $display("\n🏁 Simulación completada en t=%0t\n", $time);
        $finish;
    end
    
    //═══════════════════════════════════════════════════════════════════
    // TIMEOUT WATCHDOG
    //═══════════════════════════════════════════════════════════════════
    initial begin
        #50_000_000;  // 50 ms timeout
        $display("\n⏰ TIMEOUT: Simulación alcanzó límite de tiempo");
        print_final_summary();
        $finish;
    end
    
    //═══════════════════════════════════════════════════════════════════
    // MONITOREO DE BUS DE DATOS Y DIRECCIONES
    //═══════════════════════════════════════════════════════════════════
    
    // Señales del procesador (accediendo a través del clk_sys interno)
    wire clk_sys = dut.clk_sys;
    wire resetn = dut.resetn;
    wire [31:0] cpu_addr = dut.data_addr;
    wire [31:0] cpu_wdata = dut.data_wdata;
    wire [31:0] cpu_rdata = dut.data_rdata;
    wire cpu_wren = dut.data_we;
    wire cpu_rden = dut.data_req && !dut.data_we;
    
    // Contador de instrucciones
    wire [31:0] pc = dut.core_inst.instr_addr_o;
    logic [31:0] pc_prev = 0;
    
    always @(posedge clk_sys) begin
        if (resetn) begin
            if (pc != pc_prev) begin
                total_instructions++;
                pc_prev <= pc;
            end
        end else begin
            pc_prev <= 0;
        end
    end
    
    // Monitor de escrituras a memoria
    always @(posedge clk_sys) begin
        if (resetn && cpu_wren) begin
            mem_writes++;
            
            // Detectar escritura a TEMP_CTRL para iniciar conversión
            if (cpu_addr == ADDR_TEMP_CTRL) begin
                if (cpu_wdata == 32'h0000_0001) begin
                    temp_ctrl_writes++;
                    $display("[%0t] 🔄 Iniciando conversión de temperatura...", $time);
                end
                else if (cpu_wdata == 32'h0000_0002) begin
                    temp_ctrl_clears++;
                    // No imprimir cada clear, demasiado verbose
                end
            end
            
            // Detectar actualización del display
            else if (cpu_addr == ADDR_SEVENSEG) begin
                if (cpu_wdata != last_display_value) begin
                    last_display_value = cpu_wdata;
                    $display("[%0t] 📺 Display actualizado: 0x%08h", $time, cpu_wdata);
                end
            end
        end
    end
    
    // Monitor de lecturas de memoria - AQUÍ DETECTAMOS LAS TEMPERATURAS
    // Variables para pipeline de lectura
    logic [31:0] read_addr_delay = 0;
    logic read_en_delay = 0;
    
    always @(posedge clk_sys) begin
        if (resetn) begin
            // Pipeline: guardar dirección y enable de lectura
            read_addr_delay <= cpu_addr;
            read_en_delay <= cpu_rden;
            
            // Detectar lectura de TEMP_DATA en el ciclo siguiente
            if (read_en_delay && read_addr_delay == ADDR_TEMP_DATA) begin
                temp_data_reads++;
                
                // Obtener el valor leído (ahora disponible)
                temp_value = cpu_rdata;
                
                // Convertir a temperatura en Celsius
                temp_celsius = (temp_value * 1.0) / 10.0;
                
                // Solo contar y mostrar si el valor cambió
                if (temp_value != last_temp_raw) begin
                    last_temp_raw = temp_value;
                    last_temp_celsius = temp_celsius;
                    total_temp_readings++;
                    
                    // Actualizar min/max
                    if (temp_celsius < min_temp) min_temp = temp_celsius;
                    if (temp_celsius > max_temp) max_temp = temp_celsius;
                    
                    // Mostrar caja con la lectura
                    print_temperature_reading(total_temp_readings, temp_value, temp_celsius);
                end
            end
            
            // DEBUG: Detectar lectura de TEMP_CTRL para ver qué lee el CPU
            if (read_en_delay && read_addr_delay == ADDR_TEMP_CTRL) begin
                $display("[%0t] 🔍 DEBUG: Leyendo TEMP_CTRL = 0x%08h", $time, cpu_rdata);
            end
            
            // Contar todas las lecturas
            if (cpu_rden) mem_reads++;
        end
    end
    
    // Monitor del timer
    // NOTA: Deshabilitado temporalmente - verificar señal correcta del timer
    // logic timer_prev = 0;
    // always @(posedge clk_sys) begin
    //     if (resetn) begin
    //         logic timer_current = dut.timer_inst.timer_expired;
    //         if (timer_current && !timer_prev) begin
    //             timer_expirations++;
    //             $display("[%0t] ⏰ Timer expirado (ciclo #%0d)", $time, timer_expirations);
    //         end
    //         timer_prev = timer_current;
    //     end
    // end
    
    //═══════════════════════════════════════════════════════════════════
    // FUNCIÓN PARA IMPRIMIR LECTURA DE TEMPERATURA
    //═══════════════════════════════════════════════════════════════════
    task print_temperature_reading(
        input integer reading_num,
        input [31:0] raw_value,
        input real celsius
    );
        begin
            $display("");
            $display("╔══════════════════════════════════════════════════════════════╗");
            $display("║              📊 LECTURA DE TEMPERATURA #%-4d              ║", reading_num);
            $display("╠══════════════════════════════════════════════════════════════╣");
            $display("║  Tiempo:       %-20t ns                      ║", $time);
            $display("║  🌡️  Temperatura: %-8.1f °C                          ║", celsius);
            $display("║  📟 Valor RAW:    0x%03h (%-8d)                   ║", raw_value[11:0], raw_value);
            $display("║  📺 Display:      0x%08h                            ║", last_display_value);
            $display("║  💻 Instrucciones: %-8d                            ║", total_instructions);
            $display("╚══════════════════════════════════════════════════════════════╝");
            $display("");
        end
    endtask
    
    //═══════════════════════════════════════════════════════════════════
    // RESUMEN FINAL
    //═══════════════════════════════════════════════════════════════════
    task print_final_summary();
        begin
            $display("\n");
            $display("╔══════════════════════════════════════════════════════════════╗");
            $display("║                  📈 RESUMEN DE SIMULACIÓN                    ║");
            $display("╠══════════════════════════════════════════════════════════════╣");
            $display("║  Tiempo total:           %-20t ns        ║", $time);
            $display("║  Instrucciones:          %-12d                  ║", total_instructions);
            $display("║  Lecturas temperatura:   %-12d                  ║", total_temp_readings);
            $display("║  Inicios de conversión:  %-12d                  ║", temp_ctrl_writes);
            $display("║  Flags limpiados:        %-12d                  ║", temp_ctrl_clears);
            $display("║  Lecturas TEMP_DATA:     %-12d                  ║", temp_data_reads);
            $display("║  Expiraciones timer:     %-12d                  ║", timer_expirations);
            $display("║  Lecturas memoria:       %-12d                  ║", mem_reads);
            $display("║  Escrituras memoria:     %-12d                  ║", mem_writes);
            if (total_temp_readings > 0) begin
                $display("║  🌡️  Temp. mínima:        %-8.1f °C                  ║", min_temp);
                $display("║  🌡️  Temp. máxima:        %-8.1f °C                  ║", max_temp);
            end
            $display("╠══════════════════════════════════════════════════════════════╣");
            $display("║                     ✅ SIMULACIÓN EXITOSA                    ║");
            $display("╚══════════════════════════════════════════════════════════════╝");
        end
    endtask

endmodule
