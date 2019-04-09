//
//  SettingsPopoverViewController.swift
//  MQTTool
//
//  Created by Brent Petit on 1/22/18.
//  Copyright © 2018-2019 Brent Petit. All rights reserved.
//

import Foundation
import UIKit

class SettingsPopoverViewController: UIViewController {
    
    @IBOutlet weak var detailTextBox: UITextView!
    @IBOutlet weak var detailTopicLabel: UILabel!
    @IBOutlet weak var detailQosLabel: UILabel!
    @IBOutlet weak var detailMidLabel: UILabel!
    
    var messageData: NSData = NSData()
    var messageText: String?
    var messageTopic: String = ""
    var messageID: Int = 0
    var messageQOS: Int32 = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let gradientView = GradientView(frame: self.view.bounds)
        self.view.insertSubview(gradientView, at: 0)
        
        detailTopicLabel.text = "Topic: \(messageTopic)"
        
        detailQosLabel.text = "QOS: \(messageQOS)"
        
        detailMidLabel.text = "Message ID: \(messageID)"
        
        // Do any additional setup after loading the view.
        if(messageText != nil) {
            detailTextBox.text = messageText
        } else {
            detailTextBox.text = "\(messageData.length) bytes of Raw Data"
        }
        
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    @IBAction func dismissButton() {
        self.dismiss(animated: true, completion: nil)
    }
}
