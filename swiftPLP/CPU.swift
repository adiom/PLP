import Foundation

/// Класс CPU для работы с эмулятором PLP.
/// Этот класс управляет регистрами, памятью и выполняет инструкции, определённые в таблице `opcode`.
/// - Author: Adiom Timur
/// - Version: 1.0
class CPU: ObservableObject {
    // MARK: - Регистры

    @Published var A: UInt8 = 0
    @Published var B: UInt8 = 0
    @Published var C: UInt8 = 0
    @Published var SP: UInt8 = 255
    @Published var FLAGS: UInt8 = 0
    @Published var PC: UInt16 = 0

    // MARK: - Память

    @Published var memory: [UInt8] = Array(repeating: 0, count: 256)

    // MARK: - Выполнение инструкций

    /// Выполнить одну инструкцию.
    /// - Parameter instruction: Код инструкции в формате `UInt8`.
    func execute(instruction: UInt8) {
        switch instruction {
        case 0x10: // LOADA
            guard Int(PC + 1) < memory.count else { return }
            A = memory[Int(PC + 1)]
            PC += 1
        case 0x11: // LOADB
            guard Int(PC + 1) < memory.count else { return }
            B = memory[Int(PC + 1)]
            PC += 1
        case 0x12: // LOADC
            guard Int(PC + 1) < memory.count else { return }
            C = memory[Int(PC + 1)]
            PC += 1
        case 0x01: // PLUS
            A = A &+ B
        case 0x20: // PUSH A
            memory[Int(SP)] = A
            SP -= 1
        case 0x21: // POP A
            SP += 1
            A = memory[Int(SP)]
        case 0x30: // CMP A, B
            FLAGS = (A == B) ? 1 : 0
        case 0x40: // JZ XX
            guard FLAGS & 1 == 1 else { break }
            PC = UInt16(memory[Int(PC + 1)])
        case 0xFF: // HALT
            print("Program halted.")
            return
        default:
            print("Unknown instruction: \(instruction)")
        }
        PC += 1
    }

    // MARK: - Методы управления

    /// Загружает программу в память.
    /// - Parameter assembledCode: Массив инструкций (Hex).
    func loadProgram(assembledCode: [UInt8]) {
        // Очищаем память и загружаем новую программу
        memory = Array(repeating: 0, count: 256)
        for (index, instruction) in assembledCode.enumerated() {
            if index < memory.count {
                memory[index] = instruction
            }
        }
        PC = 0 // Сбрасываем счётчик команд
    }

    /// Выполняет всю программу до команды HALT или завершения памяти.
    func run() {
        while PC < UInt16(memory.count) {
            let instruction = memory[Int(PC)]
            execute(instruction: instruction)
            // Останавливаем выполнение, если достигли HALT
            if instruction == 0xFF {
                break
            }
        }
    }

    /// Выполняет одну инструкцию.
    func step() {
        guard PC < UInt16(memory.count) else { return }
        let instruction = memory[Int(PC)]
        execute(instruction: instruction)
    }

    /// Сбрасывает состояние процессора и памяти.
    func reset() {
        A = 0
        B = 0
        C = 0
        SP = 255
        FLAGS = 0
        PC = 0
        memory = Array(repeating: 0, count: 256)
    }
}
