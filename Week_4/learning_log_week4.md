## Week 4 – Sunday (Streaming Conv2D Architecture – Line Buffers)

### Objective
Transition from stored-image Conv2D (Week 3) to a hardware-realistic **streaming Conv2D architecture** using line buffers and sliding windows.

### Key Concepts Understood
- Streaming Conv2D processes **1 pixel per cycle** in raster order (left → right, top → bottom)
- The convolution window is **not stored as a box**; it is implicitly formed from:
  - line buffers (previous rows)
  - shift registers (recent columns)
- Startup latency exists, but steady-state throughput is **1 output per cycle**

### Buffer Architecture (Finalized)
Chose **Option A – Explicit Current Row Buffer** for clarity and correctness:

- `LB2` : stores row `r-2` (8 pixels)
- `LB1` : stores row `r-1` (8 pixels)
- `CUR_ROW` : accumulates the incoming row `r` (8 pixels)
- Shift registers hold the **last 3 pixels** of each active row for window taps

At row boundaries:
- `LB2 ← LB1`
- `LB1 ← CUR_ROW`
- `CUR_ROW` resets for next row

This avoids overwriting rows that are still required for convolution.

### Timing & Validity
- First valid 3×3 window appears at **cycle 18** (0-based)
- Condition for valid window:
- Total outputs for 8×8 input with 3×3 VALID convolution: **36 (6×6)**

### Memory Accounting
- Line buffers: `2 × 8 pixels = 16 pixels = 128 bits`
- Current row buffer: `8 pixels = 64 bits`
- Column shift registers: `3 rows × 2 pixels = 6 pixels = 48 bits`
- Total working state (conceptual): line buffers + current row + shift registers

### Design Decisions
- Separated responsibilities:
- Line buffers = row history
- Shift registers = column history
- MAC = computation

### Outcome
- Clear understanding of how rows are stored, shifted, and reused
- Resolved confusion around “where row r is stored before becoming LB1”
- Architecture frozen and ready for RTL implementation