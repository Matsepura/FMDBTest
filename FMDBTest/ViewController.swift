//
//  ViewController.swift
//  FMDBTest
//
//  Created by Semen Matsepura on 29.01.16.
//  Copyright © 2016 Semen Matsepura. All rights reserved.
//

import UIKit
import FMDB

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    //MARK: - Property
    
    @IBOutlet weak var bottomConstraint: NSLayoutConstraint!
    
    @IBOutlet var footer: UIView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var messageField: UITextField!
    @IBOutlet weak var sendMessageButton: UIButton!
    
    var loadMoreStatus = false
    var fileURL: NSURL!
    var dbWriter: FMDatabaseQueue!
    var dbReader: FMDatabaseQueue!
    var countOfLoadedMessges = 0
    var isLoadingMessages = false
    
    lazy var messages: [String] = []
    
    //MARK: - Setup
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.navigationBar.titleTextAttributes = [
            NSForegroundColorAttributeName : UIColor.lightGrayColor(),
            NSFontAttributeName : UIFont.systemFontOfSize(18, weight: UIFontWeightThin)
        ]
        self.navigationController?.navigationBar.tintColor = UIColor.lightGrayColor()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("keyboardWillShow:"), name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("keyboardWillHide:"), name: UIKeyboardWillHideNotification, object: nil)
        
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: "dismissKeyboard")
        view.addGestureRecognizer(tap)
        
        tableView.delegate = self
        tableView.dataSource = self
        self.tableView.tableFooterView = UIView()
        
        self.tableView.estimatedRowHeight = 60
        self.tableView.rowHeight = UITableViewAutomaticDimension
        
        self.fileURL = getDatabaseURL()
        
        self.cleanDatabase()
        self.createReaderWriter()
        self.createDatabase()
        
        self.messages = self.readDatabase(nil, limit: 40)
        self.tableView.setContentOffset(CGPointMake(0, CGFloat.max), animated: true)
    }
    
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        if tableView.contentSize.height > tableView.frame.size.height {
            let offset: CGPoint = CGPointMake(0, tableView.contentSize.height - tableView.frame.size.height)
            self.tableView.setContentOffset(offset, animated: true)
        }
    }
    
    func scrollToBottom() {
        
        self.tableView.scrollRectToVisible(CGRectMake(0, self.tableView.contentSize.height - self.tableView.bounds.size.height , self.tableView.bounds.size.width, self.tableView.bounds.size.height), animated: true)
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    // MARK: - Table view data source
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        var cell: MyMessageTableViewCell
        
        // аля два человека, создание двух бабл ячеек
        if indexPath.row % 2 == 0 {
            
            cell = tableView.dequeueReusableCellWithIdentifier("cellMyself", forIndexPath: indexPath) as! MyMessageTableViewCell
            if self.getMessageFromId(self.messages[indexPath.row]) == "message_text-196" || self.getMessageFromId(self.messages[indexPath.row]) == "message_text-191" {
                
                /*
                тут я вывожу картинку и выдает такую хрень
                2016-02-02 13:52:48.678 FMDBTest[495:138762] Warning once only:
                Detected a case where constraints ambiguously suggest a height
                of zero for a tableview cell's content view. We're considering
                the collapse unintentional and using standard height instead.
                saveToDataBase
                */
                
                self.tableView.layoutIfNeeded()
                cell = tableView.dequeueReusableCellWithIdentifier("myCellWithImage", forIndexPath: indexPath) as! MyMessageTableViewCell
                cell.myImageView.backgroundColor = UIColor.lightGrayColor()
            } else {
                cell.myMessageTextLabel.text = self.getMessageFromId(self.messages[indexPath.row])
            }
        } else {
            cell = tableView.dequeueReusableCellWithIdentifier("cellSender", forIndexPath: indexPath) as! MyMessageTableViewCell
            if self.getMessageFromId(self.messages[indexPath.row]) == "message_text-191" || self.getMessageFromId(self.messages[indexPath.row]) == "message_text-196" {
                
                /*
                тут я вывожу картинку и выдает такую хрень
                2016-02-02 13:52:48.678 FMDBTest[495:138762] Warning once only:
                Detected a case where constraints ambiguously suggest a height
                of zero for a tableview cell's content view. We're considering
                the collapse unintentional and using standard height instead.
                saveToDataBase
                */
                
                self.tableView.layoutIfNeeded()
                cell = tableView.dequeueReusableCellWithIdentifier("senderCellWithImage", forIndexPath: indexPath) as! MyMessageTableViewCell
                cell.myImageView.backgroundColor = UIColor.lightGrayColor()
            } else {
                cell.senderMessageTextLabel.text = self.getMessageFromId(self.messages[indexPath.row])
            }
        }
        
        //        if let cell = cell as? MyMessageTableViewCell {
        //            cell.myMessageTextLabel.text = self.getMessageFromId(self.messages[indexPath.row])
        //        }
        
        return cell
    }
    
    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        //        cell.textLabel?.text = self.getMessageFromId(self.messages[indexPath.row])
    }
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        
        let scrollOffset: CGFloat = 0
        if scrollView.contentOffset.y <=  scrollOffset
            && !self.isLoadingMessages {
                
                self.isLoadingMessages = true
                let lastMessage = self.messages.first
                let newMessages = self.readDatabase(lastMessage, limit: 10)
                if newMessages.count > 0 {
                    
                    self.messages = newMessages + self.messages
                    self.tableView.reloadData()
                    self.tableView.scrollToRowAtIndexPath(NSIndexPath(forRow: 10, inSection: 0), atScrollPosition: .Top, animated: false)
                    
                    dispatch_async(dispatch_get_main_queue()) {
                        self.isLoadingMessages = false
                    }
                } else {
                    // здесь досоздаем базу данных и суём в начало общего массива
                    print("empty! \n need to append to array new record")
                    createDatabase()
                    dispatch_async(dispatch_get_main_queue()) {
                        let arrayToAppend = self.readDatabase(self.messages.last, limit: 50)
                        for i in 0...49 {
                            self.messages.insert(arrayToAppend[i], atIndex: i)
                        }
                        
                        self.isLoadingMessages = true
                        self.tableView.reloadData()
                        
                        self.tableView.scrollToRowAtIndexPath(NSIndexPath(forRow: 50, inSection: 0), atScrollPosition: .Top, animated: false)
                        
                        dispatch_async(dispatch_get_main_queue()) {
                            self.isLoadingMessages = false
                        }
                        
                    }
                    // здесь вместо return создавать новые объекты догружать и вставлять в начало общего массива
                }
        }
    }
    
    func loadedTrue() {
        self.isLoadingMessages = false
    }
    
    //MARK: - Keyboard show/hide
    
    func keyboardWillShow(notification: NSNotification) {
        UIView.animateWithDuration(0.1) {
            self.view.frame.origin.y -= self.getKeyboardHeightFromNotification(notification)
        }
    }
    
    func keyboardWillHide(notification: NSNotification) {
        UIView.animateWithDuration(0.1) {
            self.view.frame.origin.y += self.getKeyboardHeightFromNotification(notification)
        }
    }
    
    private func getKeyboardHeightFromNotification(notification: NSNotification) -> CGFloat {
        guard let info = notification.userInfo else { return 0 }
        guard let infoValue = info[UIKeyboardFrameEndUserInfoKey] as? NSValue else { return 0 }
        let keyboardFrame = infoValue.CGRectValue()
        return keyboardFrame.height
    }
    
    func dismissKeyboard() {
        view.endEditing(true)
    }
    
    //MARK: - Chat funcs
    
    @IBAction func sendMessage(sender: AnyObject) {
        
        guard let message = messageField.text else { return }
        
        // if ниже - это проверка на пустое поле (иначе сохраняет пустые поля аля баг)
        // может вывести в свич? чтобы потом сохранять отдельно картинки, текст, ничего, юрл и тд?
        
        if messageField.text != "" {
            self.saveToDataBase(message) { success in
                guard success else { return }
                guard self.messages.count > self.tableView.numberOfRowsInSection(0) else { return }
                self.tableView.reloadData()
                
                let height = self.tableView.contentSize.height - self.tableView.bounds.height
                self.tableView.contentOffset = CGPoint(x: 0, y: height)
            }
            messageField.text = ""
        }
    }
    
    func saveToDataBase(text: String, finishBlock: ((success: Bool) -> ())) {
        print("saveToDataBase")
        guard self.dbWriter != nil else { return }
        
        var success: Bool = false
        self.dbWriter.inTransaction { db, _ in
            
            let messageTime = NSDate().timeIntervalSince1970
            let messageId = "id-\(messageTime)"
            do {
                try db.executeUpdate("insert into test (message_text, message_id, time) values (?, ?, ?)",
                    values: [text, messageId, "\(messageTime)"])
                
                self.messages.append(messageId)
                
                success = true
            }
            catch {
                print(error)
                
                success = false
            }
        }
        
        finishBlock(success: success)
    }
    
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
                
                //
                
                
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