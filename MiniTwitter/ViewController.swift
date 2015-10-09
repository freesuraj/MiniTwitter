//
//  ViewController.swift
//  MiniTwitter
//
//  Created by Suraj Pathak on 8/10/15.
//  Copyright © 2015 Laohan. All rights reserved.
//

import UIKit

import Haneke
import RealmSwift
import SwiftyJSON
import TwitterKit

class TweetCell: UITableViewCell {
    
    @IBOutlet var profileImageView: UIImageView!
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var handleLabel: UILabel!
    @IBOutlet var messageLabel: UILabel!
    @IBOutlet var dateLabel: UILabel!
    @IBOutlet var draftIndicator: UIImageView!
    
    override func awakeFromNib() {
        profileImageView.layer.borderColor = UIColor.lightGrayColor().CGColor
        profileImageView.layer.masksToBounds = true
        profileImageView.layer.cornerRadius = 10.0
    }
    
    // Customize cell with a tweet object
    func customizeWithTweet(tweetObject: TweetObject) {
        nameLabel.text = tweetObject.username
        handleLabel.text = "@" + tweetObject.handle
        messageLabel.text = tweetObject.text
        dateLabel.text = NSDate(timeIntervalSince1970: tweetObject.date).getCurrentShortDate()
        if let url = NSURL(string: tweetObject.userImage) {
            self.profileImageView.hnk_setImageFromURL(url, placeholder: UIImage(named: "user")!, format: nil, failure: nil, success: { img in
                self.profileImageView.hnk_setImage(img, animated: true, success: nil)
            })
        } else {
            self.profileImageView.hnk_setImage(UIImage(named: "user")!, animated: true, success: nil)
        }
        
        self.draftIndicator.hidden = !tweetObject.needSync
    }
}

class ViewController: UIViewController {
    
    @IBOutlet var tableView: UITableView!
    let refreshControl: UIRefreshControl = UIRefreshControl()
    
    var incomingTweets: [TweetObject] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Timeline"
        self.tableView.estimatedRowHeight = 200
        self.tableView.rowHeight = UITableViewAutomaticDimension
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "edit"), style: UIBarButtonItemStyle.Plain, target: self, action: "onCompose:")
        
        // Pull to Refresh view
        let pullToRefreshText = "Pull To Refresh"
        let pullToRefreshAttributedText = NSMutableAttributedString(string: pullToRefreshText)
        pullToRefreshAttributedText.addAttribute(NSForegroundColorAttributeName, value: UIColor.darkGrayColor(), range: NSMakeRange(0, pullToRefreshText.characters.count))
        refreshControl.attributedTitle = pullToRefreshAttributedText
        refreshControl.addTarget(self, action: "loadTweets", forControlEvents: UIControlEvents.ValueChanged)
        tableView.addSubview(refreshControl)
        
        // Add a notification observer for change of connection
        let reachability = Reachability.reachabilityForInternetConnection()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "reachabilityChanged:", name: kReachabilityChangedNotification, object: nil)
        reachability.startNotifier()
        
        // Twitter Login
        showTwitterLoginOption()
    }
    
    func reachabilityChanged(sender: NSNotification) {
       let reach = sender.object as! Reachability
        if (reach.currentReachabilityStatus() == NotReachable) {
            print("offline ")
        } else {
            loadTweets()
        }
    }
    
    // See if previous logged in session exists, otherwise force user to login first
    func showTwitterLoginOption() {
        Twitter.sharedInstance().logInWithCompletion { session, error in
            if (session != nil) {
                print("signed in as \(session!.userName)");
                // Save basic user info
                self.syncUser()
                self.loadTweets()
            } else {
                print("error: \(error!.localizedDescription)");
                self.loadTweets()
            }
        }
    }
    
    // Sync user
    func syncUser() {
        if let userID = Twitter.sharedInstance().sessionStore.session()?.userID {
            let client = TWTRAPIClient(userID: userID)
            client.loadUserWithID(userID, completion: { user, error in
                if let twUser = user {
                  TwitterUser.saveTwitterUser(twUser)
                }
            })
        }
    }
    
    func loadTweets() {
        // Check and sync draft tweets if any
        TweetObject.syncDraftTweets({ success in
        })
        
        TweetObject.downloadUserTimeLine{ tweets, error in
            if let t = tweets {
                self.incomingTweets = t
                self.tableView.reloadData()
            }
            self.refreshControl.endRefreshing()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func onCompose(sender: AnyObject?) {
        if let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("TweetComposeViewController") as? TweetComposeViewController {
            vc.completionBlock = { needRefresh in
                if(needRefresh) {
                    self.loadTweets()
                }
            }
            navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    // MARK:  UITableViewDataSource Methods
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("TweetCell", forIndexPath: indexPath) as! TweetCell
        cell.customizeWithTweet(self.incomingTweets[indexPath.row])
        
        return cell
        
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return incomingTweets.count
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }


}

