//
//  MyMessageTableViewCell.swift
//  FMDBTest
//
//  Created by Semen Matsepura on 01.02.16.
//  Copyright © 2016 Semen Matsepura. All rights reserved.
//

import UIKit

class MyMessageTableViewCell: UITableViewCell {

    @IBOutlet weak var myMessageTextLabel: UILabel!
    @IBOutlet weak var myImageView: UIImageView!
    @IBOutlet weak var senderMessageTextLabel: UILabel!
    @IBOutlet weak var senderImageView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
}