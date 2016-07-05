//
//  ViewController.swift
//  Project28
//
//  Created by Mike Camara on 18/11/2015.
//  Copyright © 2015 Mike Camara. All rights reserved.
//

// In the future  try creating a password system for your app so that the Touch ID fallback is more useful. You'll need to use the addTextFieldWithConfigurationHandler() from project 5, and I suggest you save the password in the keychain!

import LocalAuthentication
import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var secret: UITextView!
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Nothing to see here"
        
        


        //using NSNotificationCenter to watch for the keyboard appearing and disappearing
        let notificationCenter = NSNotificationCenter.defaultCenter()
        notificationCenter.addObserver(self, selector: "adjustForKeyboard:", name: UIKeyboardWillHideNotification, object: nil)
        notificationCenter.addObserver(self, selector: "adjustForKeyboard:", name: UIKeyboardWillChangeFrameNotification, object: nil)
        
        //will tell us when the application will stop being active – i.e., when our app has been backgrounded or the user has switched to multitasking mode.
        notificationCenter.addObserver(self, selector: "saveSecretMessage", name: UIApplicationWillResignActiveNotification, object: nil)

    
    }
    
    func adjustForKeyboard(notification: NSNotification) {
        let userInfo = notification.userInfo!
        
        let keyboardScreenEndFrame = (userInfo[UIKeyboardFrameEndUserInfoKey] as! NSValue).CGRectValue()
        let keyboardViewEndFrame = view.convertRect(keyboardScreenEndFrame, fromView: view.window)
        
        if notification.name == UIKeyboardWillHideNotification {
            secret.contentInset = UIEdgeInsetsZero
        } else {
            secret.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardViewEndFrame.height, right: 0)
        }
        
        secret.scrollIndicatorInsets = secret.contentInset
        
        let selectedRange = secret.selectedRange
        secret.scrollRangeToVisible(selectedRange)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

   

    func unlockSecretMessage() {
        secret.hidden = false
        title = "Secret stuff!"
        
        if let text = KeychainWrapper.stringForKey("SecretMessage") {
            secret.text = text
        }
    }
    
    func saveSecretMessage() {
        if !secret.hidden {
            KeychainWrapper.setString(secret.text, forKey: "SecretMessage")
            secret.resignFirstResponder()
            secret.hidden = true
            title = "Nothing to see here"
        }
    }
    
    // previous authenticateUser()
    // @IBAction func authenticateUser(sender: AnyObject) {
    //    unlockSecretMessage()
    //}
    
    
    @IBAction func authenticateUser(sender: AnyObject) {
        let context = LAContext()
        var error: NSError?
        
        // this was the previous message
        if context.canEvaluatePolicy(.DeviceOwnerAuthenticationWithBiometrics, error: &error) {
        //if true {

            let reason = "Identify yourself!"
            
            context.evaluatePolicy(.DeviceOwnerAuthenticationWithBiometrics, localizedReason: reason) {
                [unowned self] (success: Bool, authenticationError: NSError?) -> Void in
                
                dispatch_async(dispatch_get_main_queue()) {
                    // this was the previous code
                    if success {
                        //if true {

                        self.unlockSecretMessage()
                    } else {
                        // error
                        
                        //instead of the current error message, ideally I would have to if the user requested fallback mode (i.e. password) then what Touch ID really wants us to do is have the user enter a password. But that's not the user's iTunes password or even a PIN on their phone. Instead, it's a password that we need to have set up beforehand ourselves, then validate too.
                        if let error = authenticationError {
                            if error.code == LAError.UserFallback.rawValue {
                                let ac = UIAlertController(title: "Passcode? Ha!", message: "It's Touch ID or nothing – sorry!", preferredStyle: .Alert)
                                ac.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
                                self.presentViewController(ac, animated: true, completion: nil)
                                return
                            }
                        }
                        
                        let ac = UIAlertController(title: "Authentication failed", message: "Your fingerprint could not be verified; please try again.", preferredStyle: .Alert)
                        ac.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
                        self.presentViewController(ac, animated: true, completion: nil)
                    }
                }
            }
        } else {
            // no Touch ID
            
            let ac = UIAlertController(title: "Touch ID not available", message: "Your device is not configured for Touch ID.", preferredStyle: .Alert)
            ac.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
            self.presentViewController(ac, animated: true, completion: nil)
        }
    }
}

