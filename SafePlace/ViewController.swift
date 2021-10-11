//
//  ViewController.swift
//  SafePlace
//
//  Created by Никита on 08.10.2021.
//

import LocalAuthentication
import UIKit

class ViewController: UIViewController {
    @IBOutlet var secretTextView: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Nothing to see here"
        
        let notificationCenter = NotificationCenter.default
        
        // By using this code we point to func that prevent keyboard overlay on text
        notificationCenter.addObserver(self, selector: #selector(adjustForKeyboard), name: UIResponder.keyboardDidHideNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(adjustForKeyboard), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        
        notificationCenter.addObserver(self, selector: #selector(saveSecretMessage), name: UIApplication.willResignActiveNotification, object: nil)
    }

    @IBAction func authTapped(_ sender: Any) {
        let context = LAContext()
        var error: NSError?
        
        // Using a & points a error to RAM because OBJC dont know what is in-out parameters, so we just point to RAM directly
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error){
            let reason = "Identify yourself"
            
            context.evaluatePolicy( .deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) {
                [weak self] succsess, authError in
                DispatchQueue.main.async {
                    if succsess {
                        self?.unlockSecretMessage()
                    } else {
                        let ac = UIAlertController(title: "Authentication failed", message: "You could not be verified, please try again", preferredStyle: .alert)
                        ac.addAction(UIAlertAction(title: "OK", style: .default))
                        self?.present(ac, animated: true)
                    }
                }
            }
        } else {
            let ac = UIAlertController(title: "Biometry unavailable", message: "Your device is not configured for biometric authentication", preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default))
            present(ac, animated: true)
        }
    }
    
    @objc func adjustForKeyboard(notification: Notification) {
        guard let keyboardValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else { return }
        
        let keyboardScreenEnd = keyboardValue.cgRectValue
        let keyboardViewEndFrame = view.convert(keyboardScreenEnd, from: view.window)
        
        if notification.name == UIResponder.keyboardWillHideNotification {
            secretTextView.contentInset = .zero
        } else {
            secretTextView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardViewEndFrame.height - view.safeAreaInsets.bottom, right: 0)
        }
        
        secretTextView.scrollIndicatorInsets = secretTextView.contentInset
        
        let selectedRange = secretTextView.selectedRange
        secretTextView.scrollRangeToVisible(selectedRange)
    }
    
    func unlockSecretMessage(){
        secretTextView.isHidden = false
        title = "Secret stuff"
        
        secretTextView.text = KeychainWrapper.standard.string(forKey: "SecretMessage") ?? ""
            
    }
    
    @objc func saveSecretMessage(){
        guard secretTextView.isHidden == false else { return }
        
        KeychainWrapper.standard.set(secretTextView.text, forKey: "SecretMessage")
        secretTextView.resignFirstResponder()
        secretTextView.isHidden = true
        title = "Nothing to see here"
    }
}

