//cache: tag memory, single port, 1024 blocks
import cache_definitions_pkg::*;
module dm_cache_tag(
                     input  bit                  clk, //write clock
                     input  bit               resetn,
                     input  cache_req_t      tag_req, //tag request/command, e.g. RW, valid
                     input  cache_tag_t    tag_write, //write port
                     output cache_tag_t     tag_read  //read port
                   );
   timeunit 1ns; 
   timeprecision 1ps;
   cache_tag_t tag_mem[1024];

   always_ff @(posedge clk or negedge resetn) begin
      if(!resetn) begin
         foreach(tag_mem[i]) begin
            tag_mem[i] <= '0;
         end
      end
      else begin
         if (tag_req.we) begin
            tag_mem[tag_req.index] <= tag_write;
         end
      end   
   end

   // continous assignments
   assign tag_read = tag_mem[tag_req.index];
endmodule