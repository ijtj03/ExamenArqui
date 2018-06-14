//cache finite state machine
import cache_definitions_pkg::*;
module dm_cache_fsm(
                     input   bit                clk, //clock
                     input   bit             resetn, //reset active low
                     input   cpu_req_t      cpu_req, //CPU request input (CPU->cache)
                     input   mem_data_t    mem_data, //memory response (memory->cache)
                     output  mem_req_t      mem_req, //memory request (cache->memory)
                     output  cpu_result_t   cpu_res  //cache result (cache->CPU)
                   );
   timeunit 1ns;
   timeprecision 1ps;
   //write clock
   typedef enum bit [1:0] { IDLE       = 2'd0, 
                            CMP_TAG    = 2'd1,
                            ALLOCATE   = 2'd2, 
                            WRITE_BACK = 2'd3
                          } cache_state_t;
   //FSM state registers
   cache_state_t vstate, rstate;
   //interface signals to tag memory
   cache_tag_t tag_read;  //tag read result
   cache_tag_t tag_write; //tag write data
   cache_req_t tag_req;   //tag request
   
   //interface signals to cache data memory
   cache_data_t  data_read; //cache line read data
   cache_data_t data_write; //cache line write data
   cache_req_t    data_req; //data req
   
   //temporary variable for cache controller result
   cpu_result_t v_cpu_res;
   
   //temporary variable for memory controller request
   mem_req_t    v_mem_req;
   
   assign mem_req = v_mem_req; //connect to output ports
   assign cpu_res = v_cpu_res;

   always_comb begin
      //default values for all signals
      //no state change by default
      vstate = rstate;
      
      v_cpu_res = '{0, 0}; 
      tag_write = '{0, 0, 0};
      
      //read tag by default
      tag_req.we = '0;
      
      //direct map index for tag
      tag_req.index = cpu_req.addr[13:4];
      
      //read current cache line by default
      data_req.we = '0;
      
      //direct map index for cache data
      data_req.index = cpu_req.addr[13:4];
      
      //modify correct word (32-bit) based on address
      data_write = data_read;

      //-------- PREGUNTA 4----------------------------
      // por que se utilizan los bits addr[3:2]
      // para offset en el cache block?
      //-----------------------------------------------

      //-------- PREGUNTA 5-----------------------------
      // por que NO se utilizan los bits addr[1:0]
      // para offset en el cache block? que implica esto
      // respecto al alineamiento
      //------------------------------------------------

      case(cpu_req.addr[3:2])
         2'b00:data_write[31:0] = cpu_req.data;
         2'b01:data_write[63:32] = cpu_req.data;
         2'b10:data_write[95:64] = cpu_req.data;
         2'b11:data_write[127:96] = cpu_req.data;
      endcase

      //read out correct word(32-bit) from cache (to CPU)
      //------- PREGUNTA 6 ----------------------------------
      // Como se modifica este codigo para direccionar usando 
      // palabras de 64 bits, como afecta los valores de TAG
      // e index
      //-----------------------------------------------------
      case(cpu_req.addr[3:2])
         2'b00:v_cpu_res.data = data_read[31:0];
         2'b01:v_cpu_res.data = data_read[63:32];
         2'b10:v_cpu_res.data = data_read[95:64];
         2'b11:v_cpu_res.data = data_read[127:96];
      endcase

      //memory request address (sampled from CPU request)
      v_mem_req.addr = cpu_req.addr;
      //memory request data (used in write)
      v_mem_req.data = data_read;
      v_mem_req.rw = '0;


      //------------------------------------Cache FSM-------------------------
      case(rstate)
      //IDLE state
         IDLE : begin
            //If there is a CPU request, then compare cache tag
            if (cpu_req.valid) begin
               vstate = CMP_TAG;
            end
         end
      //----------------PREGUNTA 7-------------------------------------------------
      // Segun la teoria explique que sucede en este estado del controlador
      // Explique:
      //   a- Como se determina que hay un HIT, y como se determina que hay un MISS
      //   b- Que tipos de Misses existen en la implementacion (Justifique)    
      //---------------------------------------------------------------------------
      //CMP_TAG state
      CMP_TAG : begin
         //cache hit (tag match and cache entry is valid)
         if (cpu_req.addr[TAG_MSB:TAG_LSB] == tag_read.tag && tag_read.valid) begin
            v_cpu_res.ready = '1;
            //write hit
            if (cpu_req.rw) begin
               //read/modify cache line
               tag_req.we = '1; data_req.we = '1;
               //no change in tag
               tag_write.tag = tag_read.tag;
               tag_write.valid = '1;
               //cache line is dirty
               tag_write.dirty = '1;
            end
            //transaction is finished
            vstate = IDLE;
         end
         else begin //cache miss
            //generate new tag
            tag_req.we = '1;
            tag_write.valid = '1;
            //new tag
            tag_write.tag = cpu_req.addr[TAG_MSB:TAG_LSB];
            //cache line is dirty if write
            tag_write.dirty = cpu_req.rw;
            //generate memory request on miss
            v_mem_req.valid = '1;
            //compulsory miss or miss with clean block
            
            if (tag_read.valid == 1'b0 || tag_read.dirty == 1'b0) begin
               //wait till a new block is ALLOCATED
               vstate = ALLOCATE;
            end   
            else begin
               //miss with dirty line
               //write back address
               v_mem_req.addr = {tag_read.tag, cpu_req.addr[TAG_LSB-1:0]};
               v_mem_req.rw = '1;
               //wait till write is completed
               vstate = WRITE_BACK;
            end
         end
      end
  
            //wait for allocating a new cache line
      ALLOCATE: begin
         //memory controller has responded
         if (mem_data.ready) begin
            //re-compare tag for write miss (need modify correct word)
            vstate = CMP_TAG;
            data_write = mem_data.data;
            //update cache line data
            data_req.we = '1;
         end
      end
      
      //wait for writing back dirty cache line
      WRITE_BACK : begin
         //write back is completed
         if (mem_data.ready) begin
            //issue new memory request (allocating a new line)
            v_mem_req.valid = '1;
            v_mem_req.rw = '0;
            vstate = ALLOCATE;
         end
      end
      //-------------Pregunta Extra--------------    
      // Extra points (5) Porque no hay "default"
      //-----------------------------------------      
      endcase
   end
   always_ff @(posedge(clk)) begin
      if (!resetn) begin
         rstate <= IDLE; //reset to IDLE state
      end
      else begin
         rstate <= vstate;
      end
   end
   
   //connect cache tag/data memory
   dm_cache_tag ctag(.*);
   dm_cache_data cdata(.*);
endmodule