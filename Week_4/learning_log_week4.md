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

## Line Buffer RTL

- Implemented streaming 3×3 line buffer using explicit LB2/LB1/CUR buffers
- Designed column shift registers to form sliding 3×3 windows
- Implemented row-boundary buffer rotation without overwriting active rows
- Generated window_valid based on row/column readiness
- RTL passes Vivado syntax checks

### Streaming Conv2D Architecture Completed

The project has successfully transitioned from a stored-image convolution model
to a fully streaming, hardware-realistic Conv2D pipeline.

### Implemented Components

#### 1. Line Buffer Window Generator (Streaming)
- Explicit `LB2 / LB1 / CUR_ROW` buffer architecture
- Column shift registers form sliding 3×3 windows
- Row-boundary rotation:
  - `LB2 ← LB1`
  - `LB1 ← CUR_ROW`
- Generates `window_valid` when `row ≥ 2` and `col ≥ 2`

#### 2. Streaming MAC Integration
- Connected `line_buffer_3x3` to `mac9`
- Achieved true streaming behavior:
  - 1 pixel per cycle input
  - 1 output per cycle (steady state)
- No frame buffering required

#### 3. Functional Streaming Validation
- Testbench streams 64 pixels (8×8 raster order)
- Confirmed:
  - First valid output at `(row=2, col=2)`
  - Exactly 36 valid outputs (6×6 VALID convolution)
  - Continuous output once pipeline is filled