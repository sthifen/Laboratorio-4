`timescale 1ns/1ps

module tb_top_fpga;

    // Senales del DUT
    logic        clk_10MHz;  // Usar directamente 10MHz
    logic        btnC;
    logic        btnL, btnR, btnU, btnD;
    logic [15:0] sw;
    wire         SCL, SDA;
    logic        TMP_INT, TMP_CT;
    wire  [15:0] led;
    wire  [7:0]  AN;
    wire  [7:0]  SEG;

    // Pullups para I2C (necesarios en simulación para open-drain)
    assign (weak1, weak0) SCL = 1'b1;
    assign (weak1, weak0) SDA = 1'b1;
    string       log_file_path;
    integer      log_fd;
    bit          log_file_valid;
    int unsigned log_line_budget;

    task automatic log_line(input string message);
        int ferr_code;
        string ferr_msg;
        $display("%s", message);
        if (log_file_valid && (log_fd > 0) && (log_line_budget > 0)) begin
            $fdisplay(log_fd, "%s", message);
            $fflush(log_fd);  // Forzar escritura inmediata al disco
            log_line_budget -= 1;
            ferr_code = $ferror(log_fd, ferr_msg);
            if (ferr_code != 0) begin
                log_file_valid = 1'b0;
                $display("WARNING: logging a archivo deshabilitado por error en descriptor: %s", ferr_msg);
            end else if (log_line_budget == 0) begin
                log_file_valid = 1'b0;
                $display("INFO: limite de lineas de log alcanzado, se cierra el archivo %s", log_file_path);
                $fclose(log_fd);
            end
        end
    endtask

    function string decode_instr(input logic [31:0] pc, input logic [31:0] instr);
        string text;
        logic [6:0] opcode;
        logic [2:0] funct3;
        logic [6:0] funct7;
        logic [4:0] rd;
        logic [4:0] rs1;
        logic [4:0] rs2;
        int signed  imm_i;
        int signed  imm_s;
        int signed  imm_b;
        int signed  imm_j;

        opcode = instr[6:0];
        funct3 = instr[14:12];
        funct7 = instr[31:25];
        rd     = instr[11:7];
        rs1    = instr[19:15];
        rs2    = instr[24:20];
        imm_i  = $signed({{20{instr[31]}}, instr[31:20]});
        imm_s  = $signed({{20{instr[31]}}, instr[31:25], instr[11:7]});
        imm_b  = $signed({{19{instr[31]}}, instr[31], instr[7], instr[30:25], instr[11:8], 1'b0});
        imm_j  = $signed({{11{instr[31]}}, instr[31], instr[19:12], instr[20], instr[30:21], 1'b0});

        unique case (opcode)
            7'b0110111: text = $sformatf("lui x%0d, 0x%05h", rd, instr[31:12]);
            7'b0010111: text = $sformatf("auipc x%0d, 0x%05h", rd, instr[31:12]);
            7'b1101111: text = $sformatf("jal x%0d, 0x%08h", rd, pc + imm_j);
            7'b1100111: text = $sformatf("jalr x%0d, x%0d, %0d", rd, rs1, imm_i);
            7'b1100011: begin
                string br_name;
                case (funct3)
                    3'b000: br_name = "beq";
                    3'b001: br_name = "bne";
                    3'b100: br_name = "blt";
                    3'b101: br_name = "bge";
                    3'b110: br_name = "bltu";
                    3'b111: br_name = "bgeu";
                    default: br_name = "br?";
                endcase
                text = $sformatf("%s x%0d, x%0d, 0x%08h", br_name, rs1, rs2, pc + imm_b);
            end
            7'b0000011: begin
                string load_name;
                case (funct3)
                    3'b010: load_name = "lw";
                    3'b000: load_name = "lb";
                    3'b001: load_name = "lh";
                    3'b100: load_name = "lbu";
                    3'b101: load_name = "lhu";
                    default: load_name = "l?";
                endcase
                text = $sformatf("%s x%0d, %0d(x%0d)", load_name, rd, imm_i, rs1);
            end
            7'b0100011: begin
                string store_name;
                case (funct3)
                    3'b010: store_name = "sw";
                    3'b000: store_name = "sb";
                    3'b001: store_name = "sh";
                    default: store_name = "s?";
                endcase
                text = $sformatf("%s x%0d, %0d(x%0d)", store_name, rs2, imm_s, rs1);
            end
            7'b0010011: begin
                case (funct3)
                    3'b000: text = $sformatf("addi x%0d, x%0d, %0d", rd, rs1, imm_i);
                    3'b010: text = $sformatf("slti x%0d, x%0d, %0d", rd, rs1, imm_i);
                    3'b011: text = $sformatf("sltiu x%0d, x%0d, %0d", rd, rs1, imm_i);
                    3'b100: text = $sformatf("xori x%0d, x%0d, %0d", rd, rs1, imm_i);
                    3'b110: text = $sformatf("ori x%0d, x%0d, %0d", rd, rs1, imm_i);
                    3'b111: text = $sformatf("andi x%0d, x%0d, %0d", rd, rs1, imm_i);
                    3'b001: text = $sformatf("slli x%0d, x%0d, %0d", rd, rs1, instr[24:20]);
                    3'b101: begin
                        if (funct7[5]) begin
                            text = $sformatf("srai x%0d, x%0d, %0d", rd, rs1, instr[24:20]);
                        end else begin
                            text = $sformatf("srli x%0d, x%0d, %0d", rd, rs1, instr[24:20]);
                        end
                    end
                    default: text = "i-type?";
                endcase
            end
            7'b0110011: begin
                case ({funct7, funct3})
                    {7'b0000000, 3'b000}: text = $sformatf("add x%0d, x%0d, x%0d", rd, rs1, rs2);
                    {7'b0100000, 3'b000}: text = $sformatf("sub x%0d, x%0d, x%0d", rd, rs1, rs2);
                    {7'b0000000, 3'b111}: text = $sformatf("and x%0d, x%0d, x%0d", rd, rs1, rs2);
                    {7'b0000000, 3'b110}: text = $sformatf("or x%0d, x%0d, x%0d", rd, rs1, rs2);
                    {7'b0000000, 3'b100}: text = $sformatf("xor x%0d, x%0d, x%0d", rd, rs1, rs2);
                    {7'b0000000, 3'b010}: text = $sformatf("slt x%0d, x%0d, x%0d", rd, rs1, rs2);
                    {7'b0000000, 3'b011}: text = $sformatf("sltu x%0d, x%0d, x%0d", rd, rs1, rs2);
                    {7'b0000000, 3'b001}: text = $sformatf("sll x%0d, x%0d, x%0d", rd, rs1, rs2);
                    {7'b0000000, 3'b101}: text = $sformatf("srl x%0d, x%0d, x%0d", rd, rs1, rs2);
                    {7'b0100000, 3'b101}: text = $sformatf("sra x%0d, x%0d, x%0d", rd, rs1, rs2);
                    default: text = "r-type?";
                endcase
            end
            default: text = $sformatf("instr 0x%08h", instr);
        endcase

        return text;
    endfunction

    task automatic log_register_dump();
        for (int i = 0; i < 32; i += 4) begin
            log_line($sformatf(
                "    x%0d=0x%08h  x%0d=0x%08h  x%0d=0x%08h  x%0d=0x%08h",
                i,   dut.core_inst.regs[i],
                i+1, dut.core_inst.regs[i+1],
                i+2, dut.core_inst.regs[i+2],
                i+3, dut.core_inst.regs[i+3]
            ));
        end
    endtask

    // Instancia del DUT
    // NOTA: El puerto clk_100MHz recibe clk_10MHz porque en simulación
    // bypasseamos el PLL (forzamos clk_sys y clk_locked más abajo)
    top_pcpi_led_fpga dut (
        .clk_100MHz(clk_10MHz),
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

    initial begin : log_file_init
        string override_file;
        string default_log_path;
        int unsigned max_lines;

        log_fd = 0;
        log_file_valid = 1'b0;
        log_line_budget = 0;
        max_lines = 200000;

        // Ruta por defecto relativa a donde Vivado ejecuta la simulación
        // Típicamente: lab4_pcpi/lab4_pcpi.sim/sim_1/behav/xsim/
        default_log_path = "tb_top_fpga_sim.log";

        if ($value$plusargs("logfile=%s", override_file)) begin
            default_log_path = override_file;
        end

        if ($value$plusargs("logmax=%d", max_lines)) begin
            if (max_lines == 0) begin
                log_file_valid = 1'b0;
                $display("INFO: logging a archivo deshabilitado por logmax=0");
            end
        end

        if (max_lines != 0) begin
            log_fd = $fopen(default_log_path, "w");
            if (log_fd > 0) begin
                log_file_path = default_log_path;
                log_file_valid = 1'b1;
                log_line_budget = max_lines;
                $display("INFO: Archivo de log abierto exitosamente: %s (fd=%0d)", log_file_path, log_fd);
                log_line($sformatf("Log de simulacion escrito en %s (max %0d lineas)", log_file_path, log_line_budget));
            end else begin
                log_file_valid = 1'b0;
                $display("WARNING: No se pudo abrir archivo de log '%s'", default_log_path);
                $display("INFO: Continuando sin archivo de log (salida solo en consola)");
            end
        end
    end

    final begin
        if (log_file_valid && (log_fd > 0)) begin
            $fflush(log_fd);
            $fclose(log_fd);
            $display("INFO: Archivo de log cerrado: %s", log_file_path);
        end
    end

    // Bypass del PLL en simulación: forzar clock directamente
    // Esto evita tener que simular el PLL IP completo
    initial begin
        #1;  // Esperar 1ns antes de forzar para evitar race conditions
        force dut.clk_sys = clk_10MHz;
        force dut.clk_locked = 1'b1;
        log_line("[INFO] PLL bypasseado: clk_sys = clk_10MHz, clk_locked = 1");
    end

    // Generador de clock 10MHz (periodo 100ns)
    // Este es el clock del sistema después del PLL
    initial begin
        clk_10MHz = 0;
        forever #50 clk_10MHz = ~clk_10MHz;  // 50ns HIGH + 50ns LOW = 100ns periodo = 10MHz
    end

    // Control de duración de simulación
    int unsigned sim_duration_ns;
    initial begin
        // Por defecto 20ms, configurable con +sim_time=<ns>
        sim_duration_ns = 20_000_000;
        if ($value$plusargs("sim_time=%d", sim_duration_ns)) begin
            $display("[INFO] Duración de simulación configurada: %0d ns", sim_duration_ns);
        end
    end

    // Detector de finalización de programa
    // Si el PC llega a 0xFFFFFFFC o se ejecuta un bucle infinito en una dirección específica
    logic program_finished;
    int   idle_cycles;
    logic [31:0] last_pc;

    initial begin
        program_finished = 1'b0;
        idle_cycles = 0;
        last_pc = 32'h0;
    end

    always @(posedge dut.clk_sys) begin
        if (dut.resetn) begin
            // Detectar PC en dirección de finalización
            if (dut.core_inst.pc == 32'hFFFF_FFFC) begin
                program_finished = 1'b1;
                log_line($sformatf("[%0t] Programa finalizado: PC alcanzó 0xFFFFFFFC", $time));
            end

            // Detectar bucle infinito (PC no cambia por muchos ciclos)
            if (dut.core_inst.pc == last_pc && dut.core_inst.state == dut.core_inst.FETCH) begin
                idle_cycles = idle_cycles + 1;
                if (idle_cycles > 100) begin
                    program_finished = 1'b1;
                    log_line($sformatf("[%0t] Programa parece estar en bucle infinito en PC=0x%08h",
                             $time, dut.core_inst.pc));
                end
            end else begin
                idle_cycles = 0;
            end
            last_pc = dut.core_inst.pc;
        end
    end

    // Estímulos y control principal
    initial begin
        log_line("=== Iniciando simulacion del top-level ===");
        log_line($sformatf("[INFO] Duración máxima: %0d ns (%.2f ms)",
                 sim_duration_ns, sim_duration_ns / 1000000.0));

        // Condiciones iniciales
        btnC = 1;      // Reset activo (activo alto)
        btnL = 0;
        btnR = 0;
        btnU = 0;
        btnD = 0;
        sw = 16'h0000; // Todos los switches apagados
        TMP_INT = 0;
        TMP_CT = 0;

        // Mantener reset por varios ciclos
        repeat(10) @(posedge clk_10MHz);

        // Liberar reset
        btnC = 0;
        log_line($sformatf("[%0t] Reset liberado - Sistema iniciando", $time));

        // Esperar que el sistema se estabilice
        repeat(5) @(posedge clk_10MHz);
        log_line($sformatf("[%0t] Sistema estabilizado - Comenzando ejecución", $time));

        // Esperar hasta que termine el programa o timeout
        fork
            // Timeout
            begin
                #sim_duration_ns;
                log_line($sformatf("\n[%0t] TIMEOUT: Simulación alcanzó duración máxima", $time));
            end

            // Esperar finalización del programa
            begin
                wait(program_finished);
                #1000;  // Esperar 1us más después de detectar finalización
                log_line($sformatf("\n[%0t] Programa detectado como finalizado", $time));
            end
        join_any

        disable fork;  // Cancelar el fork que no terminó

        // Reporte final
        log_line("\n=== Fin de simulacion ===");
        log_line($sformatf("Tiempo de simulación: %0t", $time));
        log_line($sformatf("LEDs = 0x%04h (%016b)", led, led));
        log_line($sformatf("7-seg AN = 0x%02h", AN));
        log_line($sformatf("7-seg SEG = 0x%02h", SEG));
        log_line($sformatf("PC final = 0x%08h", dut.core_inst.pc));
        log_line($sformatf("Estado final = %s", dut.core_inst.state.name()));

        log_line("\nRegistros finales:");
        log_register_dump();

        $finish;
    end

    // Monitor de cambios en LEDs
    always @(led) begin
        log_line($sformatf("[%0t] LEDs cambiaron a: 0x%04h", $time, led));
    end

    // Monitor del estado del procesador
    always @(dut.core_inst.state) begin
        log_line($sformatf("[%0t] Procesador estado: %s", $time, dut.core_inst.state.name()));
    end

    // Monitor del PC
    initial begin
        forever begin
            @(posedge dut.clk_sys);
            if (dut.core_inst.state == dut.core_inst.FETCH) begin
                log_line($sformatf("[%0t] PC = 0x%08h, instr = 0x%08h (%s)",
                    $time, dut.core_inst.pc, dut.instr_data,
                    decode_instr(dut.core_inst.pc, dut.instr_data)));
                log_register_dump();
            end
        end
    end

    // Monitor detallado de los primeros 10 ciclos de clock
    integer cycle_count;
    initial begin
        cycle_count = 0;
        log_line("\n========== ANALISIS DE PRIMEROS 10 CICLOS ==========");

        // Esperar a que salga del reset
        wait(dut.resetn == 1'b1);

        repeat(10) begin
            @(posedge dut.clk_sys);
            cycle_count = cycle_count + 1;

            log_line($sformatf("\n--- Ciclo %0d (tiempo=%0t) ---", cycle_count, $time));
            log_line("  Clock/Reset:");
            log_line($sformatf("    clk_sys=%b, resetn=%b, clk_locked=%b",
                dut.clk_sys, dut.resetn, dut.clk_locked));

            log_line("  Procesador:");
            log_line($sformatf("    state=%s, pc=0x%08h",
                dut.core_inst.state.name(), dut.core_inst.pc));
            log_line($sformatf("    instr_addr=0x%08h, instr_data=0x%08h (%s)",
                dut.instr_addr, dut.instr_data,
                decode_instr(dut.instr_addr, dut.instr_data)));
            log_line($sformatf("    data_req=%b, data_we=%b, data_ready=%b",
                dut.data_req, dut.data_we, dut.data_ready));
            log_line($sformatf("    data_addr=0x%08h, data_wdata=0x%08h, data_rdata=0x%08h",
                dut.data_addr, dut.data_wdata, dut.data_rdata));

            log_line("  Perifericos:");
            log_line($sformatf("    led_reg=0x%04h, sevenseg_reg=0x%08h",
                dut.led_reg, dut.sevenseg_reg));
            log_line($sformatf("    switches_reg=0x%08h", dut.switches_reg));

            log_line("  Bus Estado:");
            log_line($sformatf("    bus_state=%s, response_data=0x%08h",
                dut.bus_state.name(), dut.response_data));

            log_line("  ROM/RAM:");
            log_line($sformatf("    rom_addr=0x%03h, ram_ena=%b, ram_enb=%b",
                dut.rom_addr_word, dut.ram_ena, dut.ram_enb));

            log_line("  Registros del procesador (primeros 8):");
            for (int i = 0; i < 8; i++) begin
                log_line($sformatf("    x%0d=0x%08h", i, dut.core_inst.regs[i]));
            end
        end

        log_line("\n========== FIN DE ANALISIS DE 10 CICLOS ==========\n");
    end

    //==========================================================================
    // MONITORES PARA VERIFICACION DE REQUISITOS DEL INSTRUCTIVO
    //==========================================================================

    // Monitor de accesos a mapa de memoria (ROM 0x0000-0x0FFF, RAM 0x1000-0x1FFF, Periféricos 0x2000+)
    always @(posedge dut.clk_sys) begin
        if (dut.data_req && dut.data_ready) begin
            string region;
            logic [31:0] addr;
            addr = dut.data_addr;

            if (addr >= 32'h0000 && addr < 32'h1000)
                region = "ROM";
            else if (addr >= 32'h1000 && addr < 32'h2000)
                region = "RAM";
            else if (addr >= 32'h2000 && addr < 32'h3000)
                region = "PERIFERICOS";
            else
                region = "FUERA_RANGO";

            if (dut.data_we) begin
                log_line($sformatf("[%0t] [BUS WRITE] %s @ 0x%08h = 0x%08h",
                         $time, region, addr, dut.data_wdata));
            end else begin
                log_line($sformatf("[%0t] [BUS READ]  %s @ 0x%08h => 0x%08h",
                         $time, region, addr, dut.data_rdata));
            end
        end
    end

    // Monitor de accesos específicos a periféricos según mapa de memoria del instructivo
    always @(posedge dut.clk_sys) begin
        if (dut.data_req && dut.data_ready) begin
            case (dut.data_addr)
                32'h0000_2000: begin // Switches/Botones
                    if (!dut.data_we)
                        log_line($sformatf("[%0t] [PERIPH] READ Switches/Botones = 0x%08h",
                                 $time, dut.data_rdata));
                end
                32'h0000_2004: begin // LEDs
                    if (dut.data_we)
                        log_line($sformatf("[%0t] [PERIPH] WRITE LEDs = 0x%04h",
                                 $time, dut.data_wdata[15:0]));
                    else
                        log_line($sformatf("[%0t] [PERIPH] READ LEDs = 0x%04h",
                                 $time, dut.data_rdata[15:0]));
                end
                32'h0000_2008: begin // 7-segment
                    if (dut.data_we)
                        log_line($sformatf("[%0t] [PERIPH] WRITE 7-seg = 0x%08h",
                                 $time, dut.data_wdata));
                end
                32'h0000_2018: begin // Timer Control
                    if (dut.data_we) begin
                        log_line($sformatf("[%0t] [TIMER] WRITE Control = 0x%08h (start=%b, clr_done=%b)",
                                 $time, dut.data_wdata, dut.data_wdata[0], dut.data_wdata[1]));
                    end else begin
                        log_line($sformatf("[%0t] [TIMER] READ Control = 0x%08h (running=%b, done=%b)",
                                 $time, dut.data_rdata, dut.data_rdata[0], dut.data_rdata[1]));
                    end
                end
                32'h0000_201C: begin // Timer Period
                    if (dut.data_we)
                        log_line($sformatf("[%0t] [TIMER] WRITE Period = %0d ciclos (%.2f ms @ 10MHz)",
                                 $time, dut.data_wdata, dut.data_wdata / 10000.0));
                    else
                        log_line($sformatf("[%0t] [TIMER] READ Period = %0d",
                                 $time, dut.data_rdata));
                end
                32'h0000_2030: begin // Temp Sensor Control
                    if (dut.data_we) begin
                        log_line($sformatf("[%0t] [TEMP] WRITE Control = 0x%08h (start=%b, clr_ready=%b)",
                                 $time, dut.data_wdata, dut.data_wdata[0], dut.data_wdata[1]));
                    end else begin
                        log_line($sformatf("[%0t] [TEMP] READ Control = 0x%08h (busy=%b, ready=%b)",
                                 $time, dut.data_rdata, dut.data_rdata[0], dut.data_rdata[1]));
                    end
                end
                32'h0000_2034: begin // Temp Sensor Data
                    if (!dut.data_we) begin
                        int signed temp_value;
                        temp_value = $signed(dut.data_rdata[15:0]);
                        log_line($sformatf("[%0t] [TEMP] READ Data = %0d (%.1f°C)",
                                 $time, temp_value, temp_value / 10.0));
                    end
                end
                default: ;
            endcase
        end
    end

    // Monitor de banderas del timer (start/done)
    logic prev_timer_running, prev_timer_done;
    initial begin
        prev_timer_running = 1'b0;
        prev_timer_done = 1'b0;
        forever begin
            @(posedge dut.clk_sys);
            if (dut.resetn) begin
                // Detectar cambios en running
                if (dut.timer_inst.running && !prev_timer_running) begin
                    log_line($sformatf("[%0t] [TIMER FLAG] Timer iniciado (running=1)", $time));
                end else if (!dut.timer_inst.running && prev_timer_running) begin
                    log_line($sformatf("[%0t] [TIMER FLAG] Timer detenido (running=0)", $time));
                end

                // Detectar cambios en done_flag
                if (dut.timer_inst.done_flag && !prev_timer_done) begin
                    log_line($sformatf("[%0t] [TIMER FLAG] Timer completado (done_flag=1)", $time));
                end else if (!dut.timer_inst.done_flag && prev_timer_done) begin
                    log_line($sformatf("[%0t] [TIMER FLAG] Timer done cleared (done_flag=0)", $time));
                end

                prev_timer_running = dut.timer_inst.running;
                prev_timer_done = dut.timer_inst.done_flag;
            end
        end
    end

    // Monitor de banderas del sensor de temperatura (start/busy/ready)
    logic prev_temp_busy, prev_temp_ready;
    initial begin
        prev_temp_busy = 1'b0;
        prev_temp_ready = 1'b0;
        forever begin
            @(posedge dut.clk_sys);
            if (dut.resetn) begin
                // Detectar cambios en conversion_active (busy)
                if (dut.temp_inst.conversion_active && !prev_temp_busy) begin
                    log_line($sformatf("[%0t] [TEMP FLAG] Sensor ocupado (conversion_active=1)", $time));
                end else if (!dut.temp_inst.conversion_active && prev_temp_busy) begin
                    log_line($sformatf("[%0t] [TEMP FLAG] Sensor disponible (conversion_active=0)", $time));
                end

                // Detectar cambios en data_ready_flag
                if (dut.temp_inst.data_ready_flag && !prev_temp_ready) begin
                    log_line($sformatf("[%0t] [TEMP FLAG] Dato listo (data_ready_flag=1)", $time));
                end else if (!dut.temp_inst.data_ready_flag && prev_temp_ready) begin
                    log_line($sformatf("[%0t] [TEMP FLAG] Ready cleared (data_ready_flag=0)", $time));
                end

                prev_temp_busy = dut.temp_inst.conversion_active;
                prev_temp_ready = dut.temp_inst.data_ready_flag;
            end
        end
    end

    // Monitor de cambios en switches (para verificar selección de período)
    logic [15:0] prev_sw;
    initial begin
        prev_sw = 16'h0000;
        forever begin
            @(sw);
            if (sw != prev_sw) begin
                log_line($sformatf("[%0t] [SWITCHES] Cambio detectado: 0x%04h (SW3..SW0=%b, período seleccionado)",
                         $time, sw, sw[3:0]));
                prev_sw = sw;
            end
        end
    end

    // Monitor de cambios en 7-segment display
    logic [31:0] prev_sevenseg;
    initial begin
        prev_sevenseg = 32'h0;
        forever begin
            @(dut.sevenseg_reg);
            if (dut.sevenseg_reg != prev_sevenseg) begin
                log_line($sformatf("[%0t] [7-SEG] Display actualizado: 0x%08h",
                         $time, dut.sevenseg_reg));
                prev_sevenseg = dut.sevenseg_reg;
            end
        end
    end

    // Generación opcional de VCD para análisis de formas de onda
    initial begin
        if ($test$plusargs("vcd")) begin
            string vcd_file;
            if ($value$plusargs("vcd=%s", vcd_file)) begin
                $dumpfile(vcd_file);
            end else begin
                $dumpfile("tb_top_fpga_wave.vcd");
            end
            $dumpvars(0, tb_top_fpga);
            log_line("[INFO] Generación de VCD habilitada");
        end
    end

    // Resumen de verificación al final
    int unsigned timer_starts, timer_dones, temp_reads, led_changes, display_updates;
    initial begin
        timer_starts = 0;
        timer_dones = 0;
        temp_reads = 0;
        led_changes = 0;
        display_updates = 0;
    end

    always @(posedge dut.clk_sys) begin
        if (dut.resetn && dut.data_req && dut.data_ready && dut.data_we) begin
            case (dut.data_addr)
                32'h0000_2018: if (dut.data_wdata[0]) timer_starts++;
                32'h0000_2004: led_changes++;
                32'h0000_2008: display_updates++;
                32'h0000_2030: if (dut.data_wdata[0]) temp_reads++;
            endcase
        end

        if (dut.timer_inst.done_flag && !prev_timer_done) timer_dones++;
    end

    final begin
        $display("\n========== RESUMEN DE VERIFICACION ==========");
        $display("Timer iniciado:      %0d veces", timer_starts);
        $display("Timer completado:    %0d veces", timer_dones);
        $display("Lecturas temp:       %0d veces", temp_reads);
        $display("Cambios LEDs:        %0d veces", led_changes);
        $display("Actualizaciones 7-seg: %0d veces", display_updates);
        $display("=============================================\n");
    end

endmodule
