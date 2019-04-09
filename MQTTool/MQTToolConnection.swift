//
//  MQTToolConnections.swift
//  MQTTool
//
//  Created by Brent Petit on 2/17/16.
//  Copyright © 2016-2019 Brent Petit. All rights reserved.
//

import Foundation
import Moscapsule

enum ConnectionState { case Disconnected, Connected, Connecting }

struct MyMQTTMessage {
    let message: MQTTMessage
    let timestamp: NSDate
}

class MQTToolConnection {
    
    let mqttConfig: MQTTConfig
    var mqttClient: MQTTClient?
    
    var messageList: [MyMQTTMessage]
    
    // List of recent messages from MQTT message callback
    
    var maxMessageList = 50
    var newMessage = false
    let messageQueue = DispatchQueue(label: "com.brentpetit.MQTTool.messageQueue")
    
    var subscriptionTopic: String = ""
    var subscriptionQos: Int32 = 0
    var hostName = ""
    var hostPort = ""
    
    // Counters
    var messagesSent = 0
    var messagesReceived = 0
    var connectTime: NSDate?
    
    let maxDisconnectsInMinute = 10 // If we see more than 10 disconnects in a minute, diconnect hard
    var disconnectsInMinute = 0
    var disconnectTimestamp: Date?
    
    //
    // Init takes clientId, host and port
    // user and password can be nil, meaning anonymous connection
    //
    init?(hostname: String, port: String, username: String?, password: String?, clientId: String) {
        moscapsule_init()
        
        if let portNumber = Int32(port) {
            print("port = \(portNumber)\n")
            mqttConfig = MQTTConfig(clientId: clientId, host: hostname, port: portNumber, keepAlive: 60)
        } else {
            print("bad port\n")
            return nil
        }
        
        if(username != nil && password != nil) {
            mqttConfig.mqttAuthOpts = MQTTAuthOpts(username: username!, password: password!)
        }
        mqttClient = nil
        connectTime = nil
        hostName = hostname
        hostPort = port
        
        // Init an empty message list
        messageList = [MyMQTTMessage]()
    }
    
    deinit {
        disconnect()
        hostName = ""
        hostPort = ""
    }
    
    // Set the durability of the session
    func setCleanSession(option: Bool) {
        mqttConfig.cleanSession = option
    }

    
    func connect() -> Bool {
        // create new MQTT Connection
        mqttConfig.onMessageCallback = { mqttMessage in
            self.handleNewMessage(message: mqttMessage)
        }
        mqttConfig.onPublishCallback = { messageId in
            self.messagesSent += 1
            print("Published \(messageId)")
        }
        
        // Clean Session, subscribed topic is reset
        if(mqttConfig.cleanSession == true) {
            subscriptionTopic = ""
        }
        
        // setupTlsCerts()

        mqttClient = MQTT.newConnection(mqttConfig)
        
        disconnectTimestamp = nil
        disconnectsInMinute = 0
        
        return (mqttClient!.isConnected)
    }
    
    func disconnect() {
        if(mqttClient != nil) {
            mqttClient!.disconnect()
            mqttClient = nil
            connectTime = nil
            subscriptionTopic = ""
            subscriptionQos = 0
            disconnectTimestamp = nil
            disconnectsInMinute = 0
        }
    }
    
    //
    // Set up TLS certificate handling
    // TODO: Needs work...
    // Should set up a cert management window
    // To get the code below working with test.mosquitto.org stick their cert
    // in the certs bundle in this project...
    // Note: May need to deal with export goo if this is enabled.
    // func setupTlsCerts() {

        // let bundleURL = NSURL(fileURLWithPath: Bundle(for: type(of: self)).path(forResource: "certs", ofType: "bundle")!)
        // let certFile = bundleURL.appendingPathComponent("mosquitto.crt")?.path
        
    //    var bundlePath = Bundle(for: type(of: self)).bundlePath as NSString
    //    bundlePath = bundlePath.appendingPathComponent("cert.bundle") as NSString
    //    let certFile = bundlePath.appendingPathComponent("mosquitto.org.crt")

        // mqttConfig.mqttTlsOpts = MQTTTlsOpts(tls_insecure: true, cert_reqs: .ssl_verify_none, tls_version: nil, ciphers: nil)
    //    mqttConfig.mqttServerCert = MQTTServerCert(cafile: certFile, capath: nil)
    // }
    
    //
    // Insert new message into the message list
    func handleNewMessage(message: MQTTMessage) -> Void {
        messageQueue.async {
            let my_message = MyMQTTMessage(message: message, timestamp: NSDate())
            self.messagesReceived += 1
            self.messageList.insert(my_message, at: 0)
            // If we've exceeded our max list size, prune the end of the list
            while(self.messageList.count > self.maxMessageList) {
                self.messageList.removeLast()
            }
            self.newMessage = true
        }
    }
    
    // Given a particular topic
    func getMessageListForTopic(topic: String) -> [MyMQTTMessage] {
        var messageListForTopic = [MyMQTTMessage]()
        for messageItem in messageList {
            if (messageItem.message.topic == topic) {
                messageListForTopic.append(messageItem)
            }
        }
        return messageListForTopic
    }
    
    func setConnectCallback(callback: ((Int, String) -> Void)?) {
        mqttConfig.onConnectCallback = { (returnCode: ReturnCode) -> () in
            print("Handling connect... \(returnCode.description)")
            callback!(returnCode.rawValue, returnCode.description)
            self.connectTime = NSDate()
            /* Re-subscribe */
            if (self.subscriptionTopic != "") {
                self.subscribe(topic: self.subscriptionTopic, qos: self.subscriptionQos)
            }
        }
    }
    
    func setDisconnectCallback(callback: ((Int, String) -> Void)?) {
        mqttConfig.onDisconnectCallback = { (reasonCode: ReasonCode) -> () in
            print("Handling disconnect... \(reasonCode.description)")
            // Throttle reconnect storms...
            if (self.disconnectTimestamp == nil) {
                self.disconnectTimestamp = Date()
                self.disconnectsInMinute = 1
            } else {
                if (self.disconnectTimestamp! < Date(timeIntervalSinceNow: -60)) {
                    self.disconnectTimestamp = nil
                    self.disconnectsInMinute = 0
                } else {
                    self.disconnectsInMinute += 1
                    if (self.disconnectsInMinute > self.maxDisconnectsInMinute) {
                        self.disconnect()
                        self.mqttClient = nil
                    }
                }
            }
            callback!(reasonCode.rawValue, reasonCode.description)
        }
    }
    
    func subscribe(topic: String, qos: Int32) {
        subscriptionTopic = topic
        subscriptionQos = qos
        mqttClient!.subscribe(subscriptionTopic, qos: qos)
    }
    
    func unsubscribe() {
        mqttClient!.unsubscribe(subscriptionTopic)
        subscriptionTopic = ""
        subscriptionQos = 0
    }
    
    func publish(topic: String, message: NSData, qos: Int32, retain: Bool) -> (Int, Int) {
        let semaphore = DispatchSemaphore(value: 0)
        print("Publishing!!!")
        var mosqRet = -1
        var msgId = -1
        mqttClient?.publish(message as Data, topic: topic, qos: qos, retain: retain) { mosqReturn, messageId in
            mosqRet = mosqReturn.rawValue
            msgId = messageId
            semaphore.signal()
        }
        semaphore.wait()
        print("mosqRet = \(mosqRet), msgeId = \(msgId)")
        return (mosqRet, msgId)
    }
    
}
