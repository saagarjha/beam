//
//  PostImagePartCell.swift
//  beam
//
//  Created by Robin Speijer on 21-07-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import UIKit
import Snoo
import SDWebImage
import AVKit
import AVFoundation

class PostImagePartCell: BeamTableViewCell, MediaImageLoader, MediaCellMediaLabels {
    
    private var ImageViewHiddenObserverContext = 0
    
    var imageOperation: SDWebImageOperation?
    
    var useCompactViewMode = false {
        didSet {
            self.configureCellHeight()
        }
    }
    
    @IBOutlet fileprivate var imageHeightConstraint: NSLayoutConstraint!
    @IBOutlet var mediaImageView: UIImageView!
    @IBOutlet var spoilerView: ImageSpoilerView!
    @IBOutlet var mediaLabelImageViews: [UIImageView]?
    
    @IBOutlet var gifPlayerView: GIFPlayerView!
    
    @IBOutlet fileprivate var progressView: CircularProgressView!
    
    var mediaObject: MediaObject? {
        didSet {
            self.configureCellHeight()
            self.spoilerView.reset()
            if self.mediaObject != oldValue {
                self.stopImageLoading()
                
                self.mediaImageView.image = nil
                
                AppDelegate.shared.retainNetworkIndicator(self)
                self.startImageLoading()
                
                let isLoading = self.imageOperation != nil
                self.progressView.isHidden = !isLoading
                self.progressView.progress = 0
                
                self.reloadMediaLabels()
                
            }
        }
    }
    
    var preferredThumbnailSize: CGSize {
        return UIScreen.main.bounds.size
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.mediaImageView.addObserver(self, forKeyPath: #keyPath(UIImageView.isHidden), options: [.new], context: &self.ImageViewHiddenObserverContext)
    }
    
    deinit {
        self.mediaImageView.removeObserver(self, forKeyPath: #keyPath(UIImageView.isHidden), context: &self.ImageViewHiddenObserverContext)
        NotificationCenter.default.removeObserver(self)
    }
    
    
    /// Prepares the cell for give playback. It adds the asset to play and plays it if possible
    func prepareGIFPlayback() {
        if let animatedUrl = self.mediaObject?.galleryItem.animatedURLString, self.mediaObject?.galleryItem.animated == true && self.mediaObject?.galleryItem.isMP4GIF == true && GIFPlayerView.canAutoplayGifs {
            self.gifPlayerView.isHidden = false
            self.gifPlayerView.play(url: animatedUrl)
        } else {
            self.gifPlayerView.stop()
            self.gifPlayerView.isHidden = true
        }
    }
    
    func imageLoadingCompleted() {
        self.progressView.isHidden = true
        AppDelegate.shared.releaseNetworkIndicator(self)
    }
    
    func progressDidChange(_ progress: CGFloat) {
        self.progressView.progress = progress
    }
    
    fileprivate func configureCellHeight() {
        self.imageHeightConstraint.constant = PostImagePartCell.heightForMediaObject(self.mediaObject, useCompactViewMode: self.useCompactViewMode, forWidth: self.bounds.width)
    }
    
    override func displayModeDidChange() {
        super.displayModeDidChange()
        
        self.mediaImageView.isOpaque = true
        self.mediaImageView.backgroundColor = DisplayModeValue(UIColor(red:0.96, green:0.96, blue:0.96, alpha:1), darkValue: UIColor(red:0.17, green:0.17, blue:0.17, alpha:1))
        self.progressView.color = displayMode == .dark ?  UIColor.white : UIColor.beamGreyExtraLight()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        self.gifPlayerView.stop()
        
        self.contentView.isHidden = false
        self.mediaImageView.isHidden = false
        self.spoilerView.reset()
    }
    
    class func heightForMediaObject(_ mediaObject: MediaObject?, useCompactViewMode: Bool, forWidth width: CGFloat) -> CGFloat {
        if useCompactViewMode {
            let ratio:CGFloat = 16 / 9
            return floor(width / ratio)
        } else if let imageSize = mediaObject?.aspectRatioSizeWithMaxWidth(width, maxHeight: UIScreen.main.bounds.size.height) {
            return floor(imageSize.height)
        }
        return 100
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if context == &self.ImageViewHiddenObserverContext {
            self.gifPlayerView.isHidden = self.mediaImageView.isHidden
        } else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }

}
