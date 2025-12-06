`timescale 1ns / 1ps

//==============================================================================
// Testbench para Top Module Completo con Firmware de Temperatura
// Simula el comportamiento en FPGA
//==============================================================================

module tb_top_integrated;

    logic        clk_100MHz;
    logic        reset_btn;
    logic [15:0] led;
    logic [7:0]  seg;
    logic [7:0]  an;
    
    // Instancia del top module
    top_pcpi_led_fpga dut (
        .clk_100MHz(clk_100MHz),
        .reset_btn (reset_btn),
        .led       (led),
        .seg       (seg),
        .an        (an)
    );
    
    // Generación de reloj 100 MHz
    initial begin
        clk_100MHz = 0;
        forever #5 clk_100MHz = ~clk_100MHz;  // 10ns período = 100 MHz
    end
    
    // Función para decodificar segmentos a dígito
    function string seg_to_digit(logic [7:0] segments);
        case (segments)
            8'b11000000: return "0";
            8'b11111001: return "1";
            8'b10100100: return "2";
            8'b10110000: return "3";
            8'b10011001: return "4";
            8'b10010010: return "5";
            8'b10000010: return "6";
            8'b11111000: return "7";
            8'b10000000: return "8";
            8'b10010000: return "9";
            8'b10001000: return "A";
            8'b10000011: return "b";
            8'b11000110: return "C";
            8'b10100001: return "d";
            8'b10000110: return "E";
            8'b10001110: return "F";
            default:     return "-";
        endcase
    endfunction
    
    // Variables para monitoreo
    logic [31:0] display_value;
    integer temperatura_actual;
    real tiempo_real;
    
    // Decodificar valor del display (observando cuando cambia)
    always @(posedge dut.clk_10MHz) begin
        if (dut.display_wr_en) begin
            display_value = dut.mem_wdata;
            temperatura_actual = display_value[7:0];  // Los 2 dígitos menos significativos
            tiempo_real = $time / 1_000_000_000.0;    // Convertir ns a segundos
            
            $display("[t=%.1fs] Temperatura = %02d°C, Display = 0x%08h, LEDs = 0x%04h", 
                     tiempo_real, temperatura_actual, display_value, led);
        end
    end
    
    // Monitor del timer (cuando termina la cuenta)
    logic prev_timer_done;
    initial prev_timer_done = 0;
    
    always @(posedge dut.clk_10MHz) begin
        if (dut.timer.timer_done && !prev_timer_done) begin
            tiempo_real = $time / 1_000_000_000.0;
            $display("    [t=%.1fs] >>> TIMER DONE! <<<", tiempo_real);
        end
        prev_timer_done <= dut.timer.timer_done;
    end
    
    // Monitor del estado del procesador
    string estado_actual;
    always @(posedge dut.clk_10MHz) begin
        case (dut.state)
            dut.FETCH:     estado_actual = "FETCH";
            dut.DECODE:    estado_actual = "DECODE";
            dut.EXECUTE:   estado_actual = "EXECUTE";
            dut.WRITEBACK: estado_actual = "WRITEBACK";
            dut.HALT:      estado_actual = "HALT";
            default:       estado_actual = "UNKNOWN";
        endcase
    end
    
    // Test principal
    initial begin
        $display("=============================================================");
        $display("Testbench: Simulación de Firmware de Temperatura");
        $display("=============================================================");
        $display("Firmware: firmware_temperature.hex");
        $display("Comportamiento esperado:");
        $display("  - Temperatura inicial: 25°C");
        $display("  - Rango: 20-30°C");
        $display("  - Actualización: cada 2 segundos");
        $display("  - Patrón: 25→26→27→28→29→30→29→28→...→20→21→...");
        $display("=============================================================\n");
        
        // Reset
        reset_btn = 1;
        #100;
        reset_btn = 0;
        
        $display("[INFO] Reset liberado, iniciando ejecución del firmware...\n");
        
        // Esperar suficiente tiempo para ver varios ciclos de temperatura
        // Cada ciclo es 100ms (con firmware_fast) = 100,000,000 ns
        // Simular ~3 segundos para ver el patrón completo
        
        wait(dut.state == dut.HALT || $time > 3000000000);  // 3 segundos o HALT
        
        if (dut.state == dut.HALT) begin
            $display("\n[WARNING] Sistema entró en HALT inesperadamente");
            $display("          PC = 0x%08h", dut.pc_current);
        end else begin
            $display("\n[INFO] Simulación completada exitosamente");
        end
        
        $display("\n=============================================================");
        $display("Resumen de la simulación:");
        $display("  Tiempo total: %.1f segundos", $time / 1_000_000_000.0);
        $display("  Instrucciones ejecutadas: %0d", dut.instruction_count);
        $display("  Ciclos de reloj (10MHz): %0d", dut.cycle_count);
        $display("  Estado final: %s", estado_actual);
        $display("  Temperatura final: %02d°C", temperatura_actual);
        $display("=============================================================");
        
        #1000;
        $finish;
    end
    
    // Monitor adicional: mostrar cada 100ms qué está pasando
    initial begin
        integer seg;
        for (seg = 0; seg < 30; seg++) begin
            #100000000;  // Esperar 100ms (sin guiones bajos)
            $display("[t=%.1fs] Estado=%s, PC=0x%08h, Display=0x%08h, Temp=%02d°C", 
                     $time / 1_000_000_000.0, estado_actual, dut.pc_current, display_value, temperatura_actual);
        end
    end
    
    // Timeout de seguridad
    initial begin
        #5000000000;  // 5 segundos máximo (sin guiones bajos para evitar overflow)
        $display("\n[TIMEOUT] Simulación excedió 5 segundos");
        $finish;
    end
    
    // Monitor de display multiplexado (para debug)
    /*
    always @(posedge dut.clk_10MHz) begin
        if (dut.display.refresh_counter == 0) begin
            $display("  [Display %0d] Segmentos = %s", 
                     dut.display.display_select, 
                     seg_to_digit(seg));
        end
    end
    */
    
endmodule
