//
//  LogService.swift
//  zaraDatabaseWrapper
//
//  Created by home on 10/10/18.
//

import Foundation
import projectConstants

///The log class containing all the needed methods
open class LogService {
    
    public init(name : String) {
        self.name = name
    }
    ///The max size a log file can be in Kilobytes. Default is 1024 (1 MB)
    open var maxFileSize: UInt64 = 2048
    
    ///The max number of log file that will be stored. Once this point is reached, the oldest file is deleted.
    open var maxFileCount = 99999
    
    ///The directory in which the log files will be written
    open var directory : String {
        var directory = LogService.defaultDirectory()
        directory = NSString(string: directory).expandingTildeInPath
        
        let fileManager = FileManager.default
        if !fileManager.fileExists(atPath: directory) {
            do {
                try fileManager.createDirectory(atPath: directory, withIntermediateDirectories: true, attributes: nil)
            } catch {
                NSLog("Couldn't create directory at \(directory)")
            }
            
            
        }
        return LogService.defaultDirectory()
    }
    
    open var currentPath: String {
        return "\(directory)/\(logName(0))"
    }
    
    ///The name of the log files
    let name : String

    
    func start() {
            write("===========================================================")
            write("==========  START \(name) \(Date().timeStamp()) ===========")
            write("===========================================================")
    }

    
    ///Whether or not logging also prints to the console
    open var printToConsole = true
    
    //the date formatter
    var dateFormatter: DateFormatter {
        return Globals.Date.TimeStamp
    }
    
    ///write content to the current log file.
    open func write(_ text: Any, terminator: String = "\n") {
        let path = currentPath
        let fileManager = FileManager.default
        if !fileManager.fileExists(atPath: path) {
            do {
                try "".write(toFile: path, atomically: true, encoding: String.Encoding.utf8)
            } catch _ {
            }
        }
        if let fileHandle = FileHandle(forWritingAtPath: path) {
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
            
            fileHandle.seekToEndOfFile()
            fileHandle.write(writeText.data(using: String.Encoding.utf8)!)
            fileHandle.closeFile()
            cleanup()
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
        let attrs: NSDictionary? = try? fileManager.attributesOfItem(atPath: path) as NSDictionary
        if let dict = attrs {
            return dict.fileSize()
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
        write("====================================================")
        write("\(Date().timeStamp()) \(function) \(type)")
        write(xml)
        
    }
    
    ///gets the log name
    func logName(_ num :Int) -> String {
        return "\(name)-\(Date().dateString())-\(num).log"
    }
    
    ///get the default log directory
    class func defaultDirectory() -> String {
        var path = ""
        let fileManager = FileManager.default
        #if os(iOS)
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        path = "\(paths[0])/Logs"
        #elseif os(macOS)
        path = "/Users/server/logs/\(Date().dateString())"
        #endif
        if !fileManager.fileExists(atPath: path) && path != ""  {
            do {
                try fileManager.createDirectory(atPath: path, withIntermediateDirectories: false, attributes: nil)
            } catch _ {
            }
        }
        return path
    }
    
}

public func logMessage(log : LogService, _ s: Any...) {
    print(Date().timeStamp(), separator: "", terminator: " : ")
    log.write("[\(Date().timeStamp())]", terminator: " : ")
    for i in s {
        print(i, separator: "", terminator: "")
        log.write(i, terminator: "")
    }
    log.write("", terminator: "\n")
    print("", separator: "", terminator: "\n")
    
}
