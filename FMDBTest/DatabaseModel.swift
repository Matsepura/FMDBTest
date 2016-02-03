//
//  DatabaseModel.swift
//  FMDBTest
//
//  Created by Semen Matsepura on 03.02.16.
//  Copyright © 2016 Semen Matsepura. All rights reserved.
//

import UIKit
import FMDB

class DatabaseModel: NSObject {
    
    //MARK: - Property
    
//    var delegate: DatabaseModelDelegate?
    
    var dbWriter: FMDatabaseQueue!
    var dbReader: FMDatabaseQueue!
    var fileURL: NSURL!
    
    //MARK: - Database funcs
    
    func getMessageFromId(messageId: String) -> String? {
        guard let dbReader = self.dbReader else { return nil }

        var messageText: String?
        
        dbReader.inDatabase { db in
            
            do {
                let result = try db.executeQuery("select message_text from test where message_id = ?", values: [messageId])
                
                if result.next() {
                    messageText = result.stringForColumnIndex(0)
                }
                result.close()
            }
            catch {
                print(error)
            }
        }
        return messageText
    }
    
    func getDatabaseURL() -> NSURL {
        var fileURL = NSURL()
        if let documents = try? NSFileManager.defaultManager().URLForDirectory(.DocumentDirectory, inDomain: .UserDomainMask, appropriateForURL: nil, create: false) {
            
            fileURL = documents.URLByAppendingPathComponent("testy.sqlite")
        }
        return fileURL
    }
    
    func cleanDatabase() {
        guard let fileURL = self.fileURL else {
            print("no file")
            return
        }
        do {
            try NSFileManager.defaultManager().removeItemAtURL(fileURL)
        } catch {
            print("error cleaning database \(error)")
        }
    }
    
    func createReaderWriter() {
        self.dbWriter = FMDatabaseQueue(path: fileURL.absoluteString)
        self.dbWriter.inDatabase { db in
            db.executeStatements("PRAGMA journal_mode=WAL;")
        }
        
        self.dbWriter.inTransaction { db, _ in
            do {
                try db.executeUpdate("create table if not exists test(message_text text, message_id text, time real)", values: nil)
                try db.executeUpdate("CREATE INDEX if not exists test_index_omg on test (message_id)", values: nil)
            } catch let error as NSError {
                print("failed: \(error.localizedDescription)")
            }
        }
        
        self.dbReader = FMDatabaseQueue(path: fileURL.absoluteString)
    }
    
    func readDatabase(offset: String? = nil, limit: Int = -1) -> [String] {
        print("readDatabase")
        
        var resultArray: [String] = []
        //        let width: CGFloat = 0
        
        guard self.dbReader != nil else { return [] }
        self.dbReader.inDatabase { db in
            do {
                
                let rs: FMResultSet
                
                switch (offset, limit) {
                case (nil, let limit) where limit > 0:
                    rs = try db.executeQuery("select message_id from (select message_id, time from test order by time DESC limit ?) order by time ASC", values: [limit])
                case (let offset, let limit) where offset != nil && limit > 0:
                    rs = try db.executeQuery("select message_id from (select message_id, time from test where message_id < ? order by time DESC limit ?) order by time ASC", values: [offset!, limit])
                case (let offset, _) where offset != nil:
                    rs = try db.executeQuery("select message_id from test where message_id < ? order by time ASC", values: [offset!])
                default:
                    rs = try db.executeQuery("select message_id from test order by time ASC", values: nil)
                }

                while rs.next() {
                    guard let messageId = rs.stringForColumnIndex(0) else { continue }
                    resultArray.append(messageId)
                }
                
                rs.close()
            } catch let error as NSError {
                print("failed: \(error.localizedDescription)")
            }
        }
        return resultArray
    }
    
    func createDatabase() {
        print("createDatabase")
        guard self.dbWriter != nil else { return }
        
        self.dbWriter.inTransaction { db, _ in
            
            self.fillDB(db)
        }
    }
    
    func fillDB(db: FMDatabase) {
        for i in 0...199 {
            let dateFormatter = NSDateFormatter()
            dateFormatter.dateFormat = "MM/dd/yyyy HH:mm:ss:SSS"
            
            let messageTime = NSDate().timeIntervalSince1970
            
            do {
                try db.executeUpdate("insert into test (message_text, message_id, time) values (?, ?, ?)",
                    values: ["message_text-\(i)", "id-\(messageTime)", "\(messageTime)"])
            }
            catch {
                print(error)
            }
        }
        print("finished filling")
    }
    
}

//protocol DatabaseModelDelegate {
//    
////    var fileURL: NSURL {get}
//    
//    func cleanDatabase()
//    func createReaderWriter()
//    func createDatabase()
//       
//}