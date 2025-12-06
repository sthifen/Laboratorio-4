`timescale 1ns/1ps

module tb_temp_display_demo;

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
    // Data Collection
    //==========================================================================
    typedef struct {
        time timestamp;
        real temp_celsius;
        int temp_raw;
        int display_value;
        int instr_count;
    } temp_sample_t;
    
    temp_sample_t samples[$];
    integer total_instructions;
    integer total_temp_readings;
    integer file_handle;
    
    //==========================================================================
    // Helper Functions
    //==========================================================================
    function string decode_7seg(input logic [7:0] seg);
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
    
    function string decode_display(input logic [31:0] display_val);
        string result;
        int i;
        for (i = 7; i >= 0; i--) begin
            result = {result, decode_7seg(display_val[i*4 +: 4] << 3)};
        end
        return result;
    endfunction
    
    //==========================================================================
    // Monitor Temperature and Display
    //==========================================================================
    logic [31:0] last_sevenseg;
    logic [15:0] last_temp;
    integer sample_count;
    
    initial begin
        last_sevenseg = 32'hFFFFFFFF;
        last_temp = 16'h0;
        sample_count = 0;
        total_instructions = 0;
        total_temp_readings = 0;
        
        // Wait for reset
        @(posedge dut.resetn);
        
        forever begin
            @(posedge clk_100MHz);
            
            // Detect new temperature reading
            if (dut.temp_inst.data_ready_flag && (dut.temp_inst.temp_tenths != last_temp)) begin
                temp_sample_t sample;
                sample.timestamp = $time;
                sample.temp_raw = dut.temp_inst.temp_tenths;
                sample.temp_celsius = real'(dut.temp_inst.temp_tenths) / 10.0;
                sample.display_value = dut.sevenseg_reg;
                sample.instr_count = total_instructions;
                
                samples.push_back(sample);
                last_temp = dut.temp_inst.temp_tenths;
                sample_count++;
                total_temp_readings++;
                
                $display("");
                $display("╔══════════════════════════════════════════════════════════════════╗");
                $display("║  📊 LECTURA #%-3d                                    [%0t ns] ║", sample_count, $time);
                $display("╠══════════════════════════════════════════════════════════════════╣");
                $display("║  🌡️  Temperatura: %0d.%0d °C (RAW: 0x%03X)                         ║", 
                         sample.temp_raw / 10, sample.temp_raw % 10, sample.temp_raw);
                $display("║  📺 Display: 0x%08X                                        ║", sample.display_value);
                $display("║  💻 Instrucciones ejecutadas: %-8d                          ║", sample.instr_count);
                $display("╚══════════════════════════════════════════════════════════════════╝");
            end
            
            // Detect display update
            if (dut.sevenseg_reg != last_sevenseg && dut.sevenseg_reg != 0) begin
                last_sevenseg = dut.sevenseg_reg;
                $display("[%0t] 🖥️  Display actualizado: 0x%08X", $time, dut.sevenseg_reg);
            end
        end
    end
    
    //==========================================================================
    // Monitor Core Activity
    //==========================================================================
    logic [31:0] last_pc;
    integer mem_writes, mem_reads;
    
    initial begin
        last_pc = 32'h0;
        mem_writes = 0;
        mem_reads = 0;
        
        @(posedge dut.resetn);
        
        forever begin
            @(posedge clk_100MHz);
            
            // Count instructions
            if (dut.core_inst.instr_addr_o != last_pc) begin
                last_pc = dut.core_inst.instr_addr_o;
                total_instructions++;
            end
            
            // Count memory accesses
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
    integer temp_ctrl_writes, temp_data_reads;
    integer timer_expirations;
    
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
                                $display("[%0t] ⏰ Timer expirado (iteración #%0d)", $time, timer_expirations);
                            end
                        end
                    endcase
                end
            end
        end
    end
    
    //==========================================================================
    // Generate HTML Report
    //==========================================================================
    task generate_html_report();
        integer i;
        temp_sample_t sample;
        
        file_handle = $fopen("temperature_report.html", "w");
        
        // HTML Header
        $fwrite(file_handle, "<!DOCTYPE html>\n");
        $fwrite(file_handle, "<html lang='es'>\n");
        $fwrite(file_handle, "<head>\n");
        $fwrite(file_handle, "    <meta charset='UTF-8'>\n");
        $fwrite(file_handle, "    <meta name='viewport' content='width=device-width, initial-scale=1.0'>\n");
        $fwrite(file_handle, "    <title>Reporte - Sistema Lector de Temperatura</title>\n");
        $fwrite(file_handle, "    <script src='https://cdn.jsdelivr.net/npm/chart.js'></script>\n");
        $fwrite(file_handle, "    <style>\n");
        $fwrite(file_handle, "        * { margin: 0; padding: 0; box-sizing: border-box; }\n");
        $fwrite(file_handle, "        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background: linear-gradient(135deg, #667eea 0%%, #764ba2 100%%); padding: 20px; }\n");
        $fwrite(file_handle, "        .container { max-width: 1200px; margin: 0 auto; background: white; border-radius: 20px; padding: 30px; box-shadow: 0 20px 60px rgba(0,0,0,0.3); }\n");
        $fwrite(file_handle, "        h1 { color: #667eea; text-align: center; margin-bottom: 10px; font-size: 2.5em; }\n");
        $fwrite(file_handle, "        .subtitle { text-align: center; color: #666; margin-bottom: 30px; font-size: 1.1em; }\n");
        $fwrite(file_handle, "        .stats { display: grid; grid-template-columns: repeat(auto-fit, minmax(250px, 1fr)); gap: 20px; margin: 30px 0; }\n");
        $fwrite(file_handle, "        .stat-card { background: linear-gradient(135deg, #667eea 0%%, #764ba2 100%%); padding: 20px; border-radius: 15px; color: white; box-shadow: 0 10px 30px rgba(102, 126, 234, 0.4); }\n");
        $fwrite(file_handle, "        .stat-card h3 { font-size: 0.9em; opacity: 0.9; margin-bottom: 10px; }\n");
        $fwrite(file_handle, "        .stat-card .value { font-size: 2.5em; font-weight: bold; }\n");
        $fwrite(file_handle, "        .chart-container { margin: 30px 0; padding: 20px; background: #f8f9fa; border-radius: 15px; }\n");
        $fwrite(file_handle, "        table { width: 100%%; border-collapse: collapse; margin: 20px 0; }\n");
        $fwrite(file_handle, "        th { background: #667eea; color: white; padding: 15px; text-align: left; }\n");
        $fwrite(file_handle, "        td { padding: 12px; border-bottom: 1px solid #ddd; }\n");
        $fwrite(file_handle, "        tr:hover { background: #f8f9fa; }\n");
        $fwrite(file_handle, "        .footer { text-align: center; margin-top: 40px; color: #666; font-size: 0.9em; }\n");
        $fwrite(file_handle, "        .badge { display: inline-block; padding: 5px 10px; border-radius: 5px; font-size: 0.8em; font-weight: bold; }\n");
        $fwrite(file_handle, "        .badge-success { background: #28a745; color: white; }\n");
        $fwrite(file_handle, "        .badge-info { background: #17a2b8; color: white; }\n");
        $fwrite(file_handle, "        .badge-warning { background: #ffc107; color: black; }\n");
        $fwrite(file_handle, "    </style>\n");
        $fwrite(file_handle, "</head>\n");
        $fwrite(file_handle, "<body>\n");
        $fwrite(file_handle, "    <div class='container'>\n");
        $fwrite(file_handle, "        <h1>🌡️ Sistema Lector de Temperatura</h1>\n");
        $fwrite(file_handle, "        <p class='subtitle'>Lab 4 - EL3313 Arquitectura de Computadoras - TEC</p>\n");
        $fwrite(file_handle, "        <p class='subtitle'><strong>Equipo:</strong> Sharon, Steven, Diego, Gabriel</p>\n");
        
        // Statistics Cards
        $fwrite(file_handle, "        <div class='stats'>\n");
        $fwrite(file_handle, "            <div class='stat-card'>\n");
        $fwrite(file_handle, "                <h3>📊 Lecturas de Temperatura</h3>\n");
        $fwrite(file_handle, "                <div class='value'>%0d</div>\n", sample_count);
        $fwrite(file_handle, "            </div>\n");
        $fwrite(file_handle, "            <div class='stat-card'>\n");
        $fwrite(file_handle, "                <h3>💻 Instrucciones Ejecutadas</h3>\n");
        $fwrite(file_handle, "                <div class='value'>%0d</div>\n", total_instructions);
        $fwrite(file_handle, "            </div>\n");
        $fwrite(file_handle, "            <div class='stat-card'>\n");
        $fwrite(file_handle, "                <h3>🔄 Accesos a Periféricos</h3>\n");
        $fwrite(file_handle, "                <div class='value'>%0d</div>\n", temp_ctrl_writes + temp_data_reads);
        $fwrite(file_handle, "            </div>\n");
        $fwrite(file_handle, "            <div class='stat-card'>\n");
        $fwrite(file_handle, "                <h3>⏱️ Tiempo de Simulación</h3>\n");
        $fwrite(file_handle, "                <div class='value'>%.2f ms</div>\n", real'($time) / 1_000_000.0);
        $fwrite(file_handle, "            </div>\n");
        $fwrite(file_handle, "        </div>\n");
        
        // Temperature Chart
        $fwrite(file_handle, "        <div class='chart-container'>\n");
        $fwrite(file_handle, "            <h2 style='color: #667eea; margin-bottom: 20px;'>📈 Evolución de Temperatura</h2>\n");
        $fwrite(file_handle, "            <canvas id='tempChart'></canvas>\n");
        $fwrite(file_handle, "        </div>\n");
        
        // Data Table
        $fwrite(file_handle, "        <h2 style='color: #667eea; margin: 30px 0 20px 0;'>📋 Registro de Lecturas</h2>\n");
        $fwrite(file_handle, "        <table>\n");
        $fwrite(file_handle, "            <thead>\n");
        $fwrite(file_handle, "                <tr>\n");
        $fwrite(file_handle, "                    <th>#</th>\n");
        $fwrite(file_handle, "                    <th>Tiempo (μs)</th>\n");
        $fwrite(file_handle, "                    <th>Temperatura (°C)</th>\n");
        $fwrite(file_handle, "                    <th>Valor RAW (hex)</th>\n");
        $fwrite(file_handle, "                    <th>Display (hex)</th>\n");
        $fwrite(file_handle, "                    <th>Instrucciones</th>\n");
        $fwrite(file_handle, "                </tr>\n");
        $fwrite(file_handle, "            </thead>\n");
        $fwrite(file_handle, "            <tbody>\n");
        
        for (i = 0; i < samples.size(); i++) begin
            sample = samples[i];
            $fwrite(file_handle, "                <tr>\n");
            $fwrite(file_handle, "                    <td><span class='badge badge-info'>%0d</span></td>\n", i+1);
            $fwrite(file_handle, "                    <td>%.2f</td>\n", real'(sample.timestamp) / 1000.0);
            $fwrite(file_handle, "                    <td><strong>%.1f °C</strong></td>\n", sample.temp_celsius);
            $fwrite(file_handle, "                    <td>0x%03X</td>\n", sample.temp_raw);
            $fwrite(file_handle, "                    <td>0x%08X</td>\n", sample.display_value);
            $fwrite(file_handle, "                    <td>%0d</td>\n", sample.instr_count);
            $fwrite(file_handle, "                </tr>\n");
        end
        
        $fwrite(file_handle, "            </tbody>\n");
        $fwrite(file_handle, "        </table>\n");
        
        // System Information
        $fwrite(file_handle, "        <h2 style='color: #667eea; margin: 30px 0 20px 0;'>⚙️ Información del Sistema</h2>\n");
        $fwrite(file_handle, "        <table>\n");
        $fwrite(file_handle, "            <tr><td><strong>Procesador</strong></td><td>rv32i_core (RISC-V 32-bit)</td></tr>\n");
        $fwrite(file_handle, "            <tr><td><strong>Frecuencia de reloj</strong></td><td>10 MHz</td></tr>\n");
        $fwrite(file_handle, "            <tr><td><strong>Sensor</strong></td><td>temp_sensor_xadc (Modo SIMULATION)</td></tr>\n");
        $fwrite(file_handle, "            <tr><td><strong>Rango de temperatura</strong></td><td>22.0°C - 36.0°C</td></tr>\n");
        $fwrite(file_handle, "            <tr><td><strong>Resolución</strong></td><td>0.1°C (décimas de grado)</td></tr>\n");
        $fwrite(file_handle, "            <tr><td><strong>Escrituras TEMP_CTRL</strong></td><td>%0d</td></tr>\n", temp_ctrl_writes);
        $fwrite(file_handle, "            <tr><td><strong>Lecturas TEMP_DATA</strong></td><td>%0d</td></tr>\n", temp_data_reads);
        $fwrite(file_handle, "            <tr><td><strong>Expiraciones de Timer</strong></td><td>%0d</td></tr>\n", timer_expirations);
        $fwrite(file_handle, "            <tr><td><strong>Accesos a memoria (write)</strong></td><td>%0d</td></tr>\n", mem_writes);
        $fwrite(file_handle, "            <tr><td><strong>Accesos a memoria (read)</strong></td><td>%0d</td></tr>\n", mem_reads);
        $fwrite(file_handle, "        </table>\n");
        
        // JavaScript for Chart
        $fwrite(file_handle, "        <script>\n");
        $fwrite(file_handle, "            const ctx = document.getElementById('tempChart').getContext('2d');\n");
        $fwrite(file_handle, "            const chart = new Chart(ctx, {\n");
        $fwrite(file_handle, "                type: 'line',\n");
        $fwrite(file_handle, "                data: {\n");
        $fwrite(file_handle, "                    labels: [");
        for (i = 0; i < samples.size(); i++) begin
            sample = samples[i];
            $fwrite(file_handle, "'%.1f'", real'(sample.timestamp) / 1000000.0);
            if (i < samples.size() - 1) $fwrite(file_handle, ", ");
        end
        $fwrite(file_handle, "],\n");
        $fwrite(file_handle, "                    datasets: [{\n");
        $fwrite(file_handle, "                        label: 'Temperatura (°C)',\n");
        $fwrite(file_handle, "                        data: [");
        for (i = 0; i < samples.size(); i++) begin
            sample = samples[i];
            $fwrite(file_handle, "%.1f", sample.temp_celsius);
            if (i < samples.size() - 1) $fwrite(file_handle, ", ");
        end
        $fwrite(file_handle, "],\n");
        $fwrite(file_handle, "                        borderColor: 'rgb(102, 126, 234)',\n");
        $fwrite(file_handle, "                        backgroundColor: 'rgba(102, 126, 234, 0.1)',\n");
        $fwrite(file_handle, "                        tension: 0.4,\n");
        $fwrite(file_handle, "                        fill: true\n");
        $fwrite(file_handle, "                    }]\n");
        $fwrite(file_handle, "                },\n");
        $fwrite(file_handle, "                options: {\n");
        $fwrite(file_handle, "                    responsive: true,\n");
        $fwrite(file_handle, "                    plugins: {\n");
        $fwrite(file_handle, "                        legend: { display: true, position: 'top' },\n");
        $fwrite(file_handle, "                        title: { display: false }\n");
        $fwrite(file_handle, "                    },\n");
        $fwrite(file_handle, "                    scales: {\n");
        $fwrite(file_handle, "                        y: {\n");
        $fwrite(file_handle, "                            beginAtZero: false,\n");
        $fwrite(file_handle, "                            title: { display: true, text: 'Temperatura (°C)' }\n");
        $fwrite(file_handle, "                        },\n");
        $fwrite(file_handle, "                        x: {\n");
        $fwrite(file_handle, "                            title: { display: true, text: 'Tiempo (ms)' }\n");
        $fwrite(file_handle, "                        }\n");
        $fwrite(file_handle, "                    }\n");
        $fwrite(file_handle, "                }\n");
        $fwrite(file_handle, "            });\n");
        $fwrite(file_handle, "        </script>\n");
        
        // Footer
        $fwrite(file_handle, "        <div class='footer'>\n");
        $fwrite(file_handle, "            <p><strong>Lab 4 - EL3313 Arquitectura de Computadoras</strong></p>\n");
        $fwrite(file_handle, "            <p>Instituto Tecnológico de Costa Rica</p>\n");
        $fwrite(file_handle, "            <p>Generado automáticamente por testbench - Diciembre 2024</p>\n");
        $fwrite(file_handle, "        </div>\n");
        $fwrite(file_handle, "    </div>\n");
        $fwrite(file_handle, "</body>\n");
        $fwrite(file_handle, "</html>\n");
        
        $fclose(file_handle);
    endtask
    
    //==========================================================================
    // Test Sequence
    //==========================================================================
    initial begin
        $display("╔══════════════════════════════════════════════════════════════════╗");
        $display("║                                                                  ║");
        $display("║       🌡️  SISTEMA LECTOR DE TEMPERATURA - DEMOSTRACIÓN  🌡️       ║");
        $display("║                                                                  ║");
        $display("║  Lab 4 - EL3313 Arquitectura de Computadoras                    ║");
        $display("║  Instituto Tecnológico de Costa Rica                            ║");
        $display("║                                                                  ║");
        $display("║  Equipo: Sharon, Steven, Diego, Gabriel                         ║");
        $display("║                                                                  ║");
        $display("╚══════════════════════════════════════════════════════════════════╝");
        $display("");
        $display("📋 Configuración del Sistema:");
        $display("   • Procesador: rv32i_core (RISC-V 32-bit)");
        $display("   • Sensor: temp_sensor_xadc (modo SIMULATION)");
        $display("   • Frecuencia: 10 MHz");
        $display("   • Mapa de memoria: 0x2008 (Display), 0x2030 (Temp Ctrl), 0x2034 (Temp Data)");
        $display("");
        $display("🚀 Iniciando simulación...");
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
        
        $display("✅ Reset liberado en t=%0t ns", $time);
        $display("");
        
        // Wait for initialization
        #1000;
        
        $display("🎯 Sistema inicializado, comenzando monitoreo...");
        $display("");
        
        // Run simulation for enough time to collect good data
        #20000000;  // 20ms - should get ~40 temperature samples
        
        $display("");
        $display("╔══════════════════════════════════════════════════════════════════╗");
        $display("║                  📊 RESUMEN DE SIMULACIÓN                        ║");
        $display("╚══════════════════════════════════════════════════════════════════╝");
        $display("");
        $display("✅ Simulación completada exitosamente");
        $display("   • Tiempo total: %.2f ms", real'($time) / 1_000_000.0);
        $display("   • Lecturas de temperatura: %0d", total_temp_readings);
        $display("   • Instrucciones ejecutadas: %0d", total_instructions);
        $display("   • Escrituras a TEMP_CTRL: %0d", temp_ctrl_writes);
        $display("   • Lecturas de TEMP_DATA: %0d", temp_data_reads);
        $display("   • Expiraciones de timer: %0d", timer_expirations);
        $display("   • Accesos a memoria (R/W): %0d / %0d", mem_reads, mem_writes);
        $display("");
        
        if (samples.size() > 0) begin
            temp_sample_t first_sample, last_sample;
            first_sample = samples[0];
            last_sample = samples[samples.size()-1];
            $display("🌡️  Rango de temperatura:");
            $display("   • Primera lectura: %.1f °C", first_sample.temp_celsius);
            $display("   • Última lectura: %.1f °C", last_sample.temp_celsius);
            $display("   • Delta: %.1f °C", last_sample.temp_celsius - first_sample.temp_celsius);
        end
        
        $display("");
        $display("📄 Generando reporte HTML...");
        generate_html_report();
        $display("✅ Reporte generado: temperature_report.html");
        $display("");
        $display("╔══════════════════════════════════════════════════════════════════╗");
        $display("║  🎉 ¡DEMOSTRACIÓN COMPLETADA EXITOSAMENTE!                      ║");
        $display("║                                                                  ║");
        $display("║  Abre 'temperature_report.html' para ver el reporte visual      ║");
        $display("╚══════════════════════════════════════════════════════════════════╝");
        
        $finish;
    end
    
    //==========================================================================
    // Timeout watchdog
    //==========================================================================
    initial begin
        #50000000;  // 50ms timeout
        $display("⚠️  Advertencia: Tiempo máximo de simulación alcanzado");
        $display("    Generando reporte con los datos recolectados...");
        generate_html_report();
        $finish;
    end

endmodule
