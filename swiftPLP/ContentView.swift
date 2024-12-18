import SwiftUI

struct ContentView: View {
    @StateObject private var cpu = CPU()
    @State private var assemblerInput: String = ""
    @State private var programInput: String = ""

    private let assembler = Assembler()

    var body: some View {
        VStack {
            HStack {
                VStack(alignment: .leading) {
                    Text("Assembler Input (RISC-V-like):")
                    TextEditor(text: $assemblerInput)
                        .border(Color.gray, width: 1)
                        .frame(height: 200)
                    Button("Assemble to Hex") {
                        assemble()
                    }
                    .padding(.top, 5)
                }
                .padding()

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

            VStack {
                Text("CPU State")
                    .font(.headline)
                HStack {
                    ForEach(0..<cpu.x.count, id: \.self) { i in
                        Text("x\(i): \(cpu.x[i])")
                    }
                }
                .padding()
                Text("PC: \(cpu.PC)")
                .padding()

                Text("Memory (Hex):")
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

                HStack {
                    Button("Step") { cpu.step() }
                    .padding()

                    Button("Run") { cpu.run() }
                    .padding()

                    Button("Reset") { cpu.reset() }
                    .padding()
                }
            }
            .padding()
        }
    }

    func assemble() {
        let assembledCode = assembler.assemble(program: assemblerInput)
        programInput = assembledCode.map { String(format: "%02X", $0) }.joined(separator: " ")
    }

    func loadProgram() {
        let instructions = programInput.split(separator: " ").compactMap { UInt8($0, radix: 16) }
        cpu.loadProgram(assembledCode: instructions)
    }
}
