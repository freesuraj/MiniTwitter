//
//  Helper.swift
//  MiniTwitter
//
//  Created by Suraj Pathak on 8/10/15.
//  Copyright © 2015 Laohan. All rights reserved.
//

import Foundation
import JGProgressHUD
import SystemConfiguration

// MARK: NSDate
extension NSDate {
    func dateFromString(date: String, format: String) -> NSDate {
        let formatter = NSDateFormatter()
        let locale = NSLocale(localeIdentifier: "en_US_POSIX")
        
        formatter.locale = locale
        formatter.dateFormat = format
        
        return formatter.dateFromString(date)!
    }
    
    func getCurrentShortDate() -> String {
        let dateFormatter = NSDateFormatter()
        
        dateFormatter.dateStyle = .ShortStyle
        dateFormatter.timeStyle = .ShortStyle
        
        let dateInFormat = dateFormatter.stringFromDate(self)
        
        return dateInFormat
    }
    
    static func dateFromTwitterTimeString(dateString: String) -> NSDate {
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "eee MMM dd HH:mm:ss ZZZZ yyyy"
        return dateFormatter.dateFromString(dateString)!
    }
}

func sampleTweets() -> [TweetObject] {
    var tweets: [TweetObject] = []
    for _ in 0...10 {
        let t = TweetObject()
        t.tweetId = String(format: "%ld", arc4random_uniform(1000) + 1)
        t.username = randomStringWithLength(12) as String
        t.handle = randomStringWithLength(10) as String
        t.text = randomStringWithLength(Int(arc4random_uniform(100) + 40)) as String
        tweets.append(t)
        RealmManager.safeWrite({
            RealmManager.realm.add(t, update: true)
        })
    }
    return tweets
}

func randomStringWithLength (len : Int) -> NSString {
    
    let letters : NSString = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789 "
    
    let randomString : NSMutableString = NSMutableString(capacity: len)
    
    for (var i=0; i < len; i++){
        let length = UInt32 (letters.length)
        let rand = arc4random_uniform(length)
        randomString.appendFormat("%C", letters.characterAtIndex(Int(rand)))
    }
    
    return randomString
}

class HUDManager {
    static let progressHud = JGProgressHUD(style: .Dark)

    static func showLoadingWithText(text: String, enableUserInteraction interaction: Bool, view: UIView) {
        progressHud.textLabel.text = text
        progressHud.interactionType = interaction ? .BlockNoTouches :  .BlockAllTouches
        progressHud.indicatorView = JGProgressHUDIndeterminateIndicatorView(HUDStyle: .ExtraLight)
        progressHud.showInView(view)
    }
    
    static func hide() {
        progressHud.dismissAfterDelay(0.1)
    }
}
