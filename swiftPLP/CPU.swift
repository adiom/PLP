import Foundation

class CPU: ObservableObject {
    // Регистр x0..x7 (x0 всегда равен 0)
    @Published var x: [Int32] = Array(repeating: 0, count: 8)
    @Published var PC: UInt32 = 0
    @Published var memory: [UInt8] = Array(repeating: 0, count: 256)

    // Консольный вывод для отображения результата системных вызовов вывода
    @Published var consoleOutput: String = ""
    // Буфер консольного ввода - символы, которые пользователь "вводит" вручную в UI
    @Published var consoleInput: [Character] = []

    // Простейшая файловая система
    var fileSystem = FileSystem()

    enum Opcode: UInt8 {
        case ADD  = 0x01
        case SUB  = 0x02
        case LW   = 0x03
        case SW   = 0x04
        case BEQ  = 0x05
        case BNE  = 0x06
        case LUI  = 0x07
        case JAL  = 0x08
        case JALR = 0x09
        case ECALL = 0x0E
        case HALT = 0xFF
    }

    // Примерный набор системных вызовов. Номер вызова = верхние 16 бит x1:
    // sysNumber = x1 >> 16
    //
    // Предложенные системные вызовы:
    // 1: print char (вывести символ из x2)
    // 2: print int (вывести число из x2)
    // 3: halt (остановить программу)
    // 4: read char (прочитать символ из consoleInput и положить его в x2)
    //
    // Файловые операции (псевдо-файловая система):
    // 5: open file (x2=addr, x3=len: имя файла в памяти, результат fd в x2)
    // 6: read file (x2=fd, x3=length, x4=addr) - чтение в память
    // 7: write file (x2=fd, x3=length, x4=addr) - запись из памяти в файл
    // 8: close file (x2=fd)

    func reset() {
        for i in 1..<x.count {
            x[i] = 0
        }
        PC = 0
        memory = Array(repeating: 0, count: 256)
        consoleOutput = ""
        consoleInput = []
        fileSystem = FileSystem()
    }

    func loadProgram(assembledCode: [UInt8]) {
        reset()
        for (index, byte) in assembledCode.enumerated() {
            if index < memory.count {
                memory[index] = byte
            }
        }
    }

    func fetchInstruction() -> UInt32? {
        let pc = Int(PC)
        guard pc + 3 < memory.count else { return nil }
        let b0 = memory[pc]
        let b1 = memory[pc+1]
        let b2 = memory[pc+2]
        let b3 = memory[pc+3]
        return UInt32(b0) | (UInt32(b1) << 8) | (UInt32(b2) << 16) | (UInt32(b3) << 24)
    }

    func step() {
        guard let instr = fetchInstruction() else { return }

        let opcode = UInt8(instr & 0xFF)
        let r1 = UInt8((instr >> 8) & 0xFF)
        let r2 = UInt8((instr >> 16) & 0xFF)
        let r3 = UInt8((instr >> 24) & 0xFF)

        let op = Opcode(rawValue: opcode)
        PC += 4
        x[0] = 0

        switch op {
        case .ADD:
            let rd = Int(r1)
            let rs1 = Int(r2)
            let rs2 = Int(r3)
            x[rd] = x[rs1] &+ x[rs2]
        case .SUB:
            let rd = Int(r1)
            let rs1 = Int(r2)
            let rs2 = Int(r3)
            x[rd] = x[rs1] &- x[rs2]
        case .LW:
            let rd = Int(r1)
            let rs1 = Int(r2)
            let imm = Int8(bitPattern: r3)
            let addr = Int(x[rs1]) &+ Int(imm)
            if addr >= 0 && addr+3 < memory.count {
                let val = UInt32(memory[addr])
                        | (UInt32(memory[addr+1]) << 8)
                        | (UInt32(memory[addr+2]) << 16)
                        | (UInt32(memory[addr+3]) << 24)
                x[rd] = Int32(bitPattern: val)
            }
        case .SW:
            let base = Int(r1)
            let reg = Int(r2)
            let imm = Int8(bitPattern: r3)
            let addr = Int(x[base]) &+ Int(imm)
            let val = UInt32(bitPattern: x[reg])
            if addr >= 0 && addr+3 < memory.count {
                memory[addr] = UInt8(val & 0xFF)
                memory[addr+1] = UInt8((val >> 8) & 0xFF)
                memory[addr+2] = UInt8((val >> 16) & 0xFF)
                memory[addr+3] = UInt8((val >> 24) & 0xFF)
            }
        case .BEQ:
            let rs1 = Int(r1)
            let rs2 = Int(r2)
            let imm = Int8(bitPattern: r3)
            if x[rs1] == x[rs2] {
                PC = UInt32(Int(PC) + Int(imm)*4)
            }
        case .BNE:
            let rs1 = Int(r1)
            let rs2 = Int(r2)
            let imm = Int8(bitPattern: r3)
            if x[rs1] != x[rs2] {
                PC = UInt32(Int(PC) + Int(imm)*4)
            }
        case .LUI:
            let rd = Int(r1)
            let immLo = r2
            let immHi = r3
            let imm16 = UInt16(immLo) | (UInt16(immHi) << 8)
            x[rd] = Int32(Int(imm16) << 16)
        case .JAL:
            let rd = Int(r1)
            let immLo = r2
            let immHi = r3
            let imm16 = Int16(bitPattern: (UInt16(immLo) | (UInt16(immHi) << 8)))
            x[rd] = Int32(PC)
            PC = UInt32(Int(PC) + Int(imm16)*4)
        case .JALR:
            let rd = Int(r1)
            let rs1 = Int(r2)
            let imm = Int8(bitPattern: r3)
            x[rd] = Int32(PC)
            PC = UInt32(Int(x[rs1]) + Int(imm))
        case .ECALL:
            // Номер системного вызова - старшие 16 бит x1
            let syscallNumber = Int(x[1]) >> 16
            handleSyscall(syscallNumber)
        case .HALT:
            print("Program halted.")
        default:
            print("Unknown instruction: \(opcode)")
        }

        x[0] = 0
    }

    func handleSyscall(_ sysNumber: Int) {
        switch sysNumber {
        case 1:
            // print char: выводим символ из x[2]
            let charCode = UInt8(truncatingIfNeeded: x[2])
            if let scalar = UnicodeScalar(UInt32(charCode)) {
                consoleOutput.append(Character(scalar))
            }
        case 2:
            // print int: выводим число x[2]
            consoleOutput.append("\(x[2])")
        case 3:
            // halt
            PC = UInt32(memory.count)
        case 4:
            // read char: читаем символ из consoleInput
            if consoleInput.isEmpty {
                x[2] = -1
            } else {
                let ch = consoleInput.removeFirst()
                x[2] = Int32(ch.asciiValue ?? 0)
            }
        case 5:
            // open file
            // x2=addr, x3=len, читаем имя файла из памяти
            let addr = Int(x[2])
            let length = Int(x[3])
            if addr >= 0 && addr+length <= memory.count {
                let nameBytes = memory[addr..<(addr+length)]
                if let name = String(bytes: nameBytes, encoding: .utf8) {
                    let fd = fileSystem.openFile(name: name)
                    x[2] = Int32(fd)
                } else {
                    x[2] = -1
                }
            } else {
                x[2] = -1
            }
        case 6:
            // read file
            // x2=fd, x3=length, x4=addr
            let fd = Int(x[2])
            let length = Int(x[3])
            let addr = Int(x[4])
            let data = fileSystem.readFile(fd: fd, length: length)
            let readCount = data.count
            if addr >= 0 && addr+readCount <= memory.count {
                for i in 0..<readCount {
                    memory[addr+i] = data[i]
                }
                x[2] = Int32(readCount)
            } else {
                x[2] = -1
            }
        case 7:
            // write file
            // x2=fd, x3=length, x4=addr
            let fd = Int(x[2])
            let length = Int(x[3])
            let addr = Int(x[4])
            if addr >= 0 && addr+length <= memory.count {
                let data = Array(memory[addr..<(addr+length)])
                let written = fileSystem.writeFile(fd: fd, data: data)
                x[2] = Int32(written)
            } else {
                x[2] = -1
            }
        case 8:
            // close file
            let fd = Int(x[2])
            let result = fileSystem.closeFile(fd: fd)
            x[2] = Int32(result ? 0 : -1)
        default:
            consoleOutput.append("Unknown syscall: \(sysNumber)\n")
        }
    }

    func run() {
        while PC < UInt32(memory.count) {
            guard let instr = fetchInstruction() else { break }
            let opcode = UInt8(instr & 0xFF)
            if opcode == Opcode.HALT.rawValue {
                step()
                break
            }
            step()
        }
    }
}
