# SwiftPLP - RISC-V Processor Emulator

A processor emulator implementing a simplified RISC-V architecture using Swift and SwiftUI.

## Main Features
- Implemented in Swift using SwiftUI
- 8 general-purpose registers (x0-x7)
- 256 bytes of memory
- Support for basic RISC-V instructions
- Console input/output via system calls
- Simple file system
- Graphical user interface

## Supported Instructions
- `ADD rd,rs1,rs2` - Addition
- `SUB rd,rs1,rs2` - Subtraction
- `LW rd,imm(rs1)` - Load word
- `SW rs2,imm(rs1)` - Store word
- `BEQ rs1,rs2,imm` - Branch if equal
- `BNE rs1,rs2,imm` - Branch if not equal
- `LUI rd,imm` - Load upper immediate
- `JAL rd,imm` - Jump and link
- `JALR rd,rs1,imm` - Jump and link register
- `ECALL` - System call
- `HALT` - Halt program

## System Calls
- Print character (character in x2)
- Print number (number in x2)
- Halt program
- Read character (result in x2)
- Open file (name in memory at address x2, length in x3)
- Read from file (fd in x2, length in x3, buffer address in x4)
- Write to file (fd in x2, length in x3, data address in x4)
- Close file (fd in x2)

## Components
- `CPU.swift` - Processor implementation
- `Assembler.swift` - Assembler
- `FileSystem.swift` - File system
- `ContentView.swift` - UI interface

## Requirements
- macOS 15.0 or later
- Xcode 16.0 or later
- Swift 5.0 or later

## Build and Run
1. Open the project in Xcode:
2. Select the target device (macOS)
3. Click ▶️ to build and run

## Usage
1. Enter assembly code in the left text field
2. Click "Assemble to Hex" to translate
3. Click "Load Program" to load into memory
4. Use:
   - "Step" to execute step by step
   - "Run" to run until HALT instruction
   - "Reset" to reset the emulator

## Example Program

## License
MIT License. See LICENSE file.

## Author
adiom

## Contributing
Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.
