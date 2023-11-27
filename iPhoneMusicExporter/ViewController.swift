//
//  ViewController.swift
//  iPhoneMusicExporter
//

import UIKit
import QuickLook
import MediaPlayer
import AVKit


class PreviewItem: NSObject, QLPreviewItem {
    var previewItemURL: URL?
    var previewItemTitle: String?

    init(url: URL) {
        previewItemURL = url
        previewItemTitle = url.pathComponents.last
    }
}

class ViewController: UIViewController {
    @IBOutlet weak var console: UITextView!
    @IBOutlet weak var allButton: UIButton!
    @IBOutlet weak var selectedButton: UIButton!
    @IBOutlet weak var previewButton: UIButton!
    
    var index = 0
    var qlItems: [QLPreviewItem]?

    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    @IBAction func allMusicAction(_ sender: Any) {
        guard let items = MPMediaQuery.songs().items else {
            addToConsole(text: "Unable to fetch your media items")
            return
        }
        addToConsole(text: "Export started")
        continueSaving(items: items)
    }
    
    @IBAction func selectedMusicAction(_ sender: Any) {
        let controller = MPMediaPickerController(mediaTypes: .music)
        controller.allowsPickingMultipleItems = true
        controller.delegate = self
        present(controller, animated: true)
    }
    
    @IBAction func previewAction(_ sender: Any) {
        if let contents = try? FileManager.default.contentsOfDirectory(at: documentsDirectory(), includingPropertiesForKeys: nil, options: .skipsSubdirectoryDescendants), contents.count > 0 {
            let controller = QLPreviewController()
            controller.dataSource = self
            qlItems = []
            for content in contents {
                qlItems?.append(PreviewItem(url: content))
            }
            clearConsole()
            present(controller, animated: true)
        } else {
            addToConsole(text: "No items available for preview")
        }
    }
    
    func addToConsole(text: String) {
        DispatchQueue.main.async {
            self.console.text = text + "\n\n" + self.console.text
        }
    }
    
    func clearConsole(){
        DispatchQueue.main.async {
            self.console.text = ""
        }
    }
    
    func continueSaving(items: [MPMediaItem]) {
        guard index < items.count else {
            addToConsole(text: "Finished Saving")
            return
        }
        
        save(items[index]) { (status) in
            self.index = self.index + 1
            self.continueSaving(items: items)
        }
    }
    
    func documentsDirectory() -> URL {
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    }
    
    func save(_ item: MPMediaItem, completion: @escaping (Bool) -> Void) {
        guard let pathURL = item.assetURL else {
            completion(false)
            return
        }
        let title = item.title ?? "Unknown"
        guard let exportSession = AVAssetExportSession(asset: AVAsset(url: pathURL), presetName: AVAssetExportPresetAppleM4A) else {
            addToConsole(text: "Unable to extract '\(title)'")
            completion(false)
            return
        }
        addToConsole(text: "Exporting '\(title)'")
        exportSession.shouldOptimizeForNetworkUse = true
        exportSession.outputFileType = AVFileType.m4a
        exportSession.outputURL = documentsDirectory().appendingPathComponent(title + ".m4a")
        exportSession.exportAsynchronously(completionHandler: { () -> Void in
            if exportSession.status == AVAssetExportSession.Status.completed  {
                self.addToConsole(text: "'\(title)' exported successfully")
                completion(true)
            } else {
                self.addToConsole(text: "Music '\(title)' export failed with error\(exportSession.error?.localizedDescription ?? "All is Well")")
                completion(false)
            }
            
        })
    }
    
}


extension ViewController: QLPreviewControllerDataSource {
    func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        return qlItems?.count ?? 0
    }

    func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        return qlItems![index]
    }
    
}

extension ViewController: MPMediaPickerControllerDelegate {
    func mediaPicker(_ mediaPicker: MPMediaPickerController, didPickMediaItems mediaItemCollection: MPMediaItemCollection) {
        mediaPicker.dismiss(animated: true)
        if let item = mediaItemCollection.items.first {
            if(mediaItemCollection.items.count > 1) {
                for i in mediaItemCollection.items {
                    save(i) {(status) in}
                }
            } else {
                save(item) {(status) in}
            }
        } else {
            addToConsole(text: "Media unavailable")
        }
        
    }

}


