# Roadmap: 16-bit Pipelined RISC CPU
 
## Done
- [x] 5-stage pipeline (IF/ID/EX/MEM/WB), full 16-bit datapath
- [x] 12-instruction ISA (ADD, SUB, AND, OR, XOR, NOT, SHL, SHR, LOAD, STORE, BEQ, HALT)
- [x] Forwarding unit (EX/MEM + MEM/WB → EX)
- [x] Load-use hazard detection + stall
- [x] Branch flush
- [x] Python assembler
- [x] Tang Nano 9K deployment + TM1637 Fibonacci demo
- [x] Yosys synthesis of the CPU as the benchmark circuit for the GPU gate-level logic simulator, used it to identify speedups

## Planned updates
 
### 1. Cache (RTL)
- [ ] I-cache, direct-mapped, parameterized size/line-width
- [ ] Wire the cache-miss stall into my existing hazard/stall logic, reuse the load-use stall path
- [ ] D-cache, starting write-through, no-allocate-on-write-miss since that's the simplest correct version
- [ ] Build a simple memory-side bus model with artificial latency so a miss penalty actually costs something
- [ ] Later: upgrade D-cache to write-back plus dirty bit once write-through is verified working
- [ ] Expose hit/miss counters somewhere I can actually see them (UART or an extra 7-seg digit)
Doing I-cache alone first. It's a clean read-only problem and it forces me to solve the "stall the pipeline on a miss" plumbing once, cleanly, before D-cache adds write-hazard complexity on top.
 
### 2. Adding Real Verification
Doing this in two phases instead of jumping straight to UVM.
 
**Phase A: lightweight SV testbench (doing this first)**
- [ ] Plain SystemVerilog class-based driver/monitor/scoreboard, no UVM base classes
- [ ] Directed tests per instruction
- [ ] Constrained-random instruction sequences, either through my assembler or a small SV-side stream generator
- [ ] Scoreboard checked against a reference model. I can extend my Python assembler into a simple functional ISA simulator for this
- [ ] Functional coverage: covergroups on opcode, hazard scenarios (RAW resolved by forwarding, load-use stall fired, branch flush fired)
- [ ] SVA assertions for pipeline invariants (PC monotonic except on branch, no reg write when write-enable is low, no stale forwarded data)

**Phase B: migrate to full UVM** (once Phase A is solid, ideally once caches exist)
- [ ] UVM agent driving instruction streams
- [ ] UVM scoreboard and functional coverage model
- [ ] Cache-specific sequences: forced miss patterns, back-to-back miss stress, write-then-immediate-read hazard
- [ ] This is the version I want on my resume and for SiliconJackets DV

## Stuff for the future (maybe..)

- [ ] ISA: JAL/JALR for real function calls, immediate arithmetic ops
- [ ] Branch predictor, even a static "predict not-taken" vs "predict taken" comparison would be a good CPI study
- [ ] Perf counters in RTL: cycle count, instr count, stall count, cache hit/miss, exposed over UART
- [ ] UART module, also lets me load programs without re-synthesizing every test
- [ ] Exception handling: illegal-opcode trap, minimal interrupt support

