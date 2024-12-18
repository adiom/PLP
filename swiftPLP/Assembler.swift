import Foundation

/// Простой Assembler для нашего упрощённого RISC-V
/// Формат инструкций описан выше.
/// Поддерживаемые команды:
/// ADD rd,rs1,rs2
/// SUB rd,rs1,rs2
/// LW rd,imm(rs1)
/// SW rs2,imm(rs1)
/// BEQ rs1,rs2,imm
/// BNE rs1,rs2,imm
/// LUI rd,imm16
/// JAL rd,imm16
/// JALR rd,rs1,imm
/// HALT
///
/// Регистры: x0..x7
class Assembler {
    func parseRegister(_ regStr: String) -> Int? {
        // Ожидаем формат xN
        guard regStr.hasPrefix("x"),
              let num = Int(regStr.dropFirst()) else { return nil }
        if num < 0 || num > 7 { return nil }
        return num
    }

    func parseImm8(_ str: String) -> Int8? {
        // Проверяем префикс 0x для шестнадцатеричных чисел
        if str.hasPrefix("0x") {
            let hexStr = String(str.dropFirst(2))
            if let val = Int(hexStr, radix: 16) {
                if val >= -128 && val <= 127 {
                    return Int8(val)
                }
            }
        } else {
            // Интерпретируем как десятичное число
            if let val = Int(str, radix: 10) {
                if val >= -128 && val <= 127 {
                    return Int8(val)
                }
            }
        }
        return nil
    }

    func parseImm16(_ str: String) -> Int16? {
        // Проверяем префикс 0x для шестнадцатеричных чисел
        if str.hasPrefix("0x") {
            let hexStr = String(str.dropFirst(2))
            if let val = Int(hexStr, radix: 16) {
                if val >= -32768 && val <= 32767 {
                    return Int16(val)
                }
            }
        } else {
            // Интерпретируем как десятичное число
            if let val = Int(str, radix: 10) {
                if val >= -32768 && val <= 32767 {
                    return Int16(val)
                }
            }
        }
        return nil
    }


    func assemble(program: String) -> [UInt8] {
        var code: [UInt8] = []
        let lines = program.split(separator: "\n")

        func emit32(_ val: UInt32) {
            code.append(UInt8(val & 0xFF))
            code.append(UInt8((val >> 8) & 0xFF))
            code.append(UInt8((val >> 16) & 0xFF))
            code.append(UInt8((val >> 24) & 0xFF))
        }

        for line in lines {
            let l = line.trimmingCharacters(in: .whitespaces)
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
                    // R-type: opcode=0x01, format: opcode | rd | rs1 | rs2
                    let val: UInt32 = 0x01 | (UInt32(rd) << 8) | (UInt32(rs1) << 16) | (UInt32(rs2) << 24)
                    emit32(val)
                }
            case "SUB":
                // SUB rd,rs1,rs2
                if args.count == 3,
                   let rd = parseRegister(args[0]),
                   let rs1 = parseRegister(args[1]),
                   let rs2 = parseRegister(args[2]) {
                    let val: UInt32 = 0x02 | (UInt32(rd) << 8) | (UInt32(rs1) << 16) | (UInt32(rs2) << 24)
                    emit32(val)
                }
            case "LW":
                // Формат: LW rd,imm(xrs1)
                // Пример: LW x1,4(x2)
                // rd - регистр назначения, imm - смещение (байт), xrs1 - базовый регистр
                if args.count == 2 {
                    let rdStr = args[0]    // например "x1"
                    let addrStr = args[1]  // например "4(x2)"
                    guard let rd = parseRegister(rdStr) else { break }

                    let pattern = #"^([0-9\-]+)\(x([0-7])\)$"#
                    if let range = addrStr.range(of: pattern, options: .regularExpression) {
                        let full = String(addrStr[range]) // Приводим к String
                        let parts = full.split(separator: "(")
                        if parts.count == 2 {
                            let immPart = String(parts[0]) // Приводим к String
                            let basePart = String(parts[1].replacingOccurrences(of: ")", with: ""))

                            if let immVal = Int(immPart),
                               let rs1 = Int(basePart),
                               rs1 >= 0 && rs1 <= 7 {
                                let imm8 = Int8(clamping: immVal)
                                let val: UInt32 = 0x03 | (UInt32(rd) << 8) | (UInt32(rs1) << 16) | (UInt32(UInt8(bitPattern: imm8)) << 24)
                                emit32(val)
                            }
                        }
                    }
                }

            case "SW":
                // Формат: SW rs2,imm(xrs1)
                // Пример: SW x2,4(x1)
                // rs2 - регистр с данными, imm - смещение, xrs1 - базовый регистр
                if args.count == 2 {
                    let rs2Str = args[0]   // например "x2"
                    let addrStr = args[1]  // например "4(x1)"
                    guard let rs2 = parseRegister(rs2Str) else { break }

                    let pattern = #"^([0-9\-]+)\(x([0-7])\)$"#
                    if let range = addrStr.range(of: pattern, options: .regularExpression) {
                        let full = String(addrStr[range])
                        let parts = full.split(separator: "(")
                        if parts.count == 2 {
                            let immPart = String(parts[0])
                            let basePart = String(parts[1].replacingOccurrences(of: ")", with: ""))

                            if let immVal = Int(immPart),
                               let base = Int(basePart),
                               base >= 0 && base <= 7 {
                                let imm8 = Int8(clamping: immVal)
                                let val: UInt32 = 0x04 | (UInt32(base) << 8) | (UInt32(rs2) << 16) | (UInt32(UInt8(bitPattern: imm8)) << 24)
                                emit32(val)
                            }
                        }
                    }
                }

            case "BEQ":
                // BEQ rs1,rs2,imm
                if args.count == 3,
                   let rs1 = parseRegister(args[0]),
                   let rs2 = parseRegister(args[1]),
                   let imm8 = parseImm8(args[2]) {
                    let val: UInt32 = 0x05 | (UInt32(rs1) << 8) | (UInt32(rs2) << 16) | (UInt32(UInt8(bitPattern: imm8)) << 24)
                    emit32(val)
                }
            case "BNE":
                // BNE rs1,rs2,imm
                if args.count == 3,
                   let rs1 = parseRegister(args[0]),
                   let rs2 = parseRegister(args[1]),
                   let imm8 = parseImm8(args[2]) {
                    let val: UInt32 = 0x06 | (UInt32(rs1) << 8) | (UInt32(rs2) << 16) | (UInt32(UInt8(bitPattern: imm8)) << 24)
                    emit32(val)
                }
            case "LUI":
                // LUI rd,imm16
                if args.count == 2,
                   let rd = parseRegister(args[0]),
                   let imm16 = parseImm16(args[1]) {
                    let immLo = UInt8(imm16 & 0xFF)
                    let immHi = UInt8((imm16 >> 8) & 0xFF)
                    let val: UInt32 = 0x07 | (UInt32(rd) << 8) | (UInt32(immLo) << 16) | (UInt32(immHi) << 24)
                    emit32(val)
                }
            case "JAL":
                // JAL rd,imm16
                if args.count == 2,
                   let rd = parseRegister(args[0]),
                   let imm16 = parseImm16(args[1]) {
                    let immLo = UInt8(imm16 & 0xFF)
                    let immHi = UInt8((imm16 >> 8) & 0xFF)
                    let val: UInt32 = 0x08 | (UInt32(rd) << 8) | (UInt32(immLo) << 16) | (UInt32(immHi) << 24)
                    emit32(val)
                }
            case "JALR":
                // JALR rd,rs1,imm8
                if args.count == 3,
                   let rd = parseRegister(args[0]),
                   let rs1 = parseRegister(args[1]),
                   let imm8 = parseImm8(args[2]) {
                    let val: UInt32 = 0x09 | (UInt32(rd) << 8) | (UInt32(rs1) << 16) | (UInt32(UInt8(bitPattern: imm8)) << 24)
                    emit32(val)
                }
            case "HALT":
                let val: UInt32 = 0xFF
                emit32(val)
            default:
                print("Unknown command: \(instr)")
            }
        }

        return code
    }
}
