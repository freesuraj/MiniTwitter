//
//  TweetComposeViewController.swift
//  MiniTwitter
//
//  Created by Suraj Pathak on 8/10/15.
//  Copyright © 2015 Laohan. All rights reserved.
//

import UIKit

import TwitterKit
import RealmSwift
import SwiftyJSON

class TweetComposeViewController: UIViewController, UITextViewDelegate {

    @IBOutlet var textView: UITextView!
    @IBOutlet var tweetButton: UIButton!
    @IBOutlet var labelCounter: UILabel!
    
    typealias ComposeCompletion = (needRefresh: Bool) -> Void
    var completionBlock : ComposeCompletion?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tweetButton.enabled = false
        tweetButton.backgroundColor = UIColor.lightGrayColor()
        title = "Compose Tweet"
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func onTweetPressed(sender: AnyObject) {
        let text = textView.attributedText.string
        HUDManager.showLoadingWithText("Sending", enableUserInteraction: false, view: self.view)
        TweetObject.sendTweet(text, isDraft: false, completion: {success in
            HUDManager.hide()
            if let c = self.completionBlock{
                c(needRefresh: true)
            }
            self.navigationController?.popViewControllerAnimated(true)
        })
    }
    
    func updateCounterAndText() {
        let count = self.textView.text.characters.count
        if count <= 140 {
            labelCounter.text = String(format: "%d", 140 - count)
            labelCounter.textColor = UIColor.blackColor()
            let attributedString = NSMutableAttributedString(string: self.textView.text)
            let attribute = [NSForegroundColorAttributeName: UIColor.blackColor(), NSFontAttributeName: UIFont.systemFontOfSize(16.0)]
            attributedString.setAttributes(attribute, range: NSMakeRange(0, count))
            textView.attributedText = attributedString
            tweetButton.enabled = true
            
            tweetButton.backgroundColor = UIColor.darkGrayColor()
            
        } else {
            labelCounter.text = String(format: "-%d", count - 140)
            labelCounter.textColor = UIColor.redColor()
            let attributedString = NSMutableAttributedString(string: self.textView.text)
            let attribute = [NSForegroundColorAttributeName: UIColor.redColor(), NSFontAttributeName: UIFont.systemFontOfSize(16.0)]
            let attribute2 = [NSForegroundColorAttributeName: UIColor.blackColor(), NSFontAttributeName: UIFont.systemFontOfSize(16.0)]
            attributedString.setAttributes(attribute2, range: NSMakeRange(0, 140))
            attributedString.setAttributes(attribute, range: NSMakeRange(140, count - 140))
            textView.attributedText = attributedString
            tweetButton.enabled = false
            
            tweetButton.backgroundColor = UIColor.lightGrayColor()
        }
        
    }
    
    func textViewDidChange(textView: UITextView) {
        updateCounterAndText()
    }

}
