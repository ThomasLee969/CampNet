//
//  SupportUsViewController.swift
//  CampNet iOS
//
//  Created by Thomas Lee on 11/28/18.
//  Copyright © 2018 Sihan Li. All rights reserved.
//

import StoreKit
import UIKit

import BRYXBanner
import Firebase
import SwiftyBeaver
import SwiftRater
import SwiftyButton
import SwiftyStoreKit

import CampNetKit


class SupportUsViewController: UIViewController {

    let donateIdentifier = "me.clumsylee.CampNet.support"

    @IBOutlet var donateButton: PressableButton!
    @IBOutlet var rateButton: PressableButton!
    var donateProduct: SKProduct!

    @available(iOS 10.0, *)
    lazy var lightImpact = UIImpactFeedbackGenerator(style: .light)
    @available(iOS 10.0, *)
    lazy var mediumImpact = UIImpactFeedbackGenerator(style: .medium)

    @IBAction func restoreButtonPressed(_ sender: Any) {
        SwiftyStoreKit.restorePurchases(atomically: true) { results in
            if results.restoreFailedPurchases.count > 0 {
                log.error("Restore Failed: \(results.restoreFailedPurchases)")
                showErrorBanner(title: L10n.SupportUs.RestoreResult.failed,
                                body: (results.restoreFailedPurchases.first!.0 as NSError).localizedDescription)
            }
            else if results.restoredPurchases.count > 0 {
                log.info("Restore Success: \(results.restoredPurchases)")

                for purchase in results.restoredPurchases {
                    if purchase.productId == self.donateIdentifier {
                        self.donated()
                        showSuccessBanner(title: L10n.SupportUs.RestoreResult.restored, duration: 0.6)
                        break
                    }
                }
            }
            else {
                log.error("Nothing to Restore")
                showErrorBanner(title: L10n.SupportUs.RestoreResult.nothing)
            }
        }
    }

    @available(iOS 10.0, *)
    @IBAction func buttonDown(_ sender: Any) {
        mediumImpact.impactOccurred()
    }

    @available(iOS 10.0, *)
    @IBAction func buttonUp(_ sender: Any) {
        lightImpact.impactOccurred()
    }

    @IBAction func donateButtonPressed(_ sender: Any) {
        Analytics.logEvent("donate_button_pressed", parameters: ["donated": Defaults[.donated] ? 1 : 0])

        if Defaults[.donated] {
            donated()
            return
        }

        SwiftyStoreKit.purchaseProduct(donateProduct, quantity: 1, atomically: true) { result in
            switch result {
            case .success(let purchase):
                log.info("Purchase Success: \(purchase.productId)")
                self.donated()
            case .error(let error):
                log.error("Failed to donate: \(error.localizedDescription)")
                if error.code != .paymentCancelled {
                    showErrorBanner(title: L10n.SupportUs.DonateError.title, body: error.localizedDescription)
                }
            }
        }
    }

    @IBAction func rateButtonPressed(_ sender: Any) {
        SwiftRater.rateApp()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        donateButton.disabledColors = .init(button: #colorLiteral(red: 0.501960814, green: 0.501960814, blue: 0.501960814, alpha: 1), shadow: #colorLiteral(red: 0.37, green: 0.37, blue: 0.37, alpha: 1))
        if Defaults[.donated] {
            donated()
        } else {
            donateButton.colors = .init(button: #colorLiteral(red: 0.9098039269, green: 0.4784313738, blue: 0.6431372762, alpha: 1), shadow: #colorLiteral(red: 0.78, green: 0.4101724125, blue: 0.5513793254, alpha: 1))
            donateButton.shadowHeight = 2
            donateButton.isEnabled = false

            Action.changeNetworkActivityCount(1)
            SwiftyStoreKit.retrieveProductsInfo([donateIdentifier]) { result in
                Action.changeNetworkActivityCount(-1)

                if let product = result.retrievedProducts.first {
                    self.donateProduct = product

                    let priceString = product.localizedPrice!
                    log.info("Product: \(product.localizedDescription), price: \(priceString)")
                    self.donateButton.titleLabel?.text = priceString
                    self.donateButton.setTitle("\(self.donateButton.titleLabel!.text!) \(priceString)", for: .normal)

                    self.donateButton.shadowHeight = 10
                    self.donateButton.isEnabled = true
                }
                else if let invalidProductId = result.invalidProductIDs.first {
                    log.error("Invalid product identifier: \(invalidProductId)")
                }
                else {
                    log.error("Error: \(String(describing: result.error))")
                }
            }
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        UIApplication.shared.applicationIconBadgeNumber = 0  // Page is shown, clear the badge.
    }

    func donated() {
        Defaults[.donated] = true
        Analytics.setUserProperty(Defaults[.donated].description, forName: "donated")
        
        donateButton.colors = .init(button: #colorLiteral(red: 0.5431281975, green: 0.89, blue: 0.3103589849, alpha: 1), shadow: #colorLiteral(red: 0.4666666687, green: 0.7647058964, blue: 0.2666666806, alpha: 1))
        donateButton.shadowHeight = 10
        donateButton.isEnabled = true
        donateButton.setTitle(L10n.SupportUs.DonateButton.Title.donated, for: .normal)
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
