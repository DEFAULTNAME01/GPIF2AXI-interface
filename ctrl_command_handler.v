//////////////////////////////////////////////////////////////////////////////////
// Company: THU
// Engineer: Lianghao
// 
// Create Date: 2025/06/18 15:14:56
// Design Name: 
// Module Name: ctrl_command_handler
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module ctrl_command_handler (
    input  wire        inner_clk,
    input  wire        rst_n,
    input wire buffer_clk,

    // AXI4-Stream 输入接口（控制命令）
    input  wire [31:0] ctrl_tdata,
    input  wire        ctrl_tvalid,
    input  wire        ctrl_tlast,
    output wire        ctrl_tready,

    // AXI4-Stream 输出接口（处理响应）
    output wire  [31:0] resp_tdata,
    output wire         resp_tvalid,
    output wire         resp_tlast,
    input  wire        resp_tready
);

        //输入（从 io 到 handler）
        wire [31:0] in_data;
        wire        in_valid;
        wire        in_last;
        wire        in_ready;
		//输出（handler 到 ctrl_rx ）
		wire [31:0] out_data;
    	wire        out_valid;
    	wire        out_last;
    	wire        out_ready;

  reg [31:0] internal_data;
reg        internal_valid;
reg        internal_last;

reg [31:0] out_data_reg;
reg        out_valid_reg;
reg        out_last_reg;

// 输出 AXIS 连接
assign out_data  = out_data_reg;
assign out_valid = out_valid_reg;
assign out_last  = out_last_reg;
assign in_ready  = !internal_valid || (internal_valid && out_ready);

// 处理逻辑主FSM
always @(posedge inner_clk or negedge rst_n) begin
    if (!rst_n) begin
        internal_data  <= 0;
        internal_valid <= 0;
        internal_last  <= 0;
        out_data_reg   <= 0;
        out_valid_reg  <= 0;
        out_last_reg   <= 0;
    end else begin
        // 接收输入数据
        if (in_valid && in_ready) begin
            internal_data  <= in_data;
            internal_valid <= 1'b1;
            internal_last  <= in_last;
        end

        // 输出阶段（可插入多拍运算）
        if (internal_valid && out_ready) begin
            // 示例：加 1 操作
            out_data_reg   <= internal_data + 1;
            out_valid_reg  <= 1'b1;
            out_last_reg   <= internal_last;
            internal_valid <= 1'b0;  // 数据已使用，清除
        end else if (out_valid_reg && out_ready) begin
            out_valid_reg <= 1'b0;
        end
    end
end

// ////////////////////////////////////////////////////////////////////
   
    // CTRL path   
    wire wr_rst_busy_ctrl_tx, rd_rst_busy_ctrl_tx;
    data_fifo_in data_fifo_ctrl_in(
    .wr_rst_busy(wr_rst_busy_ctrl_tx),    // 新增
    .rd_rst_busy(rd_rst_busy_ctrl_tx),    // 新增
    .m_aclk(inner_clk),
    .s_aclk(buffer_clk),
    
    .s_aresetn(~rst_n),
    .s_axis_tvalid(ctrl_tvalid),
    .s_axis_tready(ctrl_tready),
    .s_axis_tdata(ctrl_tdata),
    .s_axis_tlast(ctrl_tlast),
    
    
    .m_axis_tvalid(in_valid),
    .m_axis_tready(in_ready),
    .m_axis_tdata(in_data),
    .m_axis_tlast(in_last)
    
);


   // ////////////////////////////////////////////////////////////////////
   // RESP path
    wire wr_rst_busy_ctrl_rx, rd_rst_busy_ctrl_rx;
    data_fifo_in data_fifo_handel_out(
        .wr_rst_busy(wr_rst_busy_ctrl_rx),    // 新增
        .rd_rst_busy(rd_rst_busy_ctrl_rx),    // 新增
        .m_aclk(buffer_clk),
        .s_aclk(inner_clk),
        .s_aresetn(~rst_n),
        
        
        .s_axis_tvalid(out_valid),
        .s_axis_tready(out_ready),
        .s_axis_tdata(out_data),
        .s_axis_tlast(out_last),
        
        .m_axis_tvalid(resp_tvalid),
        .m_axis_tready(resp_tready),
        .m_axis_tdata(resp_tdata),
        .m_axis_tlast(resp_tlast)
        
        
    );



endmodule
