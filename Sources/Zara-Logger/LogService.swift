//
//  LogService.swift
//  zaraDatabaseWrapper
//
//  Created by home on 10/10/18.
//

import Foundation
import Common

extension LogService : LogServiceProtocol {}

///The log class containing all the needed methods
public struct LogService : Sendable  {
   
    public init(name : String, withStart : Bool = true) {
        self.name = name
        if withStart {
            start()
        }
    }
    ///The max size a log file can be in Kilobytes. Default is 1024 (1 MB)
    public var maxFileSize: UInt64 = 2048
    
    ///The max number of log file that will be stored. Once this point is reached, the oldest file is deleted.
    public var maxFileCount = 99999
    
    ///The directory in which the log files will be written
    public var directory : String {
        var directory = LogService.defaultDirectory()
        directory = NSString(string: directory).expandingTildeInPath
        do {
            try FileOperations.createDir(at: directory)
        } catch {
            print("Unable to create Directory \(directory)")
        }
        return LogService.defaultDirectory()
    }
    
    public var currentPath: String {
        return "\(directory)/\(logName(0))"
    }
    
    ///The name of the log files
    let name : String

    
    ///Emit a line to whichever sinks are active. `write` no-ops under
    ///`LOG_STDOUT_ONLY`, so the banner/API-trace helpers below — which have no
    ///`console:` argument of their own — need stdout explicitly or they vanish.
    private func emit(_ line: String) {
        if LogService.stdoutOnly { print(line) }
        write(line)
    }

    func start() {
            emit("===========================================================")
            emit("==========  START \(name) \(Date().timeStamp()) ===========")
            emit("===========================================================")
    }

    
    ///Whether or not logging also prints to the console
    public var printToConsole = true
    
    //the date formatter
    var dateFormatter: DateFormatter {
        return Globals.Date.TimeStamp
    }
    
    ///When true (env `LOG_STDOUT_ONLY` ∈ {true,1,yes}), file logging is skipped
    ///entirely — log lines still reach stdout via the console path in
    ///`logger()`/`logMessage()`. For containerized apps whose stdout is collected
    ///centrally (e.g. Alloy/Loki) and which must not require a writable log volume
    ///(the hardcoded `/Users/server/logs` path needs a PVC otherwise). Default off,
    ///so every existing file-logging consumer is unchanged.
    static let stdoutOnly: Bool = {
        switch ProcessInfo.processInfo.environment["LOG_STDOUT_ONLY"]?.lowercased() {
        case "true", "1", "yes": return true
        default: return false
        }
    }()

    ///The effective console flag for a call site's `console:` argument.
    ///
    ///`console: false` means "file only", which is fine while the file sink
    ///exists. Under `LOG_STDOUT_ONLY` there is no file sink, so those call
    ///sites would write to NO destination at all — silently losing them.
    ///That is not theoretical: `EventService.logError`/`logEvent`/`logMain`
    ///all default to `console: false`, so the error path would go dark.
    ///In stdout-only mode stdout has to carry everything.
    static func toConsole(_ console: Bool) -> Bool {
        console || stdoutOnly
    }

    ///write content to the current log file.
    public func write(_ text: Any, terminator: String = "\n") {
        if LogService.stdoutOnly { return }
        do {
        let writeText : String
        let test = type(of: text)
        switch test {
        case is String.Type, is Int.Type, is Bool.Type:
            writeText = "\(text)\(terminator)"
        case is Date.Type:
            writeText = "\((text as! Date).timeStamp())\(terminator)"
        default:
            writeText = "\(description(r: text))\(terminator)"
        }
        
        try FileOperations.writeAtEndOf(path: currentPath, data: writeText.data(using: .utf8)!)
        cleanup()
        } catch {
            print(error.localizedDescription)
        }
    }
    ///do the checks and cleanup
    func cleanup() {
        let path = "\(directory)/\(logName(0))"
        let size = fileSize(path)
        let maxSize: UInt64 = maxFileSize*1024
        if size > 0 && size >= maxSize && maxSize > 0 && maxFileCount > 0 {
            rename(0)
        }
    }
    
    ///check the size of a file
    func fileSize(_ path: String) -> UInt64 {
        let fileManager = FileManager.default
        let attrs = try? fileManager.attributesOfItem(atPath: path)
        if let dict = attrs, let size =  dict[FileAttributeKey.size] as? UInt64 {
            return size
        }
        return 0
    }
    
    ///Recursive method call to rename log files
    func rename(_ index: Int) {
        let fileManager = FileManager.default
        let path = "\(directory)/\(logName(index))"	
        let newPath = "\(directory)/\(logName(index+1))"
        if fileManager.fileExists(atPath: newPath) {
            rename(index+1)
        }
        do {
            try fileManager.moveItem(atPath: path, toPath: newPath)
        } catch _ {
        }
    }
    
    func description(r : Any) -> String {
        var mirror : Mirror? = Mirror(reflecting: r)
        
        var str = "\(mirror!.subjectType)("
        while  mirror != nil {
            for (label, value) in (mirror?.children)! {
                if let label = label {
                    str += label
                    str += ": "
                    if value is Date {
                        str += "\((value as! Date).timeStamp()),"
                    } else {
                        str += "\(value),"
                    }
                }
            }
            mirror = mirror?.superclassMirror
        }
        str = String(str.dropLast())
        str += ")"
        
        return str
    }
    
    public func apiLog(_ function : String, _ type : String,_  xml : String) {
        emit("====================================================")
        emit("\(Date().timeStamp()) \(function) \(type)")
        emit(xml)

    }
    
    ///gets the log name
    func logName(_ num :Int) -> String {
        return "\(name)-\(Date().dateString())-\(num).log"
    }
    
    ///get the default log directory
    static func defaultDirectory() -> String {
        var path = ""
        #if os(iOS)
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        path = "\(paths[0])/Logs"
        #elseif os(macOS) || os(Linux)
        path = "/Users/server/logs/\(Date().dateString())"
        #endif
        if FileOperations.checkFileExists(atPath: path) && path != ""  {
            try? FileOperations.createDir(at: path)
        }
        return path
    }
    
    public func logger(_ message : String, console : Bool = true) {
        if LogService.toConsole(console) {
            print("[\(Date().timeStamp())] : ", message)
        }
        self.write("[\(Date().timeStamp())] : " + message)
    }


    public func logMessage(_ s: Any..., terminator: String = "\n", console : Bool = true) {
        let console = LogService.toConsole(console)
        if console {print(Date().timeStamp(), separator: "", terminator: " : ")}
        self.write("[\(Date().timeStamp())]", terminator: " : ")
        for i in s {
            if console { print(i, separator: "", terminator: "") }
            self.write(i, terminator: "")
        }
        self.write("", terminator: terminator)
        if console { print("", separator: "", terminator: terminator)}
        
    }
    
}

public func logMessage(log : LogService, _ s: Any..., terminator: String = "\n", console : Bool = true) {
    let console = LogService.toConsole(console)
    if console {print(Date().timeStamp(), separator: "", terminator: " : ")}
    log.write("[\(Date().timeStamp())]", terminator: " : ")
    for i in s {
        if console { print(i, separator: "", terminator: "") }
        log.write(i, terminator: "")
    }
    log.write("", terminator: terminator)
    if console { print("", separator: "", terminator: terminator)}
    
}
