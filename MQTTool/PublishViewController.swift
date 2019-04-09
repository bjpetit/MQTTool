//
//  PublishViewController.swift
//  MQTTool
//
//  Created by Brent Petit on 2/18/16.
//  Copyright © 2016-2019 Brent Petit. All rights reserved.
//

import UIKit

class PublishViewController: UIViewController, UITextFieldDelegate {
    
    // var priorPublishSettings = UserDefaults.standard
    var publishSetting: PublishSetting?
    
    @IBOutlet weak var topicTextField: UITextField!
    @IBOutlet weak var messageTextField: UITextField!
    @IBOutlet weak var publishQosSelect: UISegmentedControl!
    @IBOutlet weak var topicStatusLabel: UILabel!

    @IBOutlet weak var retainSwitch: UISwitch!
    @IBOutlet weak var publishButton: UIButton!
    @IBOutlet weak var historyButton: UIButton!
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        // Initialize Tab Bar Item
        tabBarItem = UITabBarItem(title: "Publish", image: UIImage(named: "Publish.png"), tag: 1)
    }

    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        let gradientView = GradientView(frame: self.view.bounds)
        self.view.insertSubview(gradientView, at: 0)
        
        topicTextField.delegate = self
        messageTextField.delegate = self
        
        
        loadDefaults()
        
        // Listen for changes in the network state so that we can update the UI state
        NotificationCenter.default.addObserver(self, selector: #selector(PublishViewController.actOnNetworkNotify), name: NSNotification.Name(rawValue: networkNotify), object: nil)
        
    }
    
    // When the view appears, update the UI status
    override func viewWillAppear(_ animated: Bool) {
        updateUIState()
    }
    
    // Allow the "Go" button to trigger the publish button
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            // Dismiss the keyboard
            DispatchQueue.main.async() {
                textField.resignFirstResponder()
            }
        return true
    }

    // Set the UI Fields based on whether we are connected to 
    // a broker or not
    func updateUIState() {
        DispatchQueue.main.async() {
            if(connectionState == .Connected) {
                self.publishButton.setTitle("Publish", for: .normal)
                self.publishButton.isEnabled = true
                self.topicStatusLabel.text = "Status: Ready"
                self.topicTextField.isEnabled = true
                self.messageTextField.isEnabled = true
                self.publishQosSelect.isEnabled = true
            } else {
                self.publishButton.setTitle("Disconnected", for: .normal)
                self.publishButton.isEnabled = false
                self.topicStatusLabel.text = "Status: Disconnected"
                self.topicTextField.isEnabled = false
                self.messageTextField.isEnabled = false
                self.publishQosSelect.isEnabled = false
            }
        }

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    // When the view is first loaded, load the last saved values
    func loadDefaults() {
        
        if ( userSettings.retrievePublishList() &&
             userSettings.publish_list != nil ) {
            print("loadDefaults... item count = \(userSettings.publish_list!.count)")

            if let latest = userSettings.publish_list!.first {
                print("in loadDefaults... found\n")
                
                self.topicTextField.text = latest.topic
                self.messageTextField.text = latest.message
                self.publishQosSelect.selectedSegmentIndex = Int(latest.qos)
                self.retainSwitch.isOn = latest.retainFlag
            }
        } else {
            print("in loadDefaults... not found\n")
        }
    }
    
    func saveDefaults() {
        // Save off the settings
        print("in saveDefaults... ")
        
        if (self.topicTextField.text == nil) {
            print("saveDefaults... connectionSetting not set")
            return
        }
        
        userSettings.updatePublish(topic: self.topicTextField.text!,
                                   message: self.messageTextField.text,
                                   qos: self.publishQosSelect.selectedSegmentIndex,
                                   retain: self.retainSwitch.isOn)
        print("done\n")
        
    }

    
    
    // The network state changed, update the UI to reflect
    //  the state
    @objc func actOnNetworkNotify() {
        updateUIState()
    }
    
    // Do the publish
    @IBAction func publishButtonPressed() {

        if( connectionState == .Connected) {
            var published = false
            if let topicText = topicTextField.text {
                if(topicText.isEmpty == false) {
                    var data = Data()
                    if let myData = messageTextField.text?.data(using: .utf8) {
                        data = myData
                    }
                    let qos = Int32(publishQosSelect.selectedSegmentIndex)
                    let retain = retainSwitch.isOn
                    var returnValue = 0
                    var messageNum = 0
                        
                    saveDefaults()
                        
                    print("publish button pressed")
                    published = true
                    DispatchQueue.global(qos: .background).sync {
                        (returnValue, messageNum) = mqttConnection!.publish(topic: topicText,
                                                                            message: data as NSData,
                                                                            qos: qos,
                                                                            retain: retain)
                    }
                    if(returnValue < 0) {
                        topicStatusLabel.text = "Status: Publish failed, code \(returnValue)"
                    } else {
                        topicStatusLabel.text = "Status: Publish succeeded (message# \(messageNum))"
                    }
                }
            }
            if(published == false) {
                topicStatusLabel.text = "Status: Failed to prepare message"

            }
        } else {
                publishButton.setTitle("Disconnected", for: .normal)
                publishButton.isEnabled = false
                topicStatusLabel.text = "Status: Disconnected"
        }
    }
    
    @IBAction func historyButtonPressed(_ sender: UIButton) {
    
        let alertController: UIAlertController
        
        if (userSettings.retrievePublishList() == false ||
            userSettings.publish_list == nil ||
            userSettings.publish_list!.count == 0) {
            alertController = UIAlertController(title: "Alert", message: "No history available", preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Default action"), style: .default, handler: { _ in
                NSLog("The \"OK\" alert occured.")
            }))
        } else {
            
            alertController = UIAlertController(title: "Publish History", message: "Select a topic", preferredStyle: .actionSheet)
            
            for setting in userSettings.publish_list! {
                alertController.addAction(UIAlertAction(title: "\(setting.topic!)", style: .default, handler: { (action) in
                    //execute some code when this option is selected
                    print("\(setting.topic!) selected")
                    self.topicTextField.text = setting.topic
                    self.messageTextField.text = setting.message
                    self.publishQosSelect.selectedSegmentIndex = Int(setting.qos)
                    self.retainSwitch.isOn = setting.retainFlag
                }))
            }
            alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action) in
                //execute some cancel stuff
                print("Cancelled")
            }))
        }
        alertController.modalPresentationStyle = UIModalPresentationStyle.popover
        alertController.popoverPresentationController?.sourceView = sender // works for both iPhone & iPad
        alertController.popoverPresentationController?.sourceRect = CGRect(x: 0, y: 0, width: sender.frame.size.width, height: sender.frame.size.height)
        present(alertController, animated: true)
    }    
}
