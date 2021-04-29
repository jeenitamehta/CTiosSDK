//
//  ViewController.swift
//  CTios
//
//  Created by Jeenita Yatin Mehta on 26/04/21.
//

import UIKit
import CleverTapSDK

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        CleverTap.sharedInstance()?.recordEvent("Product viewed")
        let profile: Dictionary<String, AnyObject> = [
            //Update pre-defined profile properties
            "Name": "jm" as AnyObject,
            "Identity": 1026032 as AnyObject,
            "Email": "jeeni.ct@gmail.com" as AnyObject,
            //Update custom profile properties
            "Plan type": "Silver" as AnyObject,
            "Favorite Food": "Pizza" as AnyObject
        ]

        CleverTap.sharedInstance()?.onUserLogin(profile)
        // Do any additional setup after loading the view.
        #if DEBUG
            CleverTap.setDebugLevel(CleverTapLogLevel.debug.rawValue)
        #else
            CleverTap.setDebugLevel(CleverTapLogLevel.off.rawValue)
        #endif
    }


}

