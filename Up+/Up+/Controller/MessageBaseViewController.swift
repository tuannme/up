//
//  MessageBaseViewController.swift
//  Up+
//
//  Created by Dreamup on 2/24/17.
//  Copyright © 2017 Dreamup. All rights reserved.
//

import UIKit
import SendBirdSDK

class MessageBaseViewController: UIViewController,UITextViewDelegate {
    
    var arrMessage:[SBDBaseMessage] = []
    var memberId:String!
    var groupChannel:SBDGroupChannel?
    let myId = UserDefaults.standard.object(forKey: USER_ID) as! String
    var keyboardViewController:KeyboardViewController?
    
    @IBOutlet weak var inputViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var tbView: UITableView!
    @IBOutlet weak var listenView: UIView!
    @IBOutlet weak var messageLb: UILabel!
    @IBOutlet weak var showMediaBt: UIButton!
    
    @IBOutlet weak var keyboardSpaceBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var inputTv: UITextView!
    
    @IBOutlet weak var typingMsgView: UIView!
    @IBOutlet weak var typingLeadingSpaceContraint: NSLayoutConstraint!
    @IBOutlet weak var mediaMsgLeadingSpaceConstraint: NSLayoutConstraint!
    
    
    let INPUT_VIEW_MAX_HEIGHT:CGFloat = 70.0
    let BOTTOM_MARGIN:CGFloat = 0.0
    let INPUT_SIZE_MIN:CGFloat = 40.0
    let LINE_HEIGHT:CGFloat = 22.5
    
    var isShouldHideKeyboard = true
    
    var accessoryView:InputAccessoryView?
    
    override var shouldAutorotate: Bool {
        return false
    }
    override var supportedInterfaceOrientations : UIInterfaceOrientationMask {
        return .portrait
    }
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
    
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillShow(notification:)), name: .UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillHide(notification:)), name: .UIKeyboardWillHide, object: nil)
        
        accessoryView = InputAccessoryView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height:self.INPUT_VIEW_MAX_HEIGHT))
        accessoryView?.isUserInteractionEnabled = false
        self.inputTv.inputAccessoryView = accessoryView
        self.inputTv.isUserInteractionEnabled = true
        self.inputTv.delegate = self;
        
        let gesture = UITapGestureRecognizer(target: self, action: #selector(self.touchOnInputView))
        self.listenView.isUserInteractionEnabled = true
        self.listenView.addGestureRecognizer(gesture)
        
        let tableViewTapGesture = UITapGestureRecognizer(target: self, action: #selector(self.touchOnTableView))
        self.tbView.addGestureRecognizer(tableViewTapGesture)
        
        typingMsgView.layer.cornerRadius = 10
        typingMsgView.clipsToBounds = true
        typingMsgView.layer.borderColor = UIColor.lightGray.cgColor
        typingMsgView.layer.borderWidth = 1
        
        tbView.scrollsToTop = true
        tbView.keyboardDismissMode = UIScrollViewKeyboardDismissMode.interactive
        tbView.rowHeight = UITableViewAutomaticDimension
        tbView.estimatedRowHeight = 40
        
        accessoryView?.inputAcessoryViewFrameChangedBlock = {
            (inputAccessoryViewFrame) -> Void in
            let value = self.view.frame.height - inputAccessoryViewFrame.minY - (self.inputTv.inputAccessoryView?.frame.height)! + self.BOTTOM_MARGIN
            self.keyboardSpaceBottomConstraint.constant = max(self.BOTTOM_MARGIN, value)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
    }
    
    
    func touchOnTableView()  {
        self.inputTv.resignFirstResponder()
    }
    
    func touchOnInputView(){
        
        keyboardViewController?.setKeyboardType(type: .NONE)
        
        isShouldHideKeyboard = true
        self.inputTv.becomeFirstResponder()

        self.listenView.isHidden = true
        self.showMediaBt.isHidden = false
        
        UIView.animate(withDuration: 0.25, animations: {
            
            self.typingLeadingSpaceContraint.constant = 60
            self.mediaMsgLeadingSpaceConstraint.constant = -150
            self.view.layoutIfNeeded()
        })
        
        autoResizeTypingTextView()
    }
    
    
    @IBAction func showMediaMessageAction(_ sender: Any) {
        
        self.inputViewHeightConstraint.constant = INPUT_SIZE_MIN
        let message = inputTv.text
        
        self.showMediaBt.isHidden = true
        self.listenView.isHidden = false
        
        if(message?.characters.count == 0){
            messageLb.text = "Say something ..."
        }else{
            messageLb.text = message
        }
        
        UIView.animate(withDuration: 0.25, animations: {
            self.typingLeadingSpaceContraint.constant = 150
            self.mediaMsgLeadingSpaceConstraint.constant = 0
            self.view.layoutIfNeeded()
            
        })
        
    }
    
    func textViewDidChange(_ textView: UITextView) {
        
        if(self.mediaMsgLeadingSpaceConstraint.constant == 0){
            
            self.listenView.isHidden = true
            self.showMediaBt.isHidden = false
            
            UIView .animate(withDuration: 0.2, animations: {
                self.typingLeadingSpaceContraint.constant = 60
                self.mediaMsgLeadingSpaceConstraint.constant = -150
                self.view.layoutIfNeeded()
            })
            
        }
        autoResizeTypingTextView()
    }
    
    func autoResizeTypingTextView() {
        return
        let message = inputTv.text
        let font = UIFont (name: "Helvetica Neue", size: 17)
        let minSize = "A".heightWithConstrainedWidth(width: inputTv.frame.width, font: font!)
        let height = message?.heightWithConstrainedWidth(width: inputTv.frame.width, font: font!)
        
        let numberLine = Int(height!/minSize)
        
        if(numberLine >= 5){
            self.inputTv.isScrollEnabled = true
        }else{
            self.inputViewHeightConstraint.constant = INPUT_SIZE_MIN + LINE_HEIGHT*CGFloat((numberLine-1))
            self.inputTv.isScrollEnabled = false
        }
    }
    
    func keyboardWillShow(notification:NSNotification){
        
        let animationCurve = notification.userInfo?[UIKeyboardAnimationCurveUserInfoKey] as! Int
        let duration = notification.userInfo?[UIKeyboardAnimationDurationUserInfoKey] as! CGFloat
        
        let keyboardFrame =  notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as! CGRect
        let keyboardHeight = keyboardFrame.size.height
        
        UIView.animate(withDuration: TimeInterval(duration), delay: 0, options: UIViewAnimationOptions(rawValue: UInt(animationCurve)), animations: {
            
            
            
            let offset = self.tbView.contentOffset.y + keyboardHeight
            self.tbView.setContentOffset(CGPoint(x: 0, y: offset), animated: false)
            
            self.keyboardSpaceBottomConstraint.constant = keyboardFrame.size.height - self.INPUT_VIEW_MAX_HEIGHT
            self.view.layoutIfNeeded()
            
        }, completion: nil)
        
    }
    
    func keyboardWillHide(notification:NSNotification){
        let animationCurve = notification.userInfo?[UIKeyboardAnimationCurveUserInfoKey] as! Int
        let duration = notification.userInfo?[UIKeyboardAnimationDurationUserInfoKey] as! CGFloat
        
        if(self.inputTv.text.characters.count == 0){
            
            self.listenView.isHidden = false
            self.showMediaBt.isHidden = true
            
            UIView .animate(withDuration: 0.2, animations: {
                self.typingLeadingSpaceContraint.constant = 150
                self.mediaMsgLeadingSpaceConstraint.constant = 0
                self.view.layoutIfNeeded()
            })
            
        }
        
        UIView.animate(withDuration: TimeInterval(duration), delay: 0, options: UIViewAnimationOptions(rawValue: UInt(animationCurve)), animations: {
            
            let space = self.isShouldHideKeyboard ? self.BOTTOM_MARGIN : KEYBOARD_HEIGHT
            self.keyboardSpaceBottomConstraint.constant = space
            
            self.view.layoutIfNeeded()
            
        }, completion: nil)

    }
    

    @IBAction func backAction(_ sender: Any) {
        self.navigationController!.popViewController(animated: true)
    }
    
    
    
    @IBAction func sendMessageAction(_ sender: Any) {
        
    }
    
    @IBAction func cameraAction(_ sender: Any) {
        
        keyboardViewController?.setKeyboardType(type: .CAMERA)
        
        isShouldHideKeyboard = false
        if keyboardSpaceBottomConstraint.constant == BOTTOM_MARGIN{
            UIView.animate(withDuration: 0.2, animations: {
                self.keyboardSpaceBottomConstraint.constant = KEYBOARD_HEIGHT
                self.view.layoutIfNeeded()
            })
            return
        }

        self.inputTv.resignFirstResponder()
    }
    
    
    @IBAction func drawAction(_ sender: Any) {

        keyboardViewController?.setKeyboardType(type: .DRAW)
        
        isShouldHideKeyboard = false
        if keyboardSpaceBottomConstraint.constant == BOTTOM_MARGIN{
            UIView.animate(withDuration: 0.2, animations: {
                self.keyboardSpaceBottomConstraint.constant = KEYBOARD_HEIGHT
                self.view.layoutIfNeeded()
            })
            return
        }

        self.inputTv.resignFirstResponder()
    }
    
    @IBAction func mediaAction(_ sender: Any) {

        keyboardViewController?.setKeyboardType(type: .MEDIA)
        
        isShouldHideKeyboard = false
        if keyboardSpaceBottomConstraint.constant == BOTTOM_MARGIN{
            UIView.animate(withDuration: 0.2, animations: {
                self.keyboardSpaceBottomConstraint.constant = KEYBOARD_HEIGHT
                self.view.layoutIfNeeded()
            })
            return
        }

        self.inputTv.resignFirstResponder()
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

extension MessageBaseViewController:UIScrollViewDelegate{
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if isShouldHideKeyboard == false{
            
            let p = scrollView.panGestureRecognizer.location(in: scrollView)
            let  absP = scrollView.convert(p, to: self.view)
            let value = SCREEN_HEIGHT - absP.y - 3
            let keyboardHeight = min(value, KEYBOARD_HEIGHT)
            
            self.keyboardSpaceBottomConstraint.constant = keyboardHeight
            self.view.layoutIfNeeded()
        
        }
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        
        if isShouldHideKeyboard == false && decelerate == false{
            
            let value = keyboardSpaceBottomConstraint.constant < 50 ? 0 : KEYBOARD_HEIGHT
            self.isShouldHideKeyboard = value < KEYBOARD_HEIGHT ? true : false
            UIView.animate(withDuration: 0.2, animations: {
                self.keyboardSpaceBottomConstraint.constant = value
                self.view.layoutIfNeeded()
            })
            
        }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if isShouldHideKeyboard == false {
            
            let value = keyboardSpaceBottomConstraint.constant < 50 ? 0 : KEYBOARD_HEIGHT
            self.isShouldHideKeyboard = value < KEYBOARD_HEIGHT ? true : false

            UIView.animate(withDuration: 0.2, animations: {
                self.keyboardSpaceBottomConstraint.constant = value
                self.view.layoutIfNeeded()
            })
            
        }
    }

    
}

extension MessageBaseViewController{
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if let _keyboardViewController = segue.destination as? KeyboardViewController{
            keyboardViewController = _keyboardViewController
        }
    }
}

