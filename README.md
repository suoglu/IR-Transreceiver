# IR Transreceiver

## Contents of Readme

1. About
2. About IR
3. Modules
4. Interface Description
5. Simulation
6. Test
7. Status Information
8. Issues

[![Repo on GitLab](https://img.shields.io/badge/repo-GitLab-6C488A.svg)](https://gitlab.com/suoglu/ir-transreceiver)
[![Repo on GitHub](https://img.shields.io/badge/repo-GitHub-3D76C2.svg)](https://github.com/suoglu/IR-Transreceiver)

---

## About

This repository contains modules related to infrared (IR) emitters and receivers, such as remote controls. All modules in this repository requires external IR devices. These modules are communicated via single pin which kept high when not used. (Pull-up)

## About (Implemented) IR

IR or Consumer IR (CIR) is a widely used [Optical wireless communication (OWC)](https://en.wikipedia.org/wiki/Optical_wireless_communications) method. IR transmisson employ [Infrared](https://en.wikipedia.org/wiki/Infrared) light to transmit data. They require line of sight to operate. They usually use 38 kHz as carrier frequency. Data is usually modulated with [Amplitude-shift keying (ASK)](https://en.wikipedia.org/wiki/Amplitude-shift_keying). Source: [Wikipedia](https://en.wikipedia.org/wiki/Consumer_IR)

Implemented modules decode/encode `0` as a short low (~600µs, no max.) followed by a short high (~600µs, max. 990µs), and `1` as a short low (~600µs, no max.) followed by a long high (~1.6ms, between 1-1.99ms). Any high period longer than 2ms ends transmisson. Transmission begins when an arbitrary low followed by an arbitrary high received. Transmitting no data or data smaller then 8 bits interpreted as repeat press.

## Modules

### `ir_decoder` module

**General Description:**

Module `ir_decoder` decodes the received IR signal. Width of the decoded code controlled by parameter `CODEBITS`. If received code is longer than `CODEBITS`, only least significant bits are kept. Module requires two clock. Clock `clk_100kHz` must be around 100kHz, in testing 97.656KHz is used. System clock, `clk`, can be any multiple of `clk_100kHz`.

**Working Principle:**

After a reset `ir_decoder` checks for the start condition, which is an arbitrary low followed by an arbitrary high. After receiving start condition, `ir_decoder` starts to decode. Decoded bit value determined by counting the duration of the `rx` high pulses and stored at the negative edge of `rx`. Durations less than 990µs interpreted as `0`, durations between 1ms to 1.99ms interpreted as `1`. If the duration is longer then 2ms end condition is generated and no data is decoded. Exact durations depends on the period of `clk_100kHz`, given values assume period of 10µs. If length of the received data is shorter than 8 bits or no data is received, repeat press signal, `repeat_press`,  is generated and `code` is not updated. When a new code is decoded, `newCode` pulse with a length of a one `clk` is generated.

## Interface Description

### `ir_decoder` Interface

|   Port   | Type | Width |  Description |
| :------: | :----: | :----: |  ------  |
| `clk` | I | 1 | System Clock |
| `clk_100kHz` | I | 1 | 100kHz Clock, used in decoding |
| `rst` | I | 1 | System Reset |
| `rx` | I | 1 | Receiver Pin |
| `code` | O | `CODEBITS` | Decoded code |
| `repeat_press` | O | 1 | Indicates repeat press received |
| `newCode` | O | 1 | Indicates a new code decoded |

I: Input  O: Output

- System Clock, `clk`, frequency can be any multiple of `clk_100kHz`. 100 MHz is used it testing.
- If received code is shorter than `CODEBITS`, MSBs will be `0`.
- If received code is longer than `CODEBITS`, LSBs are kept.
- `clk_100kHz` should be approximately 100kHz, some variation does not affect functionality. During simulation and testing 97.656kHz clock is used.

## Simulation

### `ir_decoder` Simulation

Module `ir_decoder` simulated with [sim_ir_dec.v](Simulation/sim_ir_dec.v). Module simulated with default `CODEBITS` value, 32 bits. One 16bit code (0x0FAA) is send via `rx`. Clock signal `clk_100kHz` is generated with onboard module `clkGen97k656hz`.

## Test

### `ir_decoder` Test

Module `ir_decoder` tested with [ir_decoder_test.v](Test/ir_decoder_test.v) and [Basys3_0.xdc](Test/Basys3_0.xdc). Module tested with default `CODEBITS` value, 32 bits. Receiver Pin connected to JB10 port. Decoded code send via UART and shown on seven segment display (SSD). Left most switch, SW15, used to choose which portion of the `code` is shown. When SW15 is high MSBs, when low LSBs are shown. Dots on the SSD indicates repeat press. UART transmit connected to JB2 port and USB-RS232 transmit port. Baudrate set to 460.8k. 8 bit data, no parity and 1 bit stop is used. These values are hardcoded in [ir_decoder_test.v](Test/ir_decoder_test.v) and can be changed from there. (For more information check [UART](https://gitlab.com/suoglu/uart) repository) When a new code decoded, it is transmitted automatically via UART in four transmissons, MSB first.

Module `irdec_test` can also be used as IR remote decoder to extract 32 bit codes from IR remotes, and see them.

## Status Information

**Last Simulation:**

- `ir_decoder`: 18 January 2021, with [Vivado Simulator](https://www.xilinx.com/products/design-tools/vivado/simulator.html)

**Last Test:** -

- `ir_decoder`: 18 January 2021, on [Digilent Basys 3](https://reference.digilentinc.com/reference/programmable-logic/basys-3/reference-manual)

## Issues

**`ir_decoder`:**

- Rarely module stucks and needs reset to work again.
