//
//  CTiOSAudit.swift
//  CTiOSAudit
//
//  Created by Jay Mehta on 12/08/20.
//  Copyright © 2020 Jay Mehta. All rights reserved.
//

import Foundation

open class CTAudit {
    
    var chckSDKVersion = true ,chckCTID = true, onUserLogin = false, chckAutoIntegrate = true, chckInitialisation = true, checkIdentity = true, chckPN = true
    var eventsData : [[String : AnyObject]] = [[:]]
    var profileDetailsArray : [String : AnyObject] = [:]
    
    public init(){
        if let documentsPathString = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first {
                    let logPath = documentsPathString.appending("/app.txt")
                    freopen(logPath.cString(using: String.Encoding.ascii),"a+",stderr)
                }
    }
    
    public func startAudit(){
        DispatchQueue.main.asyncAfter(deadline: .now() + 60.0, execute: {
            self.getDataLogs()
        })
    }
    
    func getDataLogs() {
        do {
            // get the documents folder url
            if let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                let fileURL = documentDirectory.appendingPathComponent("app.txt")
                let savedText = try String(contentsOf: fileURL)
                let arrayOfLines =  savedText.components(separatedBy: .newlines)
                let filteredArray = arrayOfLines.filter {$0.contains("[CleverTap]:")}
                writeDataToFile(data: "AUDIT REPORT\n\n")
                pasrseLogs(dataLogs: filteredArray)
                
                if profileDetailsArray.count > 1{
                    if onUserLogin{
                        writeDataToFile(data: "***PROFILE DETAILS PASSED WITH ONUSERLOGIN***\n")
                        writeProfileDeatilsToFile()
                    }else{
                        writeDataToFile(data: "***PROFILE DETAILS PASSED WITH PUSHPROFILE***\n")
                        writeProfileDeatilsToFile()
                    }
                }
                
                writeDataToFile(data: "\n***ACTIVITY***\n")
                writeEventDataToFile()
                let file = FileManager.default
                try file.removeItem(at: fileURL)
            }
        } catch {
            print("error:", error)
        }
    }
    
    func pasrseLogs(dataLogs : [String]){
        
        eventsData.removeAll()
        for logs in dataLogs{
            if logs.contains("Auto Integration enabled"){
                if chckAutoIntegrate{
                    chckAutoIntegrate = false
                    let tempArr = logs.components(separatedBy: "[CleverTap]: ")
                    let strTemp = "\(tempArr[1])\n\n"
                    writeDataToFile(data: "***AUTO INTEGRATE***\n")
                    writeDataToFile(data: strTemp)
                }
            }else if logs.contains("Initializing"){
                if chckInitialisation{
                    chckInitialisation = false
                    checkForSDKInitialise(dataLogs: logs)
                }
            }else if logs.contains("registering APNs device token"){
                if chckPN{
                    chckPN = false
                    checkForPN(dataLogs: logs)
                }
            }else if logs.contains("onUserLogin"){
                if checkIdentity{
                    checkIdentity = false
                    onUserLogin = true
                    writeDataToFile(data: "***IDENTITY MANAGEMENT***\n")
                    writeDataToFile(data: "onUserLogin() method is used to push profile details\n\n")
                }
            }else if logs.contains("Sending"){
                if(chckSDKVersion && chckCTID){
                    checkForEventData(dataLogs: logs)
                    checkForMetaData(dataLogs: logs)
                }else{
                    checkForEventData(dataLogs: logs)
                }
                
            }
        }
    }
    
    func checkForPN(dataLogs : String){
        let tempArr = dataLogs.components(separatedBy: "token ")
        let strTemp = "\(tempArr[1])\n\n"
        writeDataToFile(data: "***Push Token Generated***\n")
        writeDataToFile(data: strTemp)
    }
    
    func checkForSDKInitialise(dataLogs : String) {
        let tempArr = dataLogs.components(separatedBy: "[CleverTap]: ")
        let strTemp = "\(tempArr[1])\n\n"
        writeDataToFile(data: "***SDK INITIALISED***\n")
        writeDataToFile(data: strTemp)
    }
    
    func checkForMetaData(dataLogs : String){
        let tempArr = dataLogs.components(separatedBy: "Sending ")
        let tempArr2 = tempArr[1].components(separatedBy: " to")
        let jsonDataMeta = convertStringToDictionary(text:tempArr2[0].dropFirst().dropLast().components(separatedBy: ",{")[0])
        let strTemp = "SDK Version : \(jsonDataMeta?["af"]?["SDK Version"] as! String)\nCTID : \(jsonDataMeta?["g"] as! String)\n\n"
        chckCTID = false
        chckSDKVersion = false
        writeDataToFile(data: "***METADATA***\n")
        writeDataToFile(data: strTemp)

    }
    
    
    func convertStringToDictionary(text: String) -> [String:AnyObject]? {
        if let data = text.data(using: .utf8) {
            do {
                let json = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String:AnyObject]
                return json
            } catch {
                print("Something went wrong")
            }
        }
        return nil
    }
    
    func checkForEventData(dataLogs : String){
        let tempArr = dataLogs.components(separatedBy: "Sending ")
        let tempArr2 = tempArr[1].components(separatedBy: " to")
        let tempArr3 = tempArr2[0].dropFirst().dropLast().components(separatedBy: ",{")
        if tempArr3.count > 2{
            for n in 1...tempArr3.count-1 {
                let strTemp = tempArr2[0].dropFirst().dropLast().components(separatedBy: ",{")[n]
                let mutableStr = NSMutableString(string: strTemp)
                mutableStr .insert("{", at: 0)
                let jsonDataEvent = convertStringToDictionary(text: mutableStr as String)
                checkForEvents(dataLogs: jsonDataEvent)
            }
            
        }else{
            let strTemp = tempArr2[0].dropFirst().dropLast().components(separatedBy: ",{")[1]
            let mutableStr = NSMutableString(string: strTemp)
            mutableStr .insert("{", at: 0)
            let jsonDataEvent = convertStringToDictionary(text: mutableStr as String)
            checkForEvents(dataLogs: jsonDataEvent)
        }
        
        

    }
    
    func checkForEvents(dataLogs : [String:AnyObject]?){
        if dataLogs?["type"] as! String == "profile" {
            let tempArr = dataLogs?["profile"] as! [String:AnyObject]
            profileDetailsArray.removeAll()
            profileDetailsArray = tempArr
//            for (key,value) in tempArr {
//                print("\(key) : \(value)")
//            }
        }else{
            if let eventName = dataLogs?["evtName"] as? String {
                    print("Event Triggered : ",eventName)
                    let tempArr = dataLogs?["evtData"] as! [String:AnyObject]
                    print("Properties :")
                    if tempArr.count == 0{
                        print("No properties passed")
                    }
                    var strTemp = ""
                    for (key,value) in tempArr {
                        strTemp.append("\(key) : \(value) | ")
                    }
                    strTemp = String(strTemp.dropLast().dropLast())
                    print(strTemp)
                    eventsData.append([dataLogs?["evtName"] as! String : strTemp as AnyObject])
                }
        }
        
    }
    
    func writeProfileDeatilsToFile(){
        for (key,value) in profileDetailsArray{
            let strTemp = "\(key) : \(value)\n"
            writeDataToFile(data: strTemp)
        }
    }
    
    func writeEventDataToFile() {
        for dict in eventsData {
            for (key,value) in dict{
                let strTemp = "Event Name : \(key)\nProperties : \(value)\n\n"
                writeDataToFile(data: strTemp)
            }
        }
    }
    
    func writeDataToFile(data : String) {
        let fileName = "AuditReport"
        let strData = data.data(using: String.Encoding.utf8, allowLossyConversion: false)!
        let documentDirectoryUrl = try! FileManager.default.url(
           for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true
        )
        let fileUrl = documentDirectoryUrl.appendingPathComponent(fileName).appendingPathExtension("txt")
        // prints the file path
        print("File path \(fileUrl.path)")
        if FileManager.default.fileExists(atPath: fileUrl.path){
            if let fileHandle = FileHandle(forUpdatingAtPath: fileUrl.path){
                fileHandle.seekToEndOfFile()
                fileHandle.write(strData)
                fileHandle.closeFile()
            }else{
                
            }
            
        }else{
            do {
               try data.write(to: fileUrl, atomically: true, encoding: String.Encoding.utf8)
            } catch let error as NSError {
               print (error)
            }
        }
    }
}
