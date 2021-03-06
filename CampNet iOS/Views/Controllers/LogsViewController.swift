//
//  LogsViewController.swift
//  CampNet iOS
//
//  Created by Thomas Lee on 2017/8/23.
//  Copyright © 2019年 Sihan Li. All rights reserved.
//

import UIKit
import BRYXBanner

class LogsViewController: UIViewController {

    @IBOutlet var textView: UITextView!

    @IBAction func copyAll(_ sender: Any) {
        UIPasteboard.general.string = textView.text
        showSuccessBanner(title: L10n.Notifications.LogsCopied.title, duration: 0.6)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        let delegate = UIApplication.shared.delegate as! AppDelegate

        if let url = delegate.logFileURL {
            textView.text = (try? String(contentsOf: url, encoding: .utf8)) ?? ""
        } else {
            textView.text = ""
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
