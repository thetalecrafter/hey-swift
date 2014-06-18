//
//  DetailsViewController.swift
//  HeySwift
//
//  Created by Andy VanWagoner on 6/13/14.
//  Copyright (c) 2014 Andy VanWagoner. All rights reserved.
//

import UIKit
import MediaPlayer

class DetailsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, ItunesAPIControllerProtocol {

    @IBOutlet var albumCover: UIImageView
    @IBOutlet var priceLabel: UILabel
    @IBOutlet var openButton: UIButton
    @IBOutlet var tracksTableView: UITableView
    
    let mediaPlayer = MPMoviePlayerController()
    
    var api: ItunesAPIController!
    var album: Album?
    var songs: Song[] = []

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        api = ItunesAPIController(delegate: self)
        if album?.id {
            UIApplication.sharedApplication().networkActivityIndicatorVisible = true
            api.lookupInItunes(.Songs, inCollection: album!.id)
        }

        title = album?.name
        priceLabel.text = album?.formattedPrice
        albumCover.image = UIImage(named: "Blank52")
        
        if let urlString = album?.artworkDetailURL {
            UIImageLoader.loadURLString(urlString) {
                (image: UIImage!, error: NSError!) in
                if image {
                    self.albumCover.image = image
                }
            }
        }
        
        let center = NSNotificationCenter.defaultCenter(),
            queue = NSOperationQueue.mainQueue()
        center.addObserverForName("MPMoviePlayerPlaybackDidFinishNotification", object: mediaPlayer, queue: queue) {
            (notification: NSNotification!) in
            let reasonInt = notification.userInfo["MPMoviePlayerPlaybackDidFinishReasonUserInfoKey"] as? Int,
                reason = reasonInt ? MPMovieFinishReason.fromRaw(reasonInt!) : nil
            if MPMovieFinishReason.PlaybackEnded == reason {
                self.playbackDidFinish()
            }
        }
    }
    
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        mediaPlayer.stop()
        mediaPlayer.contentURL = nil
    }
    
    
    @IBAction func buyLinkTouchUp(sender: AnyObject) {
        if let url = album?.viewURL {
            println("Open album link at URL \(url)")
            UIApplication.sharedApplication().openURL(NSURL(string: url))
        }
    }
    
    
    func tableView(tableView: UITableView!, numberOfRowsInSection section: Int) -> Int {
        return songs.count
    }
    
    
    func tableView(tableView: UITableView!, cellForRowAtIndexPath indexPath: NSIndexPath!) -> UITableViewCell! {
        let reused = tableView.dequeueReusableCellWithIdentifier("SongCell") as? SongCell,
            cell = reused ? reused! : SongCell(),
            song = songs[indexPath.row]
            
        cell.titleLabel.text = song.name
        let artistText = (song.artistName != album?.artistName) ? " - " + song.artistName : ""
        cell.artistLabel.text = song.formattedPrice + artistText
        cell.showPlayIcon()
        
        return cell
    }
    
    
    func tableView(tableView: UITableView!, didSelectRowAtIndexPath indexPath: NSIndexPath!) {
        if let cell = tableView.cellForRowAtIndexPath(indexPath) as? SongCell {
            let song = songs[indexPath.row]
            let preview = NSURL(string: song.previewURL)
            if mediaPlayer.contentURL? == preview {
                if mediaPlayer.playbackState == .Paused {
                    mediaPlayer.play()
                    cell.showPauseIcon()
                    println("Resume \(song.name) from \(song.previewURL)")
                } else {
                    mediaPlayer.pause()
                    cell.showPlayIcon()
                    tableView.deselectRowAtIndexPath(indexPath, animated: true)
                    println("Pause \(song.name) from \(song.previewURL)")
                }
            } else {
                mediaPlayer.contentURL = preview
                mediaPlayer.play()
                cell.showPauseIcon()
                println("Play \(song.name) from \(song.previewURL)")
            }
        }
    }
    
    
    func tableView(tableView: UITableView!, didDeselectRowAtIndexPath indexPath: NSIndexPath!) {
        if let cell = tableView.cellForRowAtIndexPath(indexPath) as? SongCell {
            cell.showPlayIcon()
        }
    }
    
    
    func didRecieveAPIResults(results: NSDictionary) {
        UIApplication.sharedApplication().networkActivityIndicatorVisible = false
        if results["results"] {
            songs = []
            let items = results["results"] as NSDictionary[]
            for result in items {
                if let song = Song.songFromItunesAPIResult(result) {
                    songs.append(song)
                }
            }
            tracksTableView.reloadData()
        }
    }
    
    
    func playbackDidFinish() {
        println("Finshed song")
        if let indexPath = tracksTableView.indexPathForSelectedRow() {
            if let cell = tracksTableView.cellForRowAtIndexPath(indexPath) as? SongCell {
                tracksTableView.deselectRowAtIndexPath(indexPath, animated: true)
                cell.showPlayIcon()
            }
            
            if indexPath.row < songs.count - 1 {
                let row = indexPath.row + 1,
                newPath = NSIndexPath(forRow: row, inSection: indexPath.section)
                tracksTableView.selectRowAtIndexPath(newPath,
                    animated: true, scrollPosition: UITableViewScrollPosition.Top
                )
                tableView(tracksTableView, didSelectRowAtIndexPath: newPath)
            }
        }
    }
    

    /*
    // #pragma mark - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue?, sender: AnyObject?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
    }
    */

}