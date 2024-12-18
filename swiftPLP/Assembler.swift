//
//  Assembler.swift
//  swiftPLP
//
//  Created by adiom on 25.11.2024.
//

import Foundation

/// Сборщик ассемблерного кода для PLP.
/// Преобразует текстовый код в машинный Hex-код.
/// - Author: Adiom Timur
/// - Version: 1.0
class Assembler {
    
    /// Преобразует текстовый ассемблерный код в массив машинных инструкций (Hex).
    /// - Parameter program: Строка с ассемблерным кодом.
    /// - Returns: Массив `UInt8`, содержащий машинный код.
    func assemble(program: String) -> [UInt8] {
        var hexCode: [UInt8] = []
        let lines = program.split(separator: "\n")

        for line in lines {
            // Убираем лишние пробелы и разбиваем строку на части
            let parts = line.trimmingCharacters(in: .whitespacesAndNewlines).split(separator: " ")
            guard let command = parts.first else { continue }

            switch command.uppercased() {
            case "LOADA":
                guard parts.count == 2, let value = UInt8(parts[1], radix: 16) else { continue }
                hexCode.append(0x10)
                hexCode.append(value)

            case "LOADB":
                guard parts.count == 2, let value = UInt8(parts[1], radix: 16) else { continue }
                hexCode.append(0x11)
                hexCode.append(value)

            case "LOADC":
                guard parts.count == 2, let value = UInt8(parts[1], radix: 16) else { continue }
                hexCode.append(0x12)
                hexCode.append(value)

            case "STORE":
                guard parts.count == 2, let address = UInt8(parts[1], radix: 16) else { continue }
                hexCode.append(0x13)
                hexCode.append(address)

            case "LOAD":
                guard parts.count == 2, let address = UInt8(parts[1], radix: 16) else { continue }
                hexCode.append(0x14)
                hexCode.append(address)

            case "PLUS":
                hexCode.append(0x01)

            case "MINUS":
                hexCode.append(0x02)

            case "LEFT":
                hexCode.append(0x03)

            case "RIGHT":
                hexCode.append(0x04)

            case "PUSH":
                guard parts.count == 2, parts[1].uppercased() == "A" else { continue }
                hexCode.append(0x20)

            case "POP":
                guard parts.count == 2, parts[1].uppercased() == "A" else { continue }
                hexCode.append(0x21)

            case "CMP":
                guard parts.count == 2 else { continue }
                switch parts[1].uppercased() {
                case "A,B":
                    hexCode.append(0x30)
                case "A,C":
                    hexCode.append(0x31)
                default:
                    continue
                }

            case "JZ":
                guard parts.count == 2, let address = UInt8(parts[1], radix: 16) else { continue }
                hexCode.append(0x40)
                hexCode.append(address)

            case "JC":
                guard parts.count == 2, let address = UInt8(parts[1], radix: 16) else { continue }
                hexCode.append(0x41)
                hexCode.append(address)

            case "JMP":
                guard parts.count == 2, let address = UInt8(parts[1], radix: 16) else { continue }
                hexCode.append(0x42)
                hexCode.append(address)

            case "HALT":
                hexCode.append(0xFF)

            default:
                print("Unknown command: \(command)")
            }
        }

        return hexCode
    }
}
