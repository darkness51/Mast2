//
//  DetailController.swift
//  MastWatch Extension
//
//  Created by Shihab Mehboob on 09/10/2018.
//  Copyright © 2018 Shihab Mehboob. All rights reserved.
//

import WatchKit
import Foundation

class DetailController: WKInterfaceController {
    
    @IBOutlet var tableView: WKInterfaceTable!
    @IBOutlet var replyB: WKInterfaceGroup!
    @IBOutlet var likeB: WKInterfaceGroup!
    @IBOutlet var boostB: WKInterfaceGroup!
    @IBOutlet weak var likeB2: WKInterfaceButton!
    @IBOutlet weak var boostB2: WKInterfaceButton!
    
    var allThings: [Status] = []
    var isShowing = true
    
    var isLiked: Bool = false
    var isBoosted: Bool = false
    
    @IBAction func replyTap() {
        WKInterfaceDevice.current().play(.click)
        let textChoices = ["Yes","No","Maybe","I love Mast"]
        presentTextInputController(withSuggestions: textChoices, allowedInputMode: WKTextInputMode.allowEmoji, completion: {(results) -> Void in
            if results != nil && results?.count ?? 0 > 0 {
                let aResult = results?.first as? String
                StoreStruct.tootText = aResult ?? ""
                StoreStruct.replyID = self.allThings[StoreStruct.currentRow].reblog?.inReplyToID ?? self.allThings[StoreStruct.currentRow].inReplyToID ?? ""
                self.presentController(withName: "TootController", context: nil)
            }
        })
    }
    
    @IBAction func likeTap() {
        WKInterfaceDevice.current().play(.click)
        let symbolConfig = UIImage.SymbolConfiguration(pointSize: 24, weight: .regular)
        if self.allThings[StoreStruct.currentRow].reblog?.favourited ?? self.allThings[StoreStruct.currentRow].favourited ?? true || self.isLiked {
            DispatchQueue.main.async {
                self.isLiked = false
                self.likeB.setBackgroundImage(UIImage(systemName: "heart.circle.fill", withConfiguration: symbolConfig)?.withTintColor(UIColor(named: "baseWhite")!.withAlphaComponent(0.35), renderingMode: .alwaysOriginal))
            }
            let request = Statuses.unfavourite(id: self.allThings[StoreStruct.currentRow].reblog?.id ?? self.allThings[StoreStruct.currentRow].id)
            StoreStruct.client.run(request) { (statuses) in
                
            }
        } else {
            DispatchQueue.main.async {
                self.isLiked = true
                self.likeB.setBackgroundImage(UIImage(systemName: "heart.circle.fill", withConfiguration: symbolConfig)?.withTintColor(UIColor(red: 224/255, green: 86/255, blue: 72/255, alpha: 1).withAlphaComponent(1), renderingMode: .alwaysOriginal))
            }
            let request = Statuses.favourite(id: self.allThings[StoreStruct.currentRow].reblog?.id ?? self.allThings[StoreStruct.currentRow].id)
            StoreStruct.client.run(request) { (statuses) in
                
            }
        }
    }
    
    @IBAction func boostTap() {
        WKInterfaceDevice.current().play(.click)
        let symbolConfig = UIImage.SymbolConfiguration(pointSize: 24, weight: .regular)
        if self.allThings[StoreStruct.currentRow].reblog?.reblogged ?? self.allThings[StoreStruct.currentRow].reblogged ?? true || self.isBoosted {
            DispatchQueue.main.async {
                self.isBoosted = false
                self.boostB.setBackgroundImage(UIImage(systemName: "arrow.2.circlepath.circle.fill", withConfiguration: symbolConfig)?.withTintColor(UIColor(named: "baseWhite")!.withAlphaComponent(0.35), renderingMode: .alwaysOriginal))
            }
            let request = Statuses.unreblog(id: self.allThings[StoreStruct.currentRow].reblog?.id ?? self.allThings[StoreStruct.currentRow].id)
            StoreStruct.client.run(request) { (statuses) in
                
            }
        } else {
            DispatchQueue.main.async {
                self.isBoosted = true
                self.boostB.setBackgroundImage(UIImage(systemName: "arrow.2.circlepath.circle.fill", withConfiguration: symbolConfig)?.withTintColor(UIColor(red: 92/255, green: 171/255, blue: 116/255, alpha: 1).withAlphaComponent(1), renderingMode: .alwaysOriginal))
            }
            let request = Statuses.reblog(id: self.allThings[StoreStruct.currentRow].reblog?.id ?? self.allThings[StoreStruct.currentRow].id)
            StoreStruct.client.run(request) { (statuses) in
                
            }
        }
    }
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        if #available(watchOSApplicationExtension 5.1, *) {
            self.tableView.curvesAtTop = true
            self.tableView.curvesAtBottom = true
        }
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        self.setTitle("Detail")
        
        self.allThings = StoreStruct.allStats
        if StoreStruct.fromWhere == 2 {
            self.allThings = StoreStruct.allStatsLocal
        }
        if StoreStruct.fromWhere == 3 {
            self.allThings = StoreStruct.allStatsFed
        }
        if StoreStruct.fromWhere == 4 {
            self.allThings = StoreStruct.allStatsProfile
        }
        
        let symbolConfig = UIImage.SymbolConfiguration(pointSize: 24, weight: .regular)
        replyB.setBackgroundImage(UIImage(systemName: "arrowshape.turn.up.left.circle.fill", withConfiguration: symbolConfig)?.withTintColor(UIColor(named: "baseWhite")!.withAlphaComponent(0.35), renderingMode: .alwaysOriginal))
        likeB.setBackgroundImage(UIImage(systemName: "heart.circle.fill", withConfiguration: symbolConfig)?.withTintColor(UIColor(named: "baseWhite")!.withAlphaComponent(0.35), renderingMode: .alwaysOriginal))
        boostB.setBackgroundImage(UIImage(systemName: "arrow.2.circlepath.circle.fill", withConfiguration: symbolConfig)?.withTintColor(UIColor(named: "baseWhite")!.withAlphaComponent(0.35), renderingMode: .alwaysOriginal))
        if self.allThings[StoreStruct.currentRow].reblog?.favourited ?? self.allThings[StoreStruct.currentRow].favourited ?? true {
            self.isLiked = true
            likeB.setBackgroundImage(UIImage(systemName: "heart.circle.fill", withConfiguration: symbolConfig)?.withTintColor(UIColor(red: 156/255, green: 143/255, blue: 247/255, alpha: 1).withAlphaComponent(1), renderingMode: .alwaysOriginal))
        }
        if self.allThings[StoreStruct.currentRow].reblog?.reblogged ?? self.allThings[StoreStruct.currentRow].reblogged ?? true {
            self.isBoosted = true
            boostB.setBackgroundImage(UIImage(systemName: "arrow.2.circlepath.circle.fill", withConfiguration: symbolConfig)?.withTintColor(UIColor(red: 156/255, green: 143/255, blue: 247/255, alpha: 1).withAlphaComponent(1), renderingMode: .alwaysOriginal))
        }
        
        self.tableView.setNumberOfRows(1, withRowType: "DetailRow")
        let controller = self.tableView.rowController(at: 0) as! DetailRow
        
        controller.imageView.setWidth(20)
        
        controller.userName.setText("@\(self.allThings[StoreStruct.currentRow].reblog?.account.username ?? self.allThings[StoreStruct.currentRow].account.username)")
        controller.userName.setTextColor(UIColor.white.withAlphaComponent(0.6))
        controller.screenName.setText("\(self.allThings[StoreStruct.currentRow].reblog?.account.displayName ?? self.allThings[StoreStruct.currentRow].account.displayName)")
        controller.screenName.setTextColor(UIColor.white.withAlphaComponent(0.6))
        
            self.getDataFromUrl(url: URL(string: self.allThings[StoreStruct.currentRow].reblog?.account.avatar ?? self.allThings[StoreStruct.currentRow].account.avatar)!) { data, response, error in
                guard let data = data, error == nil else { return }
                if self.isShowing {
                    controller.imageView.setImageData(data)
                }
            }
        
        controller.likesText.setText("\(self.allThings[StoreStruct.currentRow].reblog?.favouritesCount ?? self.allThings[StoreStruct.currentRow].favouritesCount) Likes")
        controller.likesText.setTextColor(UIColor.white.withAlphaComponent(0.6))
        
        controller.boostsText.setText("\(self.allThings[StoreStruct.currentRow].reblog?.reblogsCount ?? self.allThings[StoreStruct.currentRow].reblogsCount) Boosts")
        controller.boostsText.setTextColor(UIColor.white.withAlphaComponent(0.6))
        
    controller.timeText.setText(self.allThings[StoreStruct.currentRow].reblog?.createdAt.toString(dateStyle: .medium, timeStyle: .medium) ?? self.allThings[StoreStruct.currentRow].createdAt.toString(dateStyle: .medium, timeStyle: .medium))
        controller.timeText.setTextColor(UIColor.white.withAlphaComponent(0.6))
        
        controller.tootText.setText("\(self.allThings[StoreStruct.currentRow].reblog?.content.stripHTML() ?? self.allThings[StoreStruct.currentRow].content.stripHTML())")
        
        if self.allThings[StoreStruct.currentRow].reblog?.mediaAttachments.count ?? self.allThings[StoreStruct.currentRow].mediaAttachments.count > 0 {
        let xImage = self.allThings[StoreStruct.currentRow].reblog?.mediaAttachments[0].previewURL ?? self.allThings[StoreStruct.currentRow].mediaAttachments[0].previewURL
        if xImage != "" {
            self.getDataFromUrl(url: URL(string: xImage)!) { data, response, error in
                guard let data = data, error == nil else { return }
                DispatchQueue.main.async() {
                    controller.imageView2.setImageData(data)
                }
            }
        } else {
            controller.imageView2.setHeight(0)
        }
        } else {
            controller.imageView2.setHeight(0)
        }
    }
    
    func getDataFromUrl(url: URL, completion: @escaping (Data?, URLResponse?, Error?) -> ()) {
        URLSession.shared.dataTask(with: url) { data, response, error in
            completion(data, response, error)
            }.resume()
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }
    
    override func willDisappear() {
        self.isShowing = false
    }
}
