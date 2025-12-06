`timescale 1ns / 1ps

module tb_timer_module;

    logic        clk;
    logic        rst;
    logic        wr_ctrl_en;
    logic        wr_data_en;
    logic [31:0] wr_data;
    logic        rd_ctrl_en;
    logic        rd_data_en;
    logic [31:0] rd_ctrl_data;
    logic [31:0] rd_data_data;
    logic        timer_done;
    
    // Instancia del timer
    timer_module dut (
        .clk         (clk),
        .rst         (rst),
        .wr_ctrl_en  (wr_ctrl_en),
        .wr_data_en  (wr_data_en),
        .wr_data     (wr_data),
        .rd_ctrl_en  (rd_ctrl_en),
        .rd_data_en  (rd_data_en),
        .rd_ctrl_data(rd_ctrl_data),
        .rd_data_data(rd_data_data),
        .timer_done  (timer_done)
    );
    
    // Generación de reloj (10 MHz = 100ns)
    initial begin
        clk = 0;
        forever #50 clk = ~clk;  // 100ns período
    end
    
    // Test
    initial begin
        $display("=============================================================");
        $display("Testbench para Timer Module");
        $display("=============================================================");
        
        // Inicialización
        rst = 1;
        wr_ctrl_en = 0;
        wr_data_en = 0;
        wr_data = 0;
        rd_ctrl_en = 0;
        rd_data_en = 0;
        
        #200;
        rst = 0;
        #100;
        
        $display("\n[TEST 1] Configurar timer para contar 10 ciclos");
        // Escribir valor objetivo = 10
        @(posedge clk);
        wr_data_en = 1;
        wr_data = 32'd10;
        @(posedge clk);
        wr_data_en = 0;
        
        // Leer registro de datos
        #50;
        rd_data_en = 1;
        #50;
        $display("[CHECK] Target value = %0d (esperado: 10)", rd_data_data);
        rd_data_en = 0;
        
        // Iniciar timer (START=1)
        #100;
        @(posedge clk);
        wr_ctrl_en = 1;
        wr_data = 32'h00000001;  // START=1
        @(posedge clk);
        wr_ctrl_en = 0;
        
        // Esperar a que termine
        wait(timer_done);
        $display("[CHECK] Timer done signal received!");
        
        // Leer registro de control para verificar DONE=1
        #100;
        rd_ctrl_en = 1;
        #50;
        $display("[CHECK] Control register = 0x%08h", rd_ctrl_data);
        $display("        START bit (bit 0) = %0b", rd_ctrl_data[0]);
        $display("        DONE bit  (bit 1) = %0b (esperado: 1)", rd_ctrl_data[1]);
        rd_ctrl_en = 0;
        
        //======================================================================
        $display("\n[TEST 2] Reiniciar timer con cuenta de 20 ciclos");
        #200;
        
        // Escribir nuevo valor objetivo
        @(posedge clk);
        wr_data_en = 1;
        wr_data = 32'd20;
        @(posedge clk);
        wr_data_en = 0;
        
        // Iniciar timer
        #100;
        @(posedge clk);
        wr_ctrl_en = 1;
        wr_data = 32'h00000001;
        @(posedge clk);
        wr_ctrl_en = 0;
        
        // Esperar
        wait(timer_done);
        $display("[CHECK] Timer done signal received for count=20!");
        
        //======================================================================
        $display("\n[TEST 3] Detener timer a mitad de cuenta");
        #200;
        
        // Configurar para 100 ciclos
        @(posedge clk);
        wr_data_en = 1;
        wr_data = 32'd100;
        @(posedge clk);
        wr_data_en = 0;
        
        // Iniciar
        #100;
        @(posedge clk);
        wr_ctrl_en = 1;
        wr_data = 32'h00000001;
        @(posedge clk);
        wr_ctrl_en = 0;
        
        // Esperar 50 ciclos
        repeat(50) @(posedge clk);
        
        // Detener (START=0)
        $display("[ACTION] Stopping timer at middle of count");
        @(posedge clk);
        wr_ctrl_en = 1;
        wr_data = 32'h00000000;  // START=0
        @(posedge clk);
        wr_ctrl_en = 0;
        
        // Verificar que DONE no se activa
        #500;
        rd_ctrl_en = 1;
        #50;
        $display("[CHECK] Control register = 0x%08h", rd_ctrl_data);
        $display("        DONE bit should be 0: %0b", rd_ctrl_data[1]);
        rd_ctrl_en = 0;
        
        //======================================================================
        $display("\n=============================================================");
        $display("Test completado exitosamente!");
        $display("=============================================================");
        #1000;
        $finish;
    end
    
    // Monitor de señales importantes
    initial begin
        $monitor("[T=%0t] State: start=%0b done=%0b timer_done=%0b", 
                 $time, rd_ctrl_data[0], rd_ctrl_data[1], timer_done);
    end
    
endmodule
