import SwiftUI

// MARK: - Main View
struct ContentView: View {
    @StateObject private var cpu = CPU() // Модель CPU
    @State private var assemblerInput: String = "" // Ассемблерный код
    @State private var programInput: String = "" // HEX-код

    var body: some View {
        HStack {
            // Assembler Input Section
            VStack(alignment: .leading) {
                Text("Assembler Input:")
                TextEditor(text: $assemblerInput)
                    .border(Color.gray, width: 1)
                    .frame(height: 200)
                Button("Assemble to Hex") {
                    assemble()
                }
                .padding(.top, 5)
            }
            .padding()

            // Hex Input Section
            VStack(alignment: .leading) {
                Text("Program Input (Hex):")
                TextEditor(text: $programInput)
                    .border(Color.gray, width: 1)
                    .frame(height: 200)
                Button("Load Program") {
                    loadProgram()
                }
                .padding(.top, 5)
            }
            .padding()
        }

        // CPU State and Controls
        VStack {
            Text("CPU State")
                .font(.headline)
            HStack {
                Text("A: \(cpu.A)")
                Text("B: \(cpu.B)")
                Text("PC: \(cpu.PC)")
            }
            .padding()

            Text("Memory:")
            ScrollView {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 16)) {
                    ForEach(cpu.memory.indices, id: \.self) { index in
                        Text(String(format: "%02X", cpu.memory[index]))
                            .frame(width: 30, height: 30)
                            .border(Color.gray)
                    }
                }
            }
            .frame(height: 200)

            // Control Buttons
            HStack {
                Button("Step") { step() }
                .padding()

                Button("Run") { run() }
                .padding()

                Button("Reset") { cpu.reset() }
                .padding()
            }
        }
        .padding()
    }
    
    private let assembler = Assembler()

    // MARK: - Helper Functions
    func assemble() {
        let assembledCode = assembler.assemble(program: assemblerInput)
        programInput = assembledCode.map { String(format: "%02X", $0) }.joined(separator: " ")
    }

    func loadProgram() {
        let instructions = programInput.split(separator: " ").compactMap { UInt8($0, radix: 16) }
        cpu.loadProgram(assembledCode: instructions)
    }

    func step() {
        cpu.step()
    }

    func run() {
        cpu.run()
    }
}
