import Foundation

class CPU: ObservableObject {
    // Регистр x0 ... x7, x0 всегда равен 0
    @Published var x: [Int32] = Array(repeating: 0, count: 8)
    @Published var PC: UInt32 = 0
    @Published var memory: [UInt8] = Array(repeating: 0, count: 256)

    // Опкоды инструкций
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
        case HALT = 0xFF
    }

    func reset() {
        for i in 1..<x.count {
            x[i] = 0
        }
        PC = 0
        memory = Array(repeating: 0, count: 256)
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
        let instruction = UInt32(b0) | (UInt32(b1) << 8) | (UInt32(b2) << 16) | (UInt32(b3) << 24)
        return instruction
    }

    func step() {
        guard let instr = fetchInstruction() else { return }

        // Декодируем
        let opcode = UInt8(instr & 0xFF)
        let r1 = UInt8((instr >> 8) & 0xFF)
        let r2 = UInt8((instr >> 16) & 0xFF)
        let r3 = UInt8((instr >> 24) & 0xFF)

        // В зависимости от инструкции, интерпретируем поля:
        // Для простоты:
        // R-type: opcode, rd=r1, rs1=r2, rs2=r3
        // I-type: opcode, rd=r1, rs1=r2, imm=r3 (знаковый байт)
        // B-type: opcode, rs1=r1, rs2=r2, imm=r3 (знаковый байт)
        // U-type: opcode, rd=r1, imm16 = (r3 << 8 | r2)
        // J-type: opcode, rd=r1, imm16 = (r3 << 8 | r2)

        let op = Opcode(rawValue: opcode)
        PC += 4 // по умолчанию увеличиваем на 4
        x[0] = 0 // x0 всегда 0

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
            let rs1 = Int(r2)
            let rs2 = Int(r1) // по формату: rd=r1, rs1=r2, imm=r3 не подходит для SW, переставим местами для удобства
            // Допустим формат SW: opcode=SW, rs1=base, rs2=reg, imm=offset
            // Перекодируем в Assembler соответствующим образом
            // Для согласованности меняем формат SW на: opcode, rs1, rs2, imm
            // Тогда:
            // r1=rd, r2=rs1, r3=imm - это было для I-type
            // нам надо для SW: opcode, rs1, rs2, imm => пусть будет:
            // Ассемблер будет генерировать: SW x2,0(x1)
            // -> opcode=0x04, rs1=1 (base), rs2=2 (reg), imm=0
            // Значит используем поля так: r1=rs1, r2=rs2, r3=imm
            // Извиняюсь за путаницу, сделаем так:
            // Переделаем: пусть для SW: opcode=0x04, r1=base, r2=rs, r3=imm
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
                // PC смещаем на imm*4
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
            // Запишем imm16 << 16 в регистр
            x[rd] = Int32(Int(imm16) << 16)
        case .JAL:
            let rd = Int(r1)
            let immLo = r2
            let immHi = r3
            let imm16 = Int16(bitPattern: (UInt16(immLo) | (UInt16(immHi) << 8)))
            x[rd] = Int32(PC) // сохраняем адрес возврата
            PC = UInt32(Int(PC) + Int(imm16)*4)
        case .JALR:
            let rd = Int(r1)
            let rs1 = Int(r2)
            let imm = Int8(bitPattern: r3)
            x[rd] = Int32(PC)
            PC = UInt32(Int(x[rs1]) + Int(imm))
        case .HALT:
            print("Program halted.")
            // Можно остановить выполнение, для теста просто не делаем ничего
            // или можно обнулить PC
            break
        default:
            print("Unknown instruction: \(opcode)")
        }

        x[0] = 0 // поддерживаем инвариант
    }

    func run() {
        while PC < UInt32(memory.count) {
            let instr = fetchInstruction()
            if instr == nil { break }
            let opcode = UInt8(instr! & 0xFF)
            if opcode == Opcode.HALT.rawValue {
                step()
                break
            }
            step()
        }
    }
}
