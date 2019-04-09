//
//  LoginViewController.swift
//  MQTTool
//
//  Created by Brent Petit on 2/18/16.
//  Copyright © 2016-2019 Brent Petit. All rights reserved.
//

import UIKit
import CoreData
import Security

// Track the state of the connection
var mqttConnection: MQTToolConnection?
var connectionState = ConnectionState.Disconnected

var userSettings = UserSettings()

let networkNotify = "com.brentpetit.MQTTool.networkNotify"
let queue = DispatchQueue(label: "com.brentpetit.MQTTool.queue.connect")

class LoginViewController: UIViewController, UITextFieldDelegate {

    var timer: Timer!
    
    var gradientView = GradientView()
    
    var defaultClientId = "MQTTool"
    
    @IBOutlet weak var clientIdTextField: UITextField!
    @IBOutlet weak var hostnameTextField: UITextField!
    @IBOutlet weak var hostPortTextField: UITextField!
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var savePasswordSwitch: UISwitch!
    @IBOutlet weak var historyButton: UIButton!
    
    @IBOutlet weak var connectButton: UIButton!
    @IBOutlet weak var cleanSessionSwitch: UISwitch!

    
    @IBOutlet weak var connectionStatusLabel: UILabel!
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        // Initialize Tab Bar Item
        tabBarItem = UITabBarItem(title: "Connect", image: UIImage(named: "Connect.png"), tag: 1)

    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        let randomValue = arc4random()
        // print(randomValue)
        self.defaultClientId = "MQTTool-\(randomValue)"
        clientIdTextField.placeholder = self.defaultClientId
        
        let gradientView = GradientView(frame: self.view.bounds)
        self.view.insertSubview(gradientView, at: 0)
        
        clientIdTextField.delegate = self
        hostnameTextField.delegate = self
        hostPortTextField.delegate = self
        usernameTextField.delegate = self
        passwordTextField.delegate = self
        
        loadDefaults()
    }
    
    // Just call the function to update the UI
    override func viewWillAppear(_ animated: Bool) {
        updateUI()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // General purpose function to update UI fields based on 
    // the state of the connection
    func updateUI() {
        DispatchQueue.main.async() {
            if(connectionState == .Connected) {
                if(mqttConnection != nil) {
                    if(mqttConnection!.hostName.isEmpty) {
                        // TODO: Update this...
                        if let hostname = self.hostnameTextField.text {
                            mqttConnection!.hostName = hostname
                        } else {
                            // bogus input
                            return
                        }
                        if let port_string = self.hostPortTextField.text {
                            if let port = Int64(port_string) {
                                mqttConnection!.hostPort = "\(port)"
                            } else {
                                // bogus input
                                return
                            }
                        } else {
                            // bogus input
                            return
                        }
                    }
                    self.hostnameTextField.text = mqttConnection!.hostName
                    self.hostPortTextField.text = mqttConnection!.hostPort
                    self.connectionStatusLabel.text = "Status: Connected to " + mqttConnection!.hostName + ":" +
                        mqttConnection!.hostPort
                    self.connectButton.setTitle("Disconnect", for: .normal)
                } else {
                    self.connectionStatusLabel.text = "Status: Error - connect failed"
                }
            } else if(connectionState == .Connecting) {
                if(mqttConnection != nil) {
                    //self.hostnameTextField.text = mqttConnection!.hostName
                    //self.hostPortTextField.text = mqttConnection!.hostPort
                    self.connectionStatusLabel.text = "Status: Connecting to " +
                                self.hostnameTextField.text! + ":" +
                                self.hostPortTextField.text!
                } else {
                    self.connectionStatusLabel.text = "Status: Connecting..."
                }
                self.connectButton.setTitle("Cancel", for: .normal)
            } else {
                
                self.connectionStatusLabel.text = "Status: Disconnected"
                self.connectButton.setTitle("Connect", for: .normal)
            }
        }
    }
    
    // When the view is first loaded, load the last saved settings for the connect tab
    func loadDefaults() {
        
        if ( userSettings.retrieveConnections() &&
             userSettings.connection_list != nil ) {
            
            print("loadDefaults... item count = \(userSettings.connection_list!.count)")
            if let latest = userSettings.connection_list!.first {
            print("in loadDefaults... found\n")
            
                self.hostnameTextField.text = latest.hostname
                self.hostPortTextField.text = "\(latest.port)"
                self.clientIdTextField.text = latest.sessionID
                self.usernameTextField.text = latest.username
                self.passwordTextField.text = latest.password
                self.savePasswordSwitch.isOn = latest.savepassword
            }
        } else {
            print("in loadDefaults... not found\n")
        }
    }
    
    // Save the current settings on the connect tab
    func saveDefaults() {
        var port: Int64?
        var password: String?
        // Save off the settings
        print("in saveDefaults... ")
        port = Int64(self.hostPortTextField.text!)
        
        if (self.hostnameTextField.text == nil ||
            port == nil) {
            print("saveDefaults... hostname or port not set")
            return
        }
        
        // Pass nil into save function if savePassword is off
        if (self.savePasswordSwitch!.isOn) {
            password = self.passwordTextField.text
        }
        
        userSettings.updateConnection(hostname: self.hostnameTextField.text!,
                                      port: port!,
                                      sessionID: self.clientIdTextField.text!,
                                      clean: self.cleanSessionSwitch.isOn,
                                      username: self.usernameTextField.text,
                                      password: password)
        
        print("done\n")
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            // Dismiss the keyboard
            DispatchQueue.main.async() {
                textField.resignFirstResponder()
            }
        return true
    }
    
    @IBAction func connectButtonPressed() {
        print("Your pressed the " + (connectButton.titleLabel?.text)! + " button")
        // Check that we didn't automatically reconnect and the UI is out of sync
        if let isConnected = mqttConnection?.mqttClient?.isConnected {
            if(isConnected == true && connectionState != .Connected) {
                print("Oops, I'm already connected")
                handleConnect(returnString: "Automatically Connected")
                return
            }
        }
        
        // Fall out early if the host or port is empty
        if(self.hostnameTextField.text!.isEmpty) {
            DispatchQueue.main.async() {
                self.connectionStatusLabel.text = "Status: Error - Bad host value"
            }
            return
        }
        if(self.hostPortTextField.text!.isEmpty) {
            DispatchQueue.main.async() {
                self.connectionStatusLabel.text = "Status: Error - Bad port value"
            }
            return
        }
       
        if(connectionState == .Disconnected) {
            var clientId: String
            mqttConnection = nil

            print("Connecting...")
            
            DispatchQueue.main.async() {
                if(self.clientIdTextField.text!.isEmpty) {
                    self.clientIdTextField.text = self.clientIdTextField.placeholder
                }
            }
            
            self.handleConnecting()
            
            if(self.clientIdTextField.text!.isEmpty) {
                clientId = self.clientIdTextField.placeholder!
            } else {
                clientId = self.clientIdTextField.text!
            }
            
            // Was a clean or durable session requested?
            let cleanSession = self.cleanSessionSwitch.isOn
            let username = self.usernameTextField.text
            let password = self.passwordTextField.text
            let hostname = self.hostnameTextField.text
            let port = self.hostPortTextField.text

            // If there is an object, dereference it here before the next connection. 
            // This prevents the disconnect handler from ripping the object out from 
            //  under other views...
            DispatchQueue.global(qos: .userInitiated).async {
                // Make sure there isn't a lingering connection attempt out there
                if(mqttConnection != nil) {
                    mqttConnection!.disconnect()
                    mqttConnection = nil
                }
                if(username != "" && password != "") {
                    mqttConnection = MQTToolConnection(hostname: hostname!,
                                                       port: port!,
                                                       username: username!,
                                                       password: password!,
                                                       clientId: clientId)
                    
                } else {
                    // We're not using the login info, don't save anything
                    DispatchQueue.main.async() {
                        self.savePasswordSwitch.isOn = false
                    }
                    mqttConnection = MQTToolConnection(hostname: hostname!,
                                                       port: port!,
                                                       username: nil,
                                                       password: nil,
                                                       clientId: clientId)
                }
                
                // Verify that the Connection object was successfully created
                if(mqttConnection != nil) {
                    mqttConnection!.setCleanSession(option: cleanSession)
                    mqttConnection!.setDisconnectCallback(callback: self.setDisconnected)
                    mqttConnection!.setConnectCallback(callback: self.setConnected)
                    
                    // We are connecting, save off the current settings
                    DispatchQueue.main.async() {
                        self.saveDefaults()
                    }
                
                    print("Going into connect()")
                    if(mqttConnection!.connect() == false) {
                        self.handleDisconnect(disconnectString: "Failed to create connection")
                    }
                    
                    self.handleConnecting()
                    
                } else {
                    print("Failed to create mqttConnection")
                    self.handleDisconnect(disconnectString: "Failed to create connection")
                }
            }
        } else if(connectionState == .Connected) {
            print("Disconnecting...")
            handleDisconnect(disconnectString: "User Request")
            if(mqttConnection != nil) {
                DispatchQueue.global(qos: .userInitiated).async {
                    mqttConnection!.disconnect()
                }
            }
            connectionState = .Disconnected
        } else if (connectionState == .Connecting) {
            print("Cancelling connection")
            if(mqttConnection != nil) {
                DispatchQueue.global(qos: .userInitiated).async {
                    mqttConnection!.disconnect()
                }
            }
            handleDisconnect(disconnectString: "Connect Cancelled")
        }
        
        saveDefaults()
        
    }

    
    // Callbacks for handling a connect or disconnect event
    func setConnected(returnValue: Int, returnString: String) {
        
        print("In setConnected returnValue=\(returnValue) returnString=\(returnString)")
        
        queue.sync() {
            if(returnValue == 0) {
                self.handleConnect(returnString: returnString)
            } else {
                // Error
                self.handleConnectError(errorString: returnString)
            }

            NotificationCenter.default.post(name: NSNotification.Name(rawValue: networkNotify), object: self)
        }
    }
    
    func setDisconnected(returnValue: Int, returnString: String) {
        
        print("In setDisconnected returnValue=\(returnValue) returnString=\(returnString)")
        
        queue.sync() {
            DispatchQueue.main.async() {
                self.connectionStatusLabel.text = "Status Disconnected: \(returnString)"
            }
            self.handleDisconnect(disconnectString: returnString)
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: networkNotify), object: self)
        }
    }
    
    // Update state in UI to reflect that we are connected
    //
    func handleConnecting() {
        connectionState = .Connecting
        updateUI()
    }
    
    // Update state in UI to reflect that we are connected
    //
    func handleConnect(returnString: String) {
        connectionState = .Connected
        updateUI()
    }
    
    // Update state in UI to reflect that we are disconnected
    //
    func handleDisconnect(disconnectString: String) {
        connectionState = .Disconnected
        updateUI()
        DispatchQueue.main.async() {
            self.connectionStatusLabel.text = "Status: Disconnected " + disconnectString
        }
    }
    
    func handleConnectError(errorString: String) {
        DispatchQueue.main.async() {
            self.connectionStatusLabel.text = "Status: Error connecting " + errorString
        }
        if(mqttConnection != nil) {
            mqttConnection!.disconnect()
        }
    }
    
    @IBAction func historyButtonPressed(_ sender: UIButton) {
        let alertController: UIAlertController
        
        if (userSettings.retrieveConnections() == false ||
            userSettings.connection_list == nil ||
            userSettings.connection_list!.count == 0) {
            
            alertController = UIAlertController(title: "Alert", message: "No history available", preferredStyle: .alert)
            
            alertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Default action"), style: .default, handler: { _ in
                NSLog("The \"OK\" alert occured.")
            }))
        } else {
        
            alertController = UIAlertController(title: "Connect History", message: "Select a host", preferredStyle: .actionSheet)
        
            for setting in userSettings.connection_list! {
                alertController.addAction(UIAlertAction(title: "\(setting.hostname!):\(setting.port)", style: .default, handler: { (action) in
                    //execute some code when this option is selected
                    print("\(setting.hostname!) selected")
                    self.hostnameTextField.text = setting.hostname
                    self.hostPortTextField.text = "\(setting.port)"
                    self.clientIdTextField.text = setting.sessionID
                    self.usernameTextField.text = setting.username
                    self.passwordTextField.text = setting.password
                    self.savePasswordSwitch.isOn = setting.savepassword
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
