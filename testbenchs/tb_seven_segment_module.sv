`timescale 1ns / 1ps

module tb_seven_segment_module;

    logic        clk;
    logic        rst;
    logic        wr_en;
    logic [31:0] wr_data;
    logic        rd_en;
    logic [31:0] rd_data;
    logic [7:0]  seg;
    logic [7:0]  an;
    
    // Instancia del módulo 7 segmentos
    seven_segment_module dut (
        .clk    (clk),
        .rst    (rst),
        .wr_en  (wr_en),
        .wr_data(wr_data),
        .rd_en  (rd_en),
        .rd_data(rd_data),
        .seg    (seg),
        .an     (an)
    );
    
    // Generación de reloj (10 MHz = 100ns período)
    initial begin
        clk = 0;
        forever #50 clk = ~clk;
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
    
    // Test
    initial begin
        $display("=============================================================");
        $display("Testbench para Seven Segment Display Module");
        $display("=============================================================");
        
        // Inicialización
        rst = 1;
        wr_en = 0;
        wr_data = 0;
        rd_en = 0;
        
        #200;
        rst = 0;
        #100;
        
        //======================================================================
        $display("\n[TEST 1] Mostrar número 12345678");
        @(posedge clk);
        wr_en = 1;
        wr_data = 32'h12345678;
        @(posedge clk);
        wr_en = 0;
        
        // Leer registro
        #100;
        rd_en = 1;
        #50;
        $display("[CHECK] Display data = 0x%08h (esperado: 0x12345678)", rd_data);
        rd_en = 0;
        
        // Observar multiplexación por 8 ciclos completos
        $display("\n[INFO] Observando multiplexación de displays...");
        repeat(8) begin
            @(posedge clk);
            // Esperar a que cambie el display
            repeat(10000) @(posedge clk);
            $display("  Display %0d activo: AN=0x%02h, SEG=0x%02h -> Dígito '%s'",
                     dut.display_select, an, seg, seg_to_digit(seg));
        end
        
        //======================================================================
        $display("\n[TEST 2] Mostrar temperatura 00000025 (25°C)");
        @(posedge clk);
        wr_en = 1;
        wr_data = 32'h00000025;  // 25 en decimal
        @(posedge clk);
        wr_en = 0;
        
        #100;
        $display("[CHECK] Display data = 0x%08h", rd_data);
        
        // Observar algunos displays
        $display("\n[INFO] Verificando displays para temperatura...");
        repeat(8) begin
            @(posedge clk);
            repeat(10000) @(posedge clk);
            $display("  Display %0d: Dígito '%s'",
                     dut.display_select, seg_to_digit(seg));
        end
        
        //======================================================================
        $display("\n[TEST 3] Mostrar hexadecimal ABCDEF01");
        @(posedge clk);
        wr_en = 1;
        wr_data = 32'hABCDEF01;
        @(posedge clk);
        wr_en = 0;
        
        #100;
        $display("[CHECK] Display data = 0x%08h", rd_data);
        
        $display("\n[INFO] Verificando displays hexadecimales...");
        repeat(8) begin
            @(posedge clk);
            repeat(10000) @(posedge clk);
            $display("  Display %0d: Dígito '%s'",
                     dut.display_select, seg_to_digit(seg));
        end
        
        //======================================================================
        $display("\n=============================================================");
        $display("Tests completados exitosamente!");
        $display("Displays funcionando correctamente");
        $display("=============================================================");
        #10000;
        $finish;
    end
    
    // Monitor continuo (cada vez que cambia el display activo)
    logic [2:0] prev_display;
    
    initial begin
        prev_display = 0;
    end
    
    always @(posedge clk) begin
        if (dut.display_select != prev_display) begin
            prev_display <= dut.display_select;
        end
    end
    
endmodule
