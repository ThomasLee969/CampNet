//
//  SessionDetailCell.swift
//  CampNet iOS
//
//  Created by Thomas Lee on 2017/7/20.
//  Copyright © 2017年 Sihan Li. All rights reserved.
//

import UIKit

class SessionDetailCell: UITableViewCell {

    @IBOutlet var name: UILabel!
    @IBOutlet var value: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
