//  PDFViewController.swift
//  PDFReader
//
//  Created by ALUA KINZHEBAYEVA on 4/19/15.
//  Copyright (c) 2015 AK. All rights reserved.
//

import UIKit

internal final class PDFViewController: UIViewController {
    @IBOutlet private var collectionView: UICollectionView!
    
    var document: PDFDocument!
    private var currentPDFPage: PDFPageView!
    private var currentPageIndex: Int = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView!.registerClass(UICollectionViewCell.self, forCellWithReuseIdentifier: "page")
    }
    
    override func willAnimateRotationToInterfaceOrientation(toInterfaceOrientation: UIInterfaceOrientation, duration: NSTimeInterval) {
        let newContentOffsetX = CGFloat(currentPageIndex) * collectionView.bounds.size.width
        collectionView.contentOffset = CGPointMake(newContentOffsetX, collectionView.contentOffset.y)
        collectionView.collectionViewLayout.invalidateLayout()
    }
    
    @IBAction func print() {
        guard UIPrintInteractionController.isPrintingAvailable() else { return }
        guard UIPrintInteractionController.canPrintURL(document.fileURL) else { return }
        
        let printInfo = UIPrintInfo.printInfo()
        printInfo.duplex = .LongEdge
        printInfo.outputType = .General
        printInfo.jobName = document.fileName
        
        let printInteraction = UIPrintInteractionController.sharedPrintController()
        printInteraction.printInfo = printInfo
        printInteraction.printingItem = document.fileURL
        printInteraction.showsPageRange = true
        printInteraction.presentAnimated(true, completionHandler: nil)
    }
    
    /// Returns page view
    private func pageView(page: Int, cellBounds: CGRect) -> UIScrollView {
        let pageTuple = document.getPage(page)
        guard let pageRef = pageTuple.pageRef else { fatalError() }
        guard let backgroundImage = pageTuple.backgroundImage else { fatalError() }
        let scrollView = PDFPageView(frame: cellBounds, PDFPageRef: pageRef, backgroundImage: backgroundImage)
        
        currentPDFPage = scrollView
        let doubleTapOne = UITapGestureRecognizer(target: scrollView, action:#selector(PDFPageView.handleDoubleTap(_:)))
        doubleTapOne.numberOfTapsRequired = 2
        doubleTapOne.cancelsTouchesInView = false
        scrollView.addGestureRecognizer(doubleTapOne)
        return scrollView
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let controller = segue.destinationViewController as? PDFThumbnailCollectionViewController {
            controller.document = document
            controller.delegate = self
        }
    }
}

extension PDFViewController: PDFThumbnailControllerDelegate {
    func didSelectIndexPath(indexPath: NSIndexPath) {
        collectionView.scrollToItemAtIndexPath(indexPath, atScrollPosition: .Left, animated: true)
    }
}

extension PDFViewController: UICollectionViewDataSource {
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return document.pageCount.integerValue
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("page", forIndexPath: indexPath)
        cell.subviews.forEach({ $0.removeFromSuperview() })
        cell.addSubview(pageView(indexPath.row, cellBounds: cell.bounds))
        return cell
    }
}

extension PDFViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        return CGSizeMake(collectionView.frame.size.width, collectionView.frame.size.height)
    }
}

extension PDFViewController: UIScrollViewDelegate {
    func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        self.currentPageIndex =  Int(floor(collectionView.contentOffset.x / collectionView.bounds.size.width))
    }
}
