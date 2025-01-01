//
//  FileSystem.swift
//  swiftPLP
//
//  Created by adiom on 18.12.2024.
//

import Foundation

class FileSystem {
    // Простейшая файловая система: имя -> данные
    // Открытие файла возвращает дескриптор (целое число).
    // В данном примере: дескрипторы - индексы в массиве открытых файлов.
    
    private var files: [String: [UInt8]] = [:]
    private var openFiles: [Int: (name: String, pos: Int)] = [:]
    private var nextFd: Int = 1

    init() {
        // Можно добавить пару тестовых файлов
        files["test.txt"] = Array("Hello, File!\n".utf8)
    }

    func openFile(name: String) -> Int {
        // Если файла нет - создать пустой
        if files[name] == nil {
            files[name] = []
        }
        let fd = nextFd
        nextFd += 1
        openFiles[fd] = (name: name, pos: 0)
        return fd
    }

    func readFile(fd: Int, length: Int) -> [UInt8] {
        guard let (name, pos) = openFiles[fd],
              let data = files[name] else { return [] }
        let end = min(pos+length, data.count)
        let chunk = Array(data[pos..<end])
        openFiles[fd] = (name, end)
        return chunk
    }

    func writeFile(fd: Int, data: [UInt8]) -> Int {
        guard let (name, pos) = openFiles[fd],
              var fileData = files[name] else { return -1 }
        // Вставляем/записываем данные начиная с pos
        if pos + data.count > fileData.count {
            fileData.append(contentsOf: Array(repeating: 0, count: pos + data.count - fileData.count))
        }
        for i in 0..<data.count {
            fileData[pos+i] = data[i]
        }
        files[name] = fileData
        openFiles[fd] = (name, pos+data.count)
        return data.count
    }

    func closeFile(fd: Int) -> Bool {
        return openFiles.removeValue(forKey: fd) != nil
    }
}
