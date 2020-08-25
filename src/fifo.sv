/**
 * File: fifo.sv
 * Description: Simple FIFO module
 * Author: Anderson Ignacio da Silva <aignacio@aignacio.com>
 *
 * MIT License
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */
module fifo # (
  parameter SLOTS = 2,
  parameter WIDTH = 8
)(
  input                     clk,
  input                     arst,
  input                     write_i,
  input                     read_i,
  input         [WIDTH-1:0] data_i,
  output  logic [WIDTH-1:0] data_o,
  output  logic             error_o,
  output  logic             full_o,
  output  logic             empty_o
);

  logic   [SLOTS-1:0] [WIDTH-1:0] fifo;
  logic   [$clog2(SLOTS):0]       write_ptr;
  logic   [$clog2(SLOTS):0]       read_ptr;
  logic   [$clog2(SLOTS):0]       next_write_ptr;
  logic   [$clog2(SLOTS):0]       next_read_ptr;
  logic   [$clog2(SLOTS):0]       fifo_ocup;

  always_comb begin
    next_read_ptr = read_ptr;
    next_write_ptr = write_ptr;

    data_o = fifo[read_ptr[$clog2(SLOTS)-1:0]];

    empty_o = (write_ptr == read_ptr);
    full_o =  (write_ptr[$clog2(SLOTS)-1:0] == read_ptr[$clog2(SLOTS)-1:0]) &&
              (write_ptr[$clog2(SLOTS)] != read_ptr[$clog2(SLOTS)]);

    if (write_i && ~full_o)
      next_write_ptr = write_ptr + 'd1;

    if (read_i && ~empty_o)
      next_read_ptr = read_ptr + 'd1;

    error_o = (write_i && full_o) || (read_i && empty_o);
    fifo_ocup = write_ptr - read_ptr;
  end

  always_ff @ (posedge clk or posedge arst) begin
    if (arst) begin
      write_ptr <= '0;
      read_ptr <= '0;
      fifo <= '0;
    end
    else begin
      write_ptr <= next_write_ptr;
      read_ptr <= next_read_ptr;
      fifo[write_ptr[$clog2(SLOTS)-1:0]] <= data_i;
    end
  end

`ifndef NO_ASSERTIONS
  initial begin
    min_fifo_size : assert (SLOTS >= 2)
    else $error("FIFO size of SLOTS defined is illegal!");
  end

  illegal_occupancy : assert property (
    @(posedge clk) disable iff (arst)
    fifo_ocup <= SLOTS
  ) else $error("Illegal FIFO occupancy!");

`endif

endmodule
