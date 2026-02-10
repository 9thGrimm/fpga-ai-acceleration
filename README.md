# FPGA-Based AI Acceleration for Automatic Modulation Recognition (AMR)

This repository documents a structured, 6-month hands-on project focused on
designing, implementing, and verifying **FPGA-based AI accelerators for
signal intelligence (SIGINT)–relevant workloads**, with Automatic Modulation
Recognition (AMR) as the final target application.

The project emphasizes **fundamental understanding, correct hardware mapping,
deterministic dataflow design, and verification-driven development**, rather
than black-box acceleration frameworks or turnkey AI IP.

---

## Project Motivation

Modern SIGINT and spectrum-monitoring systems increasingly rely on
machine-learning techniques—particularly CNNs—to classify modulation schemes
from raw or preprocessed RF signals.

However, deploying these models in real-time, power-constrained, and
latency-sensitive environments requires:
- Efficient **streaming dataflows**
- Careful **memory reuse**
- Deterministic, verifiable **hardware architectures**

This project explores how deep learning inference for AMR can be mapped
**from mathematical models → RTL → FPGA hardware**, with a strong emphasis on
correctness and system-level thinking.

---

## Project Goals

The primary objectives of this project are:

- Design a **CNN inference accelerator in synthesizable RTL**
- Translate deep learning primitives into **streaming FPGA dataflows**
- Explore **memory vs compute trade-offs** in convolution-heavy workloads
- Maintain **bit-accurate equivalence** with Python golden models
- Integrate ARM (PS) and FPGA (PL) using standard **AXI interfaces**
- Build toward a **real-time Automatic Modulation Recognition (AMR) pipeline**
- Emphasize **verification, observability, and documentation** throughout

---

## Project Scope & Roadmap

### Phase 1 — Foundations (Completed)
- CNN fundamentals with an inference-only focus
- Manual implementation of convolution and feedforward operations
- Fixed-point arithmetic and bit-width analysis
- Hardware-oriented thinking: buffering, reuse, control vs datapath separation

### Phase 2 — CNN Accelerator Core
- RTL implementation of Conv2D using:
  - MAC-based datapaths
  - Line buffers and sliding windows
  - Streaming, one-pixel-per-cycle architectures
- Python golden models for cycle-accurate functional verification
- Validation using self-checking SystemVerilog testbenches
- Early performance characterization (latency, throughput, utilization)

### Phase 3 — Signal Preprocessing for AMR
- Streaming DSP pipelines for RF-derived data:
  - Time-domain IQ samples
  - Optional frequency-domain transforms (e.g., STFT / spectrograms)
- Buffering and rate-matching between ADC, preprocessing, and CNN accelerator
- Data formatting suitable for CNN-based modulation classification

### Phase 4 — Automatic Modulation Recognition (SIGINT Application)
- End-to-end AMR system:
  - Signal ingestion → preprocessing → CNN inference → classification
- Evaluation across multiple modulation schemes and SNR levels
- Focus on **deterministic behavior and observability**, not just accuracy
- Verification-oriented testing (coverage of modulation types and conditions)

---

## Hardware Platform

- **Zybo Z7** (Zynq-7000 ARM + FPGA SoC)
- **Analog Discovery 3** (planned) for signal integrity, timing, and debug
- External signal sources / PMOD peripherals (planned)
- ESD-safe workbench environment

---

## Design Philosophy

- Prefer **clarity and correctness** over premature optimization
- Avoid opaque AI acceleration frameworks
- Treat verification as a **first-class design requirement**
- Build reusable hardware blocks with clear interfaces
- Make architectural trade-offs explicit and documented
