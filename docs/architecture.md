# Architecture and protocol

## Scope

This is a small, blocking memory controller intended to demonstrate a complete RTL-to-layout ASIC flow. It is not a DRAM controller: there are no banks, refresh operations, bursts, queues, or external memory signaling. The memory is modeled as eight 32-bit words synthesized from registers in the implemented configuration.

## Interface

| Signal | Direction | Width | Meaning |
|---|---:|---:|---|
| `clk` | input | 1 | Rising-edge clock |
| `rst_n` | input | 1 | Asynchronous active-low controller reset |
| `req_valid` | input | 1 | Indicates a request is present |
| `req_rw` | input | 1 | `0`: read, `1`: write |
| `req_addr` | input | 32 | Byte address |
| `req_wdata` | input | 32 | Write data |
| `resp_ready` | output | 1 | High for the response state cycle |
| `resp_rdata` | output | 32 | Registered read data |

Only one request may be outstanding. There is no input-ready signal, so a requester must issue traffic only while the controller is idle and hold `req_*` stable until the `S_LATCH` capture edge.

## Addressing

The default parameters are:

```systemverilog
ADDR_W         = 5
DEPTH_WORDS    = 8
LATENCY_CYCLES = 3
```

The controller selects a word with `lat_addr_q[ADDR_W-1:2]`, which is `req_addr[4:2]` in the implemented configuration. The lower two address bits are ignored, so software-visible addresses should be 32-bit-word aligned. The valid byte-address window is `0x00` through `0x1C` in steps of four.

## State machine

| State | Behavior |
|---|---|
| `S_IDLE` | Wait for `req_valid`; clear the wait counter |
| `S_LATCH` | Capture read/write, address, and write-data fields |
| `S_WAIT` | Count down `LATENCY_CYCLES` |
| `S_RESPOND` | Assert `resp_ready` for one cycle, then return to idle |

For the default latency, a request follows this sequence:

| Edge/cycle | State before edge | Action |
|---|---|---|
| T0 | `S_IDLE` | Observe `req_valid`; enter `S_LATCH` |
| T1 | `S_LATCH` | Capture request; load wait counter with 3 |
| T2 | `S_WAIT` | Counter 3 → 2 |
| T3 | `S_WAIT` | Counter 2 → 1 |
| T4 | `S_WAIT` | Counter 1 → 0; enter `S_RESPOND` |
| T4–T5 | `S_RESPOND` | `resp_ready` is high |
| T5 | `S_RESPOND` | Commit the memory operation; return to `S_IDLE` |

For a read, `resp_rdata` updates on T5. The supplied testbench therefore waits for `resp_ready`, advances through the next rising edge, and then checks the registered data.

## Reset behavior

Reset clears the FSM, request registers, wait counter, and response register. The memory array is deliberately not reset, reducing reset fanout and implementation logic. Reads from words that have not been written since power-up therefore return unspecified data.

## Verified configuration

The RTL exposes parameters, but the physical implementation and retained verification evidence correspond only to `ADDR_W=5`, `DEPTH_WORDS=8`, and `LATENCY_CYCLES=3`.
