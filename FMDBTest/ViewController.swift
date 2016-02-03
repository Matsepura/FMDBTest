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
    
    let dataBaseManager = DatabaseModel()
    var loadMoreStatus = false
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
        
        self.dataBaseManager.fileURL = self.dataBaseManager.getDatabaseURL()
        
        self.dataBaseManager.cleanDatabase()
        self.dataBaseManager.createReaderWriter()
        self.dataBaseManager.createDatabase()
        
        self.messages = self.dataBaseManager.readDatabase(nil, limit: 40)
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
            if self.dataBaseManager.getMessageFromId(self.messages[indexPath.row]) == "message_text-196" || self.dataBaseManager.getMessageFromId(self.messages[indexPath.row]) == "message_text-191" {
                
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
                cell.myMessageTextLabel.text = self.dataBaseManager.getMessageFromId(self.messages[indexPath.row])
            }
        } else {
            cell = tableView.dequeueReusableCellWithIdentifier("cellSender", forIndexPath: indexPath) as! MyMessageTableViewCell
            if self.dataBaseManager.getMessageFromId(self.messages[indexPath.row]) == "message_text-191" || self.dataBaseManager.getMessageFromId(self.messages[indexPath.row]) == "message_text-196" {
                
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
                cell.senderMessageTextLabel.text = self.dataBaseManager.getMessageFromId(self.messages[indexPath.row])
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
                let newMessages = self.dataBaseManager.readDatabase(lastMessage, limit: 10)
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
                    self.dataBaseManager.createDatabase()
                    dispatch_async(dispatch_get_main_queue()) {
                        let arrayToAppend = self.dataBaseManager.readDatabase(self.messages.last, limit: 50)
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
        guard self.dataBaseManager.dbWriter != nil else { return }
        
        var success: Bool = false
        
        self.dataBaseManager.dbWriter.inTransaction { db, _ in
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
}