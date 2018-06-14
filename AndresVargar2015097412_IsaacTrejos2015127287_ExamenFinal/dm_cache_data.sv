//cache: data memory, single port, 1024 blocks
import cache_definitions_pkg::*;

module dm_cache_data(input bit clk,
                     input bit resetn,   
                     input  cache_req_t     data_req, //data request/command, e.g. RW, valid
                     input  cache_data_t  data_write, //write port (128-bit line)
                     output cache_data_t   data_read  //read port
                    ); 
   timeunit 1ns;
   timeprecision 1ps;

   cache_data_t data_mem[1024];
   //memory initialisation

   assign data_read = data_mem[data_req.index];

   always_ff @(posedge clk  or negedge resetn) begin
      //reset low
      if(!resetn) begin
         foreach(data_mem[i]) begin
            data_mem[i] <= '0;
         end
      end
      else begin
         //if request is write enable write the memmory
         if (data_req.we) begin
            data_mem[data_req.index] <= data_write;
         end   
      end
   end
endmodule