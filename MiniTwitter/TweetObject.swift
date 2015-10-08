//
//  TweetObject.swift
//  MiniTwitter
//
//  Created by Suraj Pathak on 8/10/15.
//  Copyright © 2015 Laohan. All rights reserved.
//

import Foundation

import TwitterKit
import RealmSwift
import SwiftyJSON


var isSyncing = false

public class RealmManager {
    static let realm = try! Realm()
    
    /**
    If realm is already in write transaction, continues the block on that transaction. Otherwise creates a new write transaction to perform the block.
    */
    static func safeWrite(block: () -> Void) {
        if RealmManager.realm.inWriteTransaction {
            block()
        }
        else {
            RealmManager.realm.write(block)
        }
    }
}

class TwitterUser: Object {
    dynamic var name = ""
    dynamic var userImage = ""
    dynamic var handle = ""
    dynamic var userId = ""
    
    override static func primaryKey() -> String {
        return "userId"
    }
    
    static func getCurrentUser() -> TwitterUser? {
        if let defaultUserId = NSUserDefaults.standardUserDefaults().valueForKey("userId") {
            return RealmManager.realm.objectForPrimaryKey(TwitterUser.self, key: defaultUserId)!
        }
        return nil
    }
}

class TweetObject: Object {
    
    dynamic var tweetId = ""
    dynamic var date: Double = 0.0
    dynamic var dateString = ""
    dynamic var username = ""
    dynamic var handle = ""
    dynamic var text = ""
    dynamic var userImage = ""
    dynamic var needSync = false
    override static func primaryKey() -> String {
        return "tweetId"
    }
    
    static func getLatestTweets() -> [TweetObject] {
        return RealmManager.realm.objects(TweetObject).sorted("date", ascending: false).toArray(TweetObject.self)
    }
    
    static func downloadUserTimeLine(completion:([TweetObject]?, NSError?) -> Void) {
        if let userID = Twitter.sharedInstance().sessionStore.session()?.userID {
            let client = TWTRAPIClient(userID: userID)
            let endPoint = "https://api.twitter.com/1.1/statuses/home_timeline.json"
            let params = ["count": "20"]
            var clientError : NSError?
            
            let request = client.URLRequestWithMethod("GET", URL: endPoint, parameters: params, error: &clientError)
            client.sendTwitterRequest(request) { (response, data, connectionError) -> Void in
                if (connectionError == nil) {
                    do {
                        let rawJson : [AnyObject] = try NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.AllowFragments) as! [AnyObject]
                        for raw in rawJson {
                            parseTwitterObjectJson(raw)
                        }
                        
                        completion(TweetObject.getLatestTweets(), nil)
                        
                    } catch let error as NSError {
                        completion(TweetObject.getLatestTweets(), error)
                    }
                }
                else {
                    completion(TweetObject.getLatestTweets(), connectionError)
                }
            }
        }
    }
    
    static func saveDraftTweet(text: String) {
        let t = TweetObject()
        t.tweetId = String(format: "%ld", arc4random_uniform(1000) + 1)
        t.text = text

        if let user = TwitterUser.getCurrentUser() {
            t.username = user.name
            t.handle = user.handle
            t.userImage = user.userImage
        } else {
            t.username = "You"
            t.handle = "you"
        }
        t.needSync = true
        t.dateString = NSDate().getCurrentShortDate()
        t.date = NSDate().timeIntervalSince1970
        
        RealmManager.safeWrite({
            RealmManager.realm.add(t, update: true)
        })
    }
    
    static func syncDraftTweets(completion:(Bool -> Void)) {
        if(isSyncing) {
            completion(true)
            return
        }
        isSyncing = true
        let drafts = RealmManager.realm.objects(TweetObject).filter(NSPredicate(format: "needSync == YES"))
        if(drafts.count == 0) {
            isSyncing = false
            completion(true)
            return
        }
        
        for aDraft in drafts {
            isSyncing = true
            sendTweet(aDraft.text, isDraft: true, completion: { success in
                if(success) {
                    // remove this draft
                    RealmManager.safeWrite({ () -> Void in
                        RealmManager.realm.delete(aDraft)
                    })
                }
                isSyncing = false
            })
        }
    }
    
    static func sendTweet(text: String, isDraft: Bool, completion:(Bool) -> Void) {
        if(text.characters.count == 0) {
            completion(true)
            return
        }
        if let userID = Twitter.sharedInstance().sessionStore.session()?.userID {
            let client = TWTRAPIClient(userID: userID)
            let endPoint = "https://api.twitter.com/1.1/statuses/update.json"
            let params = ["status": text]
            var clientError : NSError?
            
            let request = client.URLRequestWithMethod("POST", URL: endPoint, parameters: params, error: &clientError)
            client.sendTwitterRequest(request) { (response, data, connectionError) -> Void in
                if (connectionError == nil) {
                    do {
                        let rawJson : AnyObject = try NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.AllowFragments)
                        parseTwitterObjectJson(rawJson)
                        completion(true)
                        
                    } catch let error as NSError {
                        print("error \(error)")
                        completion(false)
                    }
                }
                else {
                    print("Error: \(connectionError)")
                    // Save this tweet as a draft tweet and sync later
                    if(!isDraft) {
                        saveDraftTweet(text)
                    }
                    completion(false)
                }
            }
        }
    }
    
    private static func parseTwitterObjectJson(rawJson: AnyObject) -> TweetObject {
        let tweet = TweetObject()
        var json = JSON(rawJson)
        tweet.tweetId = json["id_str"].stringValue
        tweet.dateString = json["created_at"].stringValue
        tweet.date = NSDate.dateFromTwitterTimeString(json["created_at"].stringValue).timeIntervalSince1970
        tweet.text = json["text"].stringValue
        let user = json["user"].dictionaryValue
        tweet.username = user["name"]!.stringValue
        tweet.handle = user["screen_name"]!.stringValue
        tweet.userImage = user["profile_image_url_https"]!.stringValue
        
        RealmManager.safeWrite({
            RealmManager.realm.add(tweet, update: true)
        })
        
        return tweet
    }
}

extension Results {
    func toArray<T>(ofType: T.Type) -> [T] {
        var array = [T]()
        for result in self {
            if let result = result as? T {
                array.append(result)
            }
        }
        return array
    }
}

