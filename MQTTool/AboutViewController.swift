//
//  AboutViewController.swift
//  MQTTool
//
//  Created by Brent Petit on 2/18/16.
//  Copyright © 2016-2019 Brent Petit. All rights reserved.
//

import UIKit

private var underlineAttrs = [
    NSAttributedString.Key.font: UIFont(name: "HelveticaNeue", size: 14)!,
    NSAttributedString.Key.foregroundColor: UIColor.white,
    NSAttributedString.Key.underlineStyle : 1] as [NSAttributedString.Key : Any]

private var normalAttrs = [
    NSAttributedString.Key.font: UIFont(name: "HelveticaNeue", size: 14)!,
    NSAttributedString.Key.foregroundColor: UIColor.white]

class AboutViewController: UIViewController {
    
    @IBOutlet weak var aboutVersionString: UILabel!
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        // Initialize Tab Bar Item
        tabBarItem = UITabBarItem(title: "About", image: UIImage(named: "About.png"), tag: 1)
    }

    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        let gradientView = GradientView(frame: self.view.bounds)
        self.view.insertSubview(gradientView, at: 0)
        
        // Pull version from Bundle
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
        aboutVersionString.text = "v\(version)"
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
