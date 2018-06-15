package cache_definitions_pkg;
    
    //Cache definitions

    //-------------PREGUNTA 1-------------------
    // Que implica usar  estos valores para
    // el tag, cuantos bits de tag son usados,
    // cuantos bits quedan para index y
    // block offset, justifique mediante calculos 
    // que estos valores son correctos
    //------------------------------------------
    
    parameter int TAG_MSB = 31; //tag msb
    parameter int TAG_LSB = 14; //tag lsb
    
    //structure for cache tag
    typedef struct packed {
        bit valid; //valid bit
        bit dirty; //dirty bit
        bit [TAG_MSB:TAG_LSB]tag; //tag bits
    } cache_tag_t;
    
    //-----------PREGUNTA 2--------------------------------
    // Cuantos sets pueden direccionar con 10 bits de index
    //-----------------------------------------------------
    //structure for cache memory request
    typedef struct packed {
        bit [9:0]index; //10-bit index
        bit we; //write enable
    } cache_req_t;
    
    //-----------PREGUNTA 3-----------------------------------
    //Cuantas palabras de 32 bits pueden ser encontradas
    //en el block/line cuantos bits son necesarios para offset
    //--------------------------------------------------------
    //128-bit cache line data
    typedef bit [127:0] cache_data_t;
    // -------------------------------------------
    // CPU - cache controller interface definition
    // -------------------------------------------
    //CPU -> cache controller
    typedef struct packed {
        bit [31:0] addr; //request addr
        bit [31:0] data; //request data
        bit rw;          //operation type : 0 = read, 1 = write
        bit valid;       //valid
    } cpu_req_t;
    
    //cache controller -> CPU
    typedef struct packed {
        bit [31:0]data; //32-bit data
        bit ready; //result is ready
    } cpu_result_t;
    
    // ------------------------------------
    // cache controller - memory interface
    // ------------------------------------

    // cache controller -> memory 
    typedef struct packed {
        bit [31:0] addr;  //request byte addr
        bit [127:0] data; //request data
        bit rw;           //operation type : 0 = read, 1 = write
        bit valid;        //valid
    } mem_req_t;

    // memory controller response (memory -> cache controller)
    typedef struct packed {
        cache_data_t  data; //128-bit read back data
        bit          ready; //data is ready
    } mem_data_t;
endpackage

//El tipo de protocolo que utiliza es el AXI4 ya que utiliza un
//handshake de validacion cuando el dato esta listo y cuando el
//sistema que lo recibe esta listo para recibirlo ademas de manejar,
//una operacion de escrituro o lectura, un bus de direccion y finalmente
//un bus de datos de: 
//CPU -> cache controller(32 bits) 
//cache controller -> memory (128 bits)