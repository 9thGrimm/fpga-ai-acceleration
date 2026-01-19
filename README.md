# fpga-ai-acceleration
Project Repo of Sagar Sajeev as part of FPGA AI Implementations and Learning Notes from 2026
=======
# FPGA-Based AI Acceleration on Zynq-7000

This repository documents a structured, 6-month hands-on project focused on
designing, implementing, and verifying FPGA-based neural network accelerators
using a Zynq-7000 SoC.

The project emphasizes **fundamental understanding, correct hardware mapping,
and clean system integration**, rather than black-box acceleration frameworks.

---

## Project Goals

The primary objectives of this project are:

- Design a **CNN inference accelerator in RTL**
- Translate deep learning operations into **efficient hardware dataflows**
- Explore **memory vs compute trade-offs** in FPGA-based AI
- Integrate ARM (PS) and FPGA (PL) using standard **AXI interfaces**
- Extend the accelerator to **real sensor-driven edge AI applications**
- Maintain strong emphasis on **correctness, verification, and documentation**

---

## Project Scope & Roadmap

### Phase 1 — Foundations
- CNN fundamentals and inference-focused deep learning concepts
- Manual implementation of convolution and feedforward operations
- Hardware-oriented thinking: buffering, reuse, pipelining

### Phase 2 — CNN Accelerator (MNIST)
- RTL implementation of convolution, activation, pooling, and FC layers
- Python golden models for functional verification
- PS–PL integration on Zynq
- Performance measurement (latency, throughput, resource usage)

### Phase 3 — Real-Time Edge AI
- Sensor input via ADC / PMOD interfaces
- Preprocessing pipelines (time-domain or frequency-domain)
- End-to-end real-time inference system
- Debugging and validation using external instrumentation

### Phase 4 — Advanced Topic
One advanced specialization, such as:
- Flexible / multi-model CNN accelerator
- High-Level Synthesis (HLS) comparison
- Verification-focused AI accelerator testbench

---

## Hardware Platform

- **Zybo Z7** (Zynq-7000 ARM + FPGA SoC)
- **Analog Discovery 3** (planned) for signal integrity and debugging
- External sensors and PMOD peripherals (planned)
- ESD-safe workbench environment

---

## Repository Structure
