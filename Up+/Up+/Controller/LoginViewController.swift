//
//  LoginViewController.swift
//  Up
//
//  Created by Dreamup on 2/7/17.
//  Copyright © 2017 Dreamup. All rights reserved.
//

import UIKit
import FirebaseAuth
import GoogleSignIn
import SendBirdSDK

class LoginViewController: UIViewController,UITextFieldDelegate,GIDSignInUIDelegate,GIDSignInDelegate{
    
    @IBOutlet weak var emailTf: UITextField!
    @IBOutlet weak var passwordTf: UITextField!
    @IBOutlet weak var loginBt: UIButton!
    @IBOutlet weak var fbLoginBt: UIButton!
    @IBOutlet weak var googleLoginBt: UIButton!
    @IBOutlet weak var warningLb: UILabel!
    @IBOutlet weak var loginSpaceBottomConstraint: NSLayoutConstraint!
    
    var isAuthendicate = false
    
    @IBAction func forgotAction(_ sender: Any) {
    }
    
    @IBAction func loginAction(_ sender: Any) {
        
        let username = emailTf.text
        let password = passwordTf.text
        
        if((password?.characters.count)! >= 6 && (username?.isValidEmail())!){
            
            warningLb.isHidden = true
            FIRAuth.auth()?.signIn(withEmail: username!, password: password!) {
                (user, error) in
                if(error != nil){
                    
                    let alertVC = UIAlertController(title: "", message: error?.localizedDescription, preferredStyle: .alert)
                    alertVC.addAction(UIAlertAction(title: "OK", style: .default, handler: {
                        action -> Void in
                        
                    }))
                    self .present(alertVC, animated: true, completion: nil)
                
                }
                self.loginSuccess(username: user!.displayName!, userId: user!.uid,photo: user?.photoURL)
            }
            
        }else{
            warningLb.isHidden = false
        }
    }
    
    @IBAction func googleSignInAction(_ sender: Any) {
        
        GIDSignIn.sharedInstance().signIn()
    }
    
    
    @IBAction func createAccountAction(_ sender: Any) {
        
    }
    
    
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error?) {
        
        if let error = error {
            print(error)
            return
        }
        
        SpinnerSwift.sharedInstance.startAnimating()
        
        guard let authentication = user.authentication else { return }
        let credential = FIRGoogleAuthProvider.credential(withIDToken: authentication.idToken,
                                                          accessToken: authentication.accessToken)
        
        FIRAuth.auth()?.signIn(with: credential) {
            (user, error) in
            SpinnerSwift.sharedInstance.stopAnimating()
            
            if let error = error {
                print(error)
                return
            }
            
            self.loginSuccess(username: user!.displayName!, userId: user!.uid, photo: user?.photoURL)
           
        }
    }
    func sign(_ signIn: GIDSignIn!, didDisconnectWith user:GIDGoogleUser!,
              withError error: Error!) {
        
    }
    
    func loginSuccess(username:String,userId:String,photo:URL?) {
     
        UserDefaults.standard.set(userId, forKey: USER_ID)
        UserDefaults.standard.set(username, forKey: USER_NAME)
        if(photo != nil){
            UserDefaults.standard.set(photo?.absoluteString, forKey: USER_PHOTO_URL)
        }
        
        let user = User()
        user.userId = userId
        user.username = username
        let manager = FIRUserManager()
        manager .createUser(user: user)
        
        SBDMain.connect(withUserId: userId, completionHandler: {
            (user, error) in
            
            do{
                let data = try Data.init(contentsOf: photo!)
                SBDMain.updateCurrentUserInfo(withNickname: username , profileImage: data, completionHandler: {
                    (error) in
                    // ...
                })
            
            }catch let error{
                print(error)
            }

        })
        self.isAuthendicate = true
        LocationManager.shareInstace.startLoadLocation()
        self.performSegue(withIdentifier: "LoginSegue", sender: nil)
    }
    
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(rotated), name: NSNotification.Name.UIDeviceOrientationDidChange, object: nil)
        
        loginBt.layer.cornerRadius = 5.0
        loginBt.clipsToBounds = true
        loginBt.layer.masksToBounds = false
        loginBt.layer.shadowOpacity = 1.0
        loginBt.layer.shadowOffset = CGSize(width: 0, height: 6)
        loginBt.layer.shadowColor = UIColor(red: 254.0/255.0, green: 181/255.0, blue: 173/255.0, alpha: 1.0).cgColor
        
        emailTf.delegate = self
        passwordTf.delegate = self
        
        GIDSignIn.sharedInstance().uiDelegate = self
        GIDSignIn.sharedInstance().delegate = self
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
    }
    
    
    func rotated() {
        if UIDeviceOrientationIsLandscape(UIDevice.current.orientation) {
            //print("Landscape")
            loginSpaceBottomConstraint.constant = 150
            
        }
        
        if UIDeviceOrientationIsPortrait(UIDevice.current.orientation) {
            //print("Portrait")
            let height = 195 + 170*(view.frame.height/568)
            loginSpaceBottomConstraint.constant = view.frame.size.height - height
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if(textField == emailTf){
            passwordTf.becomeFirstResponder()
        }else{
            self.view.endEditing(true)
        }
        return true
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        if(identifier == "LoginSegue" && isAuthendicate == false){
            return false
        }
        return true
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}


extension String{
    func isValidEmail() -> Bool{

        let laxString = "^.+@([A-Za-z0-9-]+\\.)+[A-Za-z]{2}[A-Za-z]*$"
        let predicate = NSPredicate(format: "SELF MATCHES %@", laxString)
        return predicate.evaluate(with: self)
    }
}

