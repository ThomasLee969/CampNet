//
//  ConfigurationsViewController.swift
//  CampNet iOS
//
//  Created by Thomas Lee on 2017/7/13.
//  Copyright © 2017年 Sihan Li. All rights reserved.
//

import UIKit
import CampNetKit

class ConfigurationsViewController: UITableViewController {
    
    var names: [(key: String, value: String)]!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        
        self.names = Configuration.displayNames.sorted { $0.value < $1.value || $0.value == $1.value && $0.key < $1.key }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return names.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "configurationCell", for: indexPath) as! ConfigurationCell

        // Configure the cell...
        let (identifier, name) = names[indexPath.row]
        cell.logo.image = UIImage(named: identifier)
        cell.name.text = name
        cell.domain.text = identifier.components(separatedBy: ".").reversed().joined(separator: ".")

        return cell
    }

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        if segue.identifier == "showConfigurationSetup" {
            if let indexPath = tableView.indexPathForSelectedRow {
                let configurationIdentifier = names[indexPath.row].key
                let name = names[indexPath.row].value
                var existedUsernames: Set<String> = []
                for (configuration, accountArray) in Account.all {
                    if configuration.identifier == configurationIdentifier {
                        existedUsernames.formUnion(accountArray.map{ $0.username })
                        break
                    }
                }
                
                let controller = segue.destination as! ConfigurationSetupViewController
                controller.configurationIdentifier = configurationIdentifier
                controller.existedUsernames = existedUsernames
                controller.navigationItem.title = name
            }
        }
    }

}
