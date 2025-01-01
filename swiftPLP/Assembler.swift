import Foundation

/// Простой ассемблер для упрощённого RISC-V.
/// Игнорирует строки, начинающиеся на `#`.
/// Удаляет комментарии после `#` в строках.
class Assembler {
    func parseRegister(_ regStr: String) -> Int? {
        guard regStr.hasPrefix("x"), let num = Int(regStr.dropFirst()), num >= 0, num < 8 else { return nil }
        return num
    }

    func parseImm8(_ str: String) -> Int8? {
        if str.hasPrefix("0x") {
            let hexStr = String(str.dropFirst(2))
            if let val = Int(hexStr, radix: 16), val >= -128 && val <= 127 {
                return Int8(val)
            }
        } else {
            if let val = Int(str, radix: 10), val >= -128 && val <= 127 {
                return Int8(val)
            }
        }
        return nil
    }

    func parseImm16(_ str: String) -> Int16? {
        if str.hasPrefix("0x") {
            let hexStr = String(str.dropFirst(2))
            if let val = Int(hexStr, radix: 16), val >= -32768 && val <= 32767 {
                return Int16(val)
            }
        } else {
            if let val = Int(str, radix: 10), val >= -32768 && val <= 32767 {
                return Int16(val)
            }
        }
        return nil
    }

    func emit32(_ val: UInt32, into code: inout [UInt8]) {
        code.append(UInt8(val & 0xFF))
        code.append(UInt8((val >> 8) & 0xFF))
        code.append(UInt8((val >> 16) & 0xFF))
        code.append(UInt8((val >> 24) & 0xFF))
    }

    func assemble(program: String) -> [UInt8] {
        var code: [UInt8] = []
        let lines = program.split(separator: "\n")

        for var line in lines {
            var l = line.trimmingCharacters(in: .whitespaces)
            // Удалим комментарии
            if let hashIndex = l.firstIndex(of: "#") {
                l = String(l[..<hashIndex]).trimmingCharacters(in: .whitespaces)
            }
            if l.isEmpty { continue }
            let parts = l.split(separator: " ", maxSplits: 1).map{String($0)}
            guard let instr = parts.first?.uppercased() else { continue }
            let args = parts.count > 1 ? parts[1].split(separator: ",").map{String($0.trimmingCharacters(in: .whitespaces))} : []

            switch instr {
            case "ADD":
                // ADD rd,rs1,rs2
                if args.count == 3,
                   let rd = parseRegister(args[0]),
                   let rs1 = parseRegister(args[1]),
                   let rs2 = parseRegister(args[2]) {
                    let val: UInt32 = 0x01 | (UInt32(rd) << 8) | (UInt32(rs1) << 16) | (UInt32(rs2) << 24)
                    emit32(val, into: &code)
                }
            case "SUB":
                if args.count == 3,
                   let rd = parseRegister(args[0]),
                   let rs1 = parseRegister(args[1]),
                   let rs2 = parseRegister(args[2]) {
                    let val: UInt32 = 0x02 | (UInt32(rd) << 8) | (UInt32(rs1) << 16) | (UInt32(rs2) << 24)
                    emit32(val, into: &code)
                }
            case "LW":
                // LW rd,imm(xrs1)
                if args.count == 2,
                   let rd = parseRegister(args[0]) {
                    // Пример: LW x1,4(x2)
                    if let parenIndex = args[1].firstIndex(of: "(") {
                        let immPart = String(args[1][..<parenIndex])
                        let rest = String(args[1][parenIndex...]).trimmingCharacters(in: CharacterSet(charactersIn: "()"))
                        // rest = "x2"
                        if let rs1 = parseRegister(rest),
                           let imm = parseImm8(immPart) {
                            let val: UInt32 = 0x03 | (UInt32(rd) << 8) | (UInt32(rs1) << 16) | (UInt32(UInt8(bitPattern: imm)) << 24)
                            emit32(val, into: &code)
                        }
                    }
                }
            case "SW":
                // SW x2,4(x1) => opcode=0x04 | base=x1| reg=x2| imm
                if args.count == 2 {
                    // args[0] = x2, args[1] = "4(x1)"
                    if let reg = parseRegister(args[0]) {
                        if let parenIndex = args[1].firstIndex(of: "(") {
                            let immPart = String(args[1][..<parenIndex])
                            let rest = String(args[1][parenIndex...]).trimmingCharacters(in: CharacterSet(charactersIn: "()"))
                            // rest = "x1"
                            if let base = parseRegister(rest),
                               let imm = parseImm8(immPart) {
                                let val: UInt32 = 0x04 | (UInt32(base) << 8) | (UInt32(reg) << 16) | (UInt32(UInt8(bitPattern: imm)) << 24)
                                emit32(val, into: &code)
                            }
                        }
                    }
                }
            case "BEQ":
                if args.count == 3,
                   let rs1 = parseRegister(args[0]),
                   let rs2 = parseRegister(args[1]),
                   let imm = parseImm8(args[2]) {
                    let val: UInt32 = 0x05 | (UInt32(rs1) << 8) | (UInt32(rs2) << 16) | (UInt32(UInt8(bitPattern: imm)) << 24)
                    emit32(val, into: &code)
                }
            case "BNE":
                if args.count == 3,
                   let rs1 = parseRegister(args[0]),
                   let rs2 = parseRegister(args[1]),
                   let imm = parseImm8(args[2]) {
                    let val: UInt32 = 0x06 | (UInt32(rs1) << 8) | (UInt32(rs2) << 16) | (UInt32(UInt8(bitPattern: imm)) << 24)
                    emit32(val, into: &code)
                }
            case "LUI":
                if args.count == 2,
                   let rd = parseRegister(args[0]),
                   let imm16 = parseImm16(args[1]) {
                    let immLo = UInt8(imm16 & 0xFF)
                    let immHi = UInt8((imm16 >> 8) & 0xFF)
                    let val: UInt32 = 0x07 | (UInt32(rd) << 8) | (UInt32(immLo) << 16) | (UInt32(immHi) << 24)
                    emit32(val, into: &code)
                }
            case "JAL":
                if args.count == 2,
                   let rd = parseRegister(args[0]),
                   let imm16 = parseImm16(args[1]) {
                    let immLo = UInt8(imm16 & 0xFF)
                    let immHi = UInt8((imm16 >> 8) & 0xFF)
                    let val: UInt32 = 0x08 | (UInt32(rd) << 8) | (UInt32(immLo) << 16) | (UInt32(immHi) << 24)
                    emit32(val, into: &code)
                }
            case "JALR":
                if args.count == 3,
                   let rd = parseRegister(args[0]),
                   let rs1 = parseRegister(args[1]),
                   let imm = parseImm8(args[2]) {
                    let val: UInt32 = 0x09 | (UInt32(rd) << 8) | (UInt32(rs1) << 16) | (UInt32(UInt8(bitPattern: imm)) << 24)
                    emit32(val, into: &code)
                }
            case "ECALL":
                let val: UInt32 = 0x0E
                emit32(val, into: &code)
            case "HALT":
                let val: UInt32 = 0xFF
                emit32(val, into: &code)
            default:
                // Неизвестная инструкция или пустая строка - игнорируем
                break
            }
        }

        return code
    }
}
