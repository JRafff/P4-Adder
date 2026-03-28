# 32-bit Pentium 4 (P4) Adder / Subtractor

Welcome to the RTL implementation of the renowned **32-bit Pentium 4 (P4) Adder**, inspired by the high-speed ALU architecture pioneered by Intel. 

Standard Ripple Carry Adders (RCAs) suffer from severe performance bottlenecks due to linear carry propagation. To shatter this speed limit, this project leverages a high-performance **hybrid architecture** written entirely in structural VHDL. The design drastically minimizes the critical path delay by dividing the workload into two parallel, highly optimized macro-blocks:

* **Sparse Parallel Prefix Carry Tree:** Computes the lookahead carries in logarithmic time ($\log_2N$) rather than linear time.
* **Sum Generator (Carry Select):** Pre-computes partial sums in advance, instantly selecting the correct result as soon as the sparse tree routes the carry.

Furthermore, this module acts as a complete arithmetic unit. It natively supports both **Addition and Subtraction** by implementing a 2's complement XOR barrier on the inputs, controlled by a dedicated `SUB` flag.

![Alt text](/img/P4_top_level.JPG?raw=true "P4 Adder Top Level") *(Note: Sostituisci con l'immagine del tuo Top Level)*

---

## 1. Carry Generator (Sparse Prefix Tree)

The core of the P4 Adder is its carry generation network. Instead of waiting for the carry to ripple through all 32 bits, this block predicts the lookahead carries at specific intervals (every 4 bits) using a **Kogge-Stone / Ladner-Fischer** hybrid tree topology in $\log_2(N)$ stages.

The tree is built using three fundamental logic layers:

### A. The PG Network
The first layer evaluates the initial Propagate ($p_i$) and Generate ($g_i$) signals for each bit independently:
* $p_i = a_i \oplus b_i$
* $g_i = a_i \cdot b_i$

### B. The Prefix Tree (Superblocks)
The intermediate levels of the tree merge the individual $p$ and $g$ signals into group signals using two specific logical operators:

* **PG Block (White box):** Computes both the group Generate and group Propagate signals. It is used in the intermediate nodes of the tree.
    * $G_{i:j} = G_{i:k} + (P_{i:k} \cdot G_{k-1:j})$
    * $P_{i:j} = P_{i:k} \cdot P_{k-1:j}$

* **G Block (Shadowed/Black box):** Computes *only* the group Generate signal. It is typically used in the final nodes where the propagate signal is no longer needed.
    * $G_{i:j} = G_{i:k} + (P_{i:k} \cdot G_{k-1:j})$

![Alt text](/img/PG_blocks.JPG?raw=true "PG and G blocks") *(Note: Sostituisci con lo schema dei blocchi PG/G)*

---

## 2. Sum Generator (Carry Select Architecture)

While the Carry Tree is busy computing the lookahead carries, the **Sum Generator** works in parallel to compute the partial sums in advance, ensuring zero wasted time.


The 32-bit inputs are divided into 4-bit sub-blocks. Each sub-block implements a **Carry Select (CS)** architecture:
1.  It contains **two parallel Ripple Carry Adders (RCAs)**.
2.  The first RCA computes the 4-bit sum assuming an incoming carry of `0`.
3.  The second RCA computes the sum assuming an incoming carry of `1`.
4.  A **Multiplexer (MUX)** is placed at the output of these RCAs. 

As soon as the actual carry arrives from the Prefix Tree (Carry Generator), the MUX instantly selects the correct pre-computed sum. This completely hides the internal RCA delay, as the sums are already calculated by the time the sparse tree finishes its routing.

![Alt text](/img/CSB_architecture.JPG?raw=true "Carry Select Block") *(Note: Sostituisci con lo schema dei tuoi blocchi RCA e MUX)*

---

## Design Methodology & Coding Style

The project is structured using a strict **bottom-up approach**:
* **Behavioral VHDL:** Used strictly for the elementary logic gates and base components (e.g., the standard RCA, the Multiplexers, and the basic PG/G logic equations).
* **Structural VHDL:** Used for all the upper hierarchical levels (the Prefix Tree routing, the Carry Select blocks assembly, and the Top-Level P4 module). This ensures that the RTL code exactly matches the intended physical hardware wiring.

## 📊 Verification
The design includes a fully automated, synchronous testbench (`TB_P4_ADDER.vhd`) that verifies the correctness of both Additions and Subtractions. It feeds the DUT with mathematical corner cases (e.g., extreme propagation `0xFFFFFFFF + 0x00000001`) and saves the self-checked results into a log file.
