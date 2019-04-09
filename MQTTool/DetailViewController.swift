//
//  DetailViewController.swift
//  MQTTool
//
//  Created by Brent Petit on 2/29/16.
//  Copyright © 2016-2019 Brent Petit. All rights reserved.
//

import UIKit

private var underlineAttrs = [
    NSAttributedString.Key.font: UIFont(name: "HelveticaNeue", size: 17)!,
    NSAttributedString.Key.foregroundColor: UIColor.white,
    NSAttributedString.Key.underlineStyle : 1] as [NSAttributedString.Key : Any]

private var normalAttrs = [
    NSAttributedString.Key.font: UIFont(name: "HelveticaNeue", size: 17)!,
    NSAttributedString.Key.foregroundColor: UIColor.white]

class DetailViewController: UIViewController {

    @IBOutlet weak var detailTextBox: UITextView!

    @IBOutlet weak var detailTopicButton: UIButton!
    //@IBOutlet weak var detailTopicLabel: UILabel!
    @IBOutlet weak var detailQosLabel: UILabel!
    @IBOutlet weak var detailMidLabel: UILabel!
    @IBOutlet weak var detailTimestampLabel: UILabel!
    
    var messageData: Data?
    var messageText: String?
    var messageTopic: String = ""
    var messageID: Int = 0
    var messageQOS: Int32 = 0
    var messageTimestamp = NSDate(timeIntervalSince1970: 0)
    // Others?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let gradientView = GradientView(frame: self.view.bounds)
        self.view.insertSubview(gradientView, at: 0)
        
        // detailTopicButton.setTitle("Topic: \(messageTopic)", for: .normal)
        let topicString = NSMutableAttributedString(string: "Topic: ", attributes: normalAttrs)
        topicString.append(NSMutableAttributedString(string:"\(messageTopic)", attributes: underlineAttrs))
        detailTopicButton.setAttributedTitle(topicString, for: .normal)
        
        detailQosLabel.text = "QOS: \(messageQOS)"
        
        detailMidLabel.text = "Message ID: \(messageID)"
        
        let formatter = DateFormatter()
        formatter.dateStyle = DateFormatter.Style.short
        formatter.timeStyle = .medium
        
        let dateString = formatter.string(from: messageTimestamp as Date)
        
        detailTimestampLabel.text = "Timestamp: \(dateString)"

        // Do any additional setup after loading the view.
        if(messageText != nil) {
            detailTextBox.text = messageText
        } else {
            if let messageDataString = messageData?.base64EncodedString() {
                detailTextBox.text = "\(messageDataString)"
            } else {
                detailTextBox.text = ""
            }
        }
 
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    @IBAction func dismissButton() {
        self.dismiss(animated: true, completion: nil)
    }
    

    @IBAction func topicButton(_ sender: UIButton) {

        let alertController: UIAlertController
        
        alertController = UIAlertController(title: "Modify Subscription", message: "Would you like to set the subscription to the topic: \"\(messageTopic)\"?", preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Default action"), style: .default, handler: { _ in
            
                print("The \"OK\" alert occured.")
            let userInfo = [ "topic": self.messageTopic] as [String: String]
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "updateSubscriptionTopic"), object: nil, userInfo: userInfo)
            // NotificationCenter.default.post(name: "reload", object: nil, userInfo: userInfo)
            
            self.dismiss(animated: true, completion: nil)
        }))
        
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action) in
                //execute some cancel stuff
                print("Cancelled")
            }))
        
        alertController.modalPresentationStyle = UIModalPresentationStyle.popover
        alertController.popoverPresentationController?.sourceView = sender // works for both iPhone & iPad
        alertController.popoverPresentationController?.sourceRect = CGRect(x: 0, y: 0, width: sender.frame.size.width, height: sender.frame.size.height)
        present(alertController, animated: true)
    }
}
