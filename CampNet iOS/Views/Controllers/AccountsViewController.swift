//
//  AccountsViewController.swift
//  CampNet iOS
//
//  Created by Thomas Lee on 2017/7/13.
//  Copyright © 2017年 Sihan Li. All rights reserved.
//

import UIKit
import PromiseKit
import CampNetKit

class AccountsViewController: UITableViewController {

    @IBAction func cancelAddingAccount(segue: UIStoryboardSegue) {}
    @IBAction func accountAdded(segue: UIStoryboardSegue) {}
    @IBAction func cancelChangingPassword(segue: UIStoryboardSegue) {}
    @IBAction func passwordChanged(segue: UIStoryboardSegue) {
        if let controller = segue.source as? ChangePasswordViewController {
            _ = updateProfile(of: controller.account)
        }
    }
    
    var accounts: [(configuration: Configuration, accounts: [Account])] = []
    var mainAccount: Account? = nil
    
    func account(at indexPath: IndexPath) -> Account {
        return accounts[indexPath.section].accounts[indexPath.row]
    }
    
    func indexPath(of account: Account?) -> IndexPath? {
        guard let account = account else {
            return nil
        }

        for (section, tuple) in accounts.enumerated() {
            if tuple.configuration != account.configuration {
                continue
            }
            for (row, entry) in tuple.accounts.enumerated() {
                if entry == account {
                    return IndexPath(row: row, section: section)
                }
            }
        }
        return nil
    }
    
    func accountAdded(_ notification: Notification) {
        if let account = notification.userInfo?["account"] as? Account {
            _ = updateProfile(of: account)  // Update the new account in the background.
            
            // Insert account into the table.
            let identifier = account.configuration.identifier
            let name = account.configuration.displayName
            let username = account.username
            
            for (section, tuple) in accounts.enumerated() {
                if tuple.configuration.displayName < name ||
                   tuple.configuration.displayName == name && tuple.configuration.identifier < identifier {
                    continue
                } else if tuple.configuration.displayName == name && tuple.configuration.identifier == identifier {
                    
                    // Insert row.
                    for (row, entry) in tuple.accounts.enumerated() {
                        if entry.username < username {
                            continue
                        } else if entry.username == username {
                            // Account already exists.
                            return
                        } else {
                            // Insert here.
                            insertRow(section: section, row: row, account: account)
                            return
                        }
                    }
                    // Insert row at the end.
                    insertRow(section: section, row: tuple.accounts.count, account: account)
                    return
                } else {
                    // Insert section.
                    insertSection(section: section, account: account)
                    return
                }
            }
            // Insert section at the end.
            insertSection(section: accounts.count, account: account)
        }
    }
    
    func insertRow(section: Int, row: Int, account: Account) {
        accounts[section].accounts.insert(account, at: row)
        tableView.insertRows(at: [IndexPath(row: row, section: section)], with: .automatic)
    }
    
    func insertSection(section: Int, account: Account) {
        accounts.insert((configuration: account.configuration, accounts: [account]), at: section)
        tableView.insertSections(IndexSet(integer: section), with: .automatic)
    }
    
    func accountRemoved(_ notification: Notification) {
        if let indexPath = indexPath(of: notification.userInfo?["account"] as? Account) {
            
            accounts[indexPath.section].accounts.remove(at: indexPath.row)
            if accounts[indexPath.section].accounts.isEmpty {
                accounts.remove(at: indexPath.section)
                tableView.deleteSections(IndexSet(integer: indexPath.section), with: .automatic)
            } else {
                tableView.deleteRows(at: [indexPath], with: .automatic)
            }
        }
    }
    
    func mainChanged(_ notification: Notification) {
        if let fromIndexPath = indexPath(of: notification.userInfo?["fromAccount"] as? Account) {
            tableView.cellForRow(at: fromIndexPath)?.accessoryType = .none
        }
        mainAccount = notification.userInfo?["toAccount"] as? Account
        if let toIndexPath = indexPath(of: mainAccount) {
            tableView.cellForRow(at: toIndexPath)?.accessoryType = .checkmark
        }
    }
    
    func profileUpdated(_ notification: Notification) {
        guard let account = notification.userInfo?["account"] as? Account,
              let profile = notification.userInfo?["profile"] as? Profile,
              let indexPath = indexPath(of: account) else {
            return
        }
        
        let cell = tableView.cellForRow(at: indexPath) as! AccountCell
        cell.update(profile: profile, decimalUnits: account.configuration.decimalUnits)
    }
    
    func authorizationChanged(_ notification: Notification) {
        guard let account = notification.userInfo?["account"] as? Account,
              let indexPath = indexPath(of: account) else {
            return
        }
        let cell = tableView.cellForRow(at: indexPath) as! AccountCell
        cell.unauthorized = account.unauthorized
    }
    
    func updateProfile(of account: Account) -> Promise<Profile> {
        let delegate = UIApplication.shared.delegate as! AppDelegate
        
        delegate.setNetworkActivityIndicatorVisible(true)
        return account.profile(on: DispatchQueue.global(qos: .userInitiated)).always {
            delegate.setNetworkActivityIndicatorVisible(false)
            }
    }
    
    func refresh(sender:AnyObject)
    {
        var promises: [Promise<Profile>] = []
        for (_, accountArray) in accounts {
            for account in accountArray {
                let promise = updateProfile(of: account)
                promises.append(promise)
            }
        }
        
        when(resolved: promises).always { _ in
            self.refreshControl?.endRefreshing()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()

        // Set accounts.
        var allAccounts = Account.all
        
        for configuration in allAccounts.keys {
            allAccounts[configuration]!.sort { $0.username < $1.username }
        }
        for (configuration, accounts) in allAccounts {
            self.accounts.append((configuration, accounts))
        }

        accounts.sort { $0.configuration.displayName < $1.configuration.displayName ||
                        $0.configuration.displayName == $1.configuration.displayName && $0.configuration.identifier < $1.configuration.identifier }
        
        // Set mainAccount.
        self.mainAccount = Account.main
        
        self.refreshControl?.addTarget(self, action: #selector(refresh(sender:)), for: .valueChanged)
        
        // Set observers.
        NotificationCenter.default.addObserver(self, selector: #selector(accountAdded(_:)), name: .accountAdded, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(accountRemoved(_:)), name: .accountRemoved, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(mainChanged(_:)), name: .mainAccountChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(profileUpdated(_:)), name: .accountProfileUpdated, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(authorizationChanged(_:)), name: .accountAuthorizationChanged, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return accounts.count + 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return section < accounts.count ? accounts[section].accounts.count : 1
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return section < accounts.count ? accounts[section].configuration.displayName : nil
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section < accounts.count {
            let cell = tableView.dequeueReusableCell(withIdentifier: "accountCell", for: indexPath) as! AccountCell
            
            // Configure the cell...
            let account = self.account(at: indexPath)
            let profile = account.profile
            
            cell.username.text = account.username
            cell.unauthorized = account.unauthorized
            cell.update(profile: profile, decimalUnits: account.configuration.decimalUnits)
            cell.accessoryType = (account == mainAccount) ? .checkmark : .none
            
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "addAccountCell", for: indexPath)
            
            return cell
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section < accounts.count {
            let account = self.account(at: indexPath)
            Account.makeMain(account)
            
            
        }
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
    
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let changePasswordAction = UITableViewRowAction(style: .normal, title: NSLocalizedString("Change\nPassword", comment: "Action to change the password of an account in the account list.")) { (action, indexPath) in
            let cell = tableView.cellForRow(at: indexPath)
            self.performSegue(withIdentifier: "changePassword", sender: cell)
            
            tableView.setEditing(false, animated: true)
        }
        
        let deleteAction = UITableViewRowAction(style: .destructive, title: NSLocalizedString("Delete", comment: "Action to delete an account in the account list.")) { (action, indexPath) in
            Account.remove(self.account(at: indexPath))
            
            tableView.setEditing(false, animated: true)
        }
        
        return [deleteAction, changePasswordAction]
    }

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        
        if segue.identifier == "changePassword" {
            if let indexPath = tableView.indexPath(for: sender as! AccountCell) {
                let controller = segue.destination as! ChangePasswordViewController
                controller.account = account(at: indexPath)
            }
        }
    }

}
