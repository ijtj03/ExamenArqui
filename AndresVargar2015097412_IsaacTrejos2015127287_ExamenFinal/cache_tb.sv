import cache_definitions_pkg::*;

module cache_tb();
   
   timeunit 1ns;
   timeprecision 1ps;

   logic                 clk;
   logic              resetn;
   cpu_req_t         cpu_req;
   mem_data_t       mem_data;
   mem_req_t         mem_req;
   cpu_result_t      cpu_res;

   // associative array / dictionary mimicing a physical memory
   cache_data_t   main_memory[bit[31:0]];

   // instance of the cache controller
   dm_cache_fsm m_dm_cache_fsm (
                                    clk,  //clock
                                  resetn, //reset active low
                                 cpu_req, //CPU request input (CPU->cache)
                                mem_data, //memory response (memory->cache)
                                 mem_req, //memory request (cache->memory)
                                 cpu_res  //cache result (cache->CPU)
                              );
   
   //Free running clock                           
   initial begin
      clk_gen();
   end
   
   //Memory request from cache processing
   initial begin
      process_mem_read_req_from_cache();
   end
   //-------------------------Respuesta 9------------------------------------
   //En el waveform se aprecia solo una transicion a memoria debido
   //a que en el codio se realizan dos request pero a la misma direccion
   //con el mismo tag por lo que en el segundo request a cache sucede un 
   //cache hit y no es nesesario requerir otra consulta a memoria, basicamente
   //es aplicar el proposito del uso de la cache. Por el principio
   //temporal el mismo dato puede ser accesado en un periodo corto de tiempo
   //y por este motivo es que se queda almacenado en cache para que su acceso
   //sea mas rapido
   // MAIN test
   initial begin
      main_memory_init();
      reset(50, 100);
      #100;//wait reset
      cpu_read_request(32'h0000_0FF0);//cold miss --> requiere acceso a memoria
      #500;
      cpu_read_request(32'h0000_0FF0);//segundo request no requiere acceso a memoria
      #1000;// wait 10 cycles to finish the test
      $finish;
   end

   // This is for setting some values into the "main memory"
   task automatic main_memory_init();
   //-----------PREGUNTA 8-----------------------------------
   // En que set deberian estar las direccion usada,
   // realice los calculos y muestre en el waveform
   //-------------------------------------------------------- 
      main_memory[32'h0000_0FF0] = 128'h1234_ABCD_FFFF_DEAD;
   endtask

   // this is the clock generation
   task automatic clk_gen();

      clk = 0;
      forever begin
         #50 clk = ~clk;
      end
   endtask
   
   // this is the reset of the system
   task  automatic reset(int reset_start = 0, int reset_duration =  10);
      
      #reset_start;  
      resetn = 1'b0; 
      #reset_duration;
      resetn = 1'b1;
   
   endtask
  
   // this task mimics a CPU addr request for read
   task automatic cpu_read_request(input bit [31:0] addr);
      cpu_req.addr   = addr; //request addr
      cpu_req.data   =    0; //read operation
      cpu_req.rw     =    0; //operation type : 0 = read, 1 = write
      cpu_req.valid  =    1;
      repeat(2) @(posedge clk);
      cpu_req.valid  =    0;
   endtask


   // This task process mem read request
   task automatic process_mem_read_req_from_cache();
      forever begin
         @(mem_req.addr);
         wait(mem_req.valid);
         // if there is valid data in main memory
         if(main_memory.exists(mem_req.addr)) begin
            $display("Cache requested address = %h found in memory data = %0h", mem_req.addr, main_memory[mem_req.addr]);
            mem_data.data  = main_memory[mem_req.addr];
            mem_data.ready = 1;
            repeat(2) @(posedge clk);
            mem_data.ready = 0; 
         end
         else begin
            $warning("Address = %h not found in memory returning zeroes", mem_req.addr);
            mem_data.data  = 0;
            mem_data.ready = 1;
            repeat(2) @(posedge clk);
            mem_data.ready = 0;
         end      
      end
   endtask
endmodule