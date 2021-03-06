//
//  SessionsViewController.swift
//  CampNet iOS
//
//  Created by Thomas Lee on 2017/1/17.
//  Copyright © 2019年 Sihan Li. All rights reserved.
//

import UIKit

import Firebase
import SwiftRater
import CampNetKit

class SessionsViewController: UITableViewController {

    static let startTimeUpdateInterval: TimeInterval = 60

    @IBOutlet var loginIpButton: UIBarButtonItem!

    var account: Account?
    var sessions: [Session] = []
    var pastIps: [String] = []
    var currentIp: String?

    var startTimeTimer = Timer()

    var canLoginIp: Bool {
        return account?.configuration.actions[.loginIp] != nil
    }
    var canLogoutSession: Bool {
        return account?.configuration.actions[.logoutSession] != nil
    }

    @IBAction func cancelLoggingInIp(segue: UIStoryboardSegue) {}
    @IBAction func ipLoggedIn(segue: UIStoryboardSegue) {}
    @IBAction func sessionLoggedOut(segue: UIStoryboardSegue) {}

    @IBAction func refreshTable(_ sender: Any) {
        guard let account = account else {
            self.refreshControl?.endRefreshing()
            return
        }

        _ = account.profile().ensure {
            self.refreshControl?.endRefreshing()
        }

        Analytics.logEvent("sessions_refresh", parameters: nil)
    }

    func reloadSessions() {
        sessions = account?.profile?.sessions ?? []
        pastIps = account?.pastIps ?? []
        currentIp = WiFi.ip
    }

    func reload() {
        account = Account.main
        loginIpButton.isEnabled = canLoginIp

        reloadSessions()
    }

    @objc func mainChanged(_ notification: Notification) {
        reload()
        tableView.reloadData()
    }

    @objc func profileUpdated(_ notification: Notification) {
        guard let account = notification.userInfo?["account"] as? Account, self.account == account else {
            return
        }

        let oldIps = sessions.map({ $0.ip })
        reloadSessions()
        let ips = sessions.map({ $0.ip })

        if oldIps.isEmpty && ips.isEmpty {
            // Nothing needs to be done.
            return
        }
        if oldIps.isEmpty {
            tableView.insertSections(IndexSet(integer: 0), with: .left)
            return
        }
        if ips.isEmpty {
            tableView.deleteSections(IndexSet(integer: 0), with: .left)
            return
        }
        // Else manipulating rows in the section.

        var rowsToReload: [IndexPath] = []
        var rowsToDelete: [IndexPath] = []
        var rowsToInsert: [IndexPath] = []

        for (index, oldIp) in oldIps.enumerated() {
            let indexPath = IndexPath(row: index, section: 0)

            if !ips.contains(oldIp) {
                rowsToDelete.append(indexPath)
            }
        }

        for (index, ip) in ips.enumerated() {
            let indexPath = IndexPath(row: index, section: 0)

            if oldIps.contains(ip) {
                rowsToReload.append(indexPath)
            } else {
                rowsToInsert.append(indexPath)
            }
        }

        tableView.beginUpdates()
        tableView.deleteRows(at: rowsToDelete, with: .left)
        tableView.insertRows(at: rowsToInsert, with: .left)
        tableView.endUpdates()

        // Do not reload in the update block, or the animation will become weird.
        tableView.reloadRows(at: rowsToReload, with: .fade)
    }

    @objc func updateStartTimes() {
        for (index, session) in sessions.enumerated() {
            let cell = tableView.cellForRow(at: IndexPath(row: index, section: 0)) as? SessionCell
            cell?.updateStartTime(date: session.startTime)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()

        self.reload()

        NotificationCenter.default.addObserver(self, selector: #selector(mainChanged(_:)),
                                               name: .mainAccountChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(profileUpdated(_:)),
                                               name: .accountProfileUpdated, object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if refreshControl!.isRefreshing {
            // See https://stackoverflow.com/questions/21758892/uirefreshcontrol-stops-spinning-after-making-application-inactive
            let offset = tableView.contentOffset
            refreshControl?.endRefreshing()
            refreshControl?.beginRefreshing()
            tableView.contentOffset = offset
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        startTimeTimer = Timer.scheduledTimer(timeInterval: SessionsViewController.startTimeUpdateInterval,
                                              target: self, selector: #selector(updateStartTimes), userInfo: nil,
                                              repeats: true)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        startTimeTimer.invalidate()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func logout(session: Session) {
        guard let account = account else {
            return
        }

        _ = account.logoutSession(session: session).done {
            SwiftRater.incrementSignificantUsageCount()
        }
        Analytics.logEvent("foreground_logout_session", parameters: nil)
    }


    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        if sessions.isEmpty {
            let label = UILabel(frame: tableView.bounds)
            label.text = L10n.Sessions.EmptyView.title
            label.textColor = .lightGray
            label.textAlignment = .center
            label.font = .preferredFont(forTextStyle: .title1)

            tableView.backgroundView = label

            return 0
        } else {
            tableView.backgroundView = nil

            return 1
        }
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sessions.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "sessionCell", for: indexPath) as! SessionCell
        let session = sessions[indexPath.row]

        let type: SessionType
        if session.ip == currentIp {
            type = .current
        } else if pastIps.contains(session.ip) {
            type = .expired
        } else {
            type = .normal
        }
        cell.update(session: session, type: type, decimalUnits: account?.configuration.decimalUnits ?? false)

        return cell
    }

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return canLogoutSession
    }

    override func tableView(_ tableView: UITableView,
                            titleForDeleteConfirmationButtonForRowAt indexPath: IndexPath) -> String? {
        return L10n.Sessions.DeleteConfirmationButton.title
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle,
                            forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            logout(session: sessions[indexPath.row])
        }

        tableView.setEditing(false, animated: true)
    }


    /*
      Override to support rearranging the table view.
     override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

     }
     */

    /*
      Override to support conditional rearranging of the table view.
     override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
      Return false if you do not want the item to be re-orderable.
     return true
     }
     */

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        //Get the new view controller using segue.destinationViewController.
        //Pass the selected object to the new view controller.
        if segue.identifier == "sessionDetail" {
            let controller = segue.destination as! SessionDetailViewController

            controller.account = account!
            controller.session = sessions[tableView.indexPathForSelectedRow!.row]
        } else if segue.identifier == "loginIp" {
            let controller = (segue.destination as! UINavigationController).topViewController as! LoginIpViewController

            controller.account = account!
        }
     }
}
