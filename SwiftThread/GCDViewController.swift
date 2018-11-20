//
//  GCDViewController.swift
//  SwiftThread
//
//  Created by Oniityann on 2018/10/22.
//  Copyright © 2018 Oniityann. All rights reserved.
//

import UIKit

class GCDViewController: UIViewController {

    @IBOutlet weak var imageView1: UIImageView!
    @IBOutlet weak var imageView2: UIImageView!
    
    @IBOutlet weak var indicator1: UIActivityIndicatorView!
    @IBOutlet weak var indicator2: UIActivityIndicatorView!
    
    @IBOutlet weak var hideButton: UIButton!
    
    let imageURLString1 = "https://clutchpoints.com/wp-content/uploads/2018/09/lebron-james.png"
    let imageURLString2 = "https://image.cleveland.com/home/cleve-media/width960/img/ent_impact_home/photo/lebron-james-fd7471e93488c597.jpg"
    
    override func viewDidLoad() {
        super.viewDidLoad()

        print("View did load.")
        let dispatchTime = DispatchTime.now() + 0.5
        DispatchQueue.main.asyncAfter(deadline: dispatchTime) {
            print("After 0.5 seconds.")
        }
    }
    
    @IBAction func serialAndSync(_ sender: Any) {
        let queue = DispatchQueue(label: "com.demo.Serial1")
        // 串行队列做同步操作, 容易造成死锁, 不建议这样使用
        queue.sync {
            print("Sync operation in a serial queue.")
        }
    }
    
    @IBAction func serialAndAsync(_ sender: Any) {
        let queue = DispatchQueue(label: "com.demo.Serial2")
        
        // 串行队列做异步操作是顺序执行
        queue.async {
            print(Thread.current)
            for i in 0 ..< 2 {
                print("First i: \(i)")
            }
        }
        queue.async {
            print(Thread.current)
            for i in 0 ..< 2 {
                print("Second i: \(i)")
            }
        }
    }
    
    @IBAction func concurrentAndSync(_ sender: Any) {
        let label = "com.demo.Concurrent1"
        let qos = DispatchQoS.default
        let attributes = DispatchQueue.Attributes.concurrent
        let autoreleaseFrequency = DispatchQueue.AutoreleaseFrequency.never
        let queue = DispatchQueue(label: label, qos: qos, attributes: attributes, autoreleaseFrequency: autoreleaseFrequency, target: nil)
        
        // 并发队列同步操作是顺序执行
        queue.sync {
            for i in 0 ..< 2 {
                print("First sync i: \(i)")
            }
        }
        queue.sync {
            for i in 0 ..< 2 {
                print("Second sync i: \(i)")
            }
        }
    }
    
    @IBAction func concurrentAndAsync(_ sender: Any) {
        let label = "com.demo.Concurrent2"
        let attributes = DispatchQueue.Attributes.concurrent
        let queue = DispatchQueue(label: label, attributes: attributes)
        
        // 并发队列做异步操作执行顺序不固定
        queue.async {
            for i in 0 ..< 2 {
                print("First async i: \(i)")
            }
        }
        queue.async {
            for i in 0 ..< 2 {
                print("Second async i: \(i)")
            }
        }
    }
    
    @IBAction func mainQSync(_ sender: Any) {
        print("Sync in main queue will cause dead lock.")
    }
    
    @IBAction func mainQAsync(_ sender: Any) {
        // 串行队列做异步操作是顺序执行
        DispatchQueue.main.async {
            for i in 0 ..< 2 {
                print("First main queue async i: \(i)")
            }
        }
        DispatchQueue.main.async {
            for i in 0 ..< 2 {
                print("Second main queue async i: \(i)")
            }
        }
    }
    
    @IBAction func downloadImage(_ sender: Any) {
        indicator1.startAnimating()
//        let queue = DispatchQueue.global(qos: .default)
        DispatchQueue.global().async {
            sleep(1)
            let imageURL = URL(string: self.imageURLString1)
            let data = try? Data(contentsOf: imageURL!)
            
            guard let theData = data else {
                OperationQueue.main.addOperation {
                    self.indicator1.stopAnimating()
                }
                print("Download failed.")
                return
            }
            let image = UIImage(data: theData)
            
            DispatchQueue.main.async {
                if let image = image {
                    self.imageView1.image = image
                    self.hideButton.isHidden = false
                    self.imageView1.isHidden = false
                    self.indicator1.stopAnimating()
                }
            }
        }
    }
    
    @IBAction func downloadImagesInGroup(_ sender: Any) {
        
        indicator1.startAnimating()
        indicator2.startAnimating()
        
        let group = DispatchGroup()
        
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first
        var fileURL1 = URL(fileURLWithPath: documentsPath!)
        fileURL1 = fileURL1.appendingPathComponent("LBJ1")
        fileURL1 = fileURL1.appendingPathExtension("png")
        
        var fileURL2 = URL(fileURLWithPath: documentsPath!)
        fileURL2 = fileURL2.appendingPathComponent("LBJ2")
        fileURL2 = fileURL2.appendingPathExtension("jpg")
        
        group.enter()
        DispatchQueue.global().async {
            
            print("Begin to download image1.")
            
            let imageURL = URL(string: self.imageURLString1)
            let data = try? Data(contentsOf: imageURL!)
            
            guard let theData = data else {
                DispatchQueue.main.async {
                    self.indicator1.stopAnimating()
                }
                print("Image 1 download failed.")
                return
            }
            
            try! theData.write(to: fileURL1, options: .atomic)
            
            print("Image1 downloaded.")
            sleep(1)
            group.leave()
        }
        
        group.enter()
        DispatchQueue.global().async {
            
            print("Begin to download image2.")
            
            let imageURL = URL(string: self.imageURLString2)
            let data = try? Data(contentsOf: imageURL!)
            
            guard let theData = data else {
                DispatchQueue.main.async {
                    self.indicator2.stopAnimating()
                }
                print("Image 2 Download failed.")
                return
            }
            
            try! theData.write(to: fileURL2, options: .atomic)
            
            sleep(1)
            print("Image2 downloaded.")
            group.leave()
        }
        
        group.notify(queue: .main) {

            let imageData1 = try? Data(contentsOf: fileURL1)
            let imageData2 = try? Data(contentsOf: fileURL2)
            
            guard let theData1 = imageData1 else {
                return
            }
            guard let theData2 = imageData2 else {
                return
            }
            
            let image1 = UIImage(data: theData1)
            let image2 = UIImage(data: theData2)
            
            self.imageView1.image = image1
            self.imageView2.image = image2
            self.imageView1.isHidden = false
            self.imageView2.isHidden = false
            self.indicator1.stopAnimating()
            self.indicator2.stopAnimating()
            self.hideButton.isHidden = false
        }
    }
    
    @IBAction func barrier(_ sender: Any) {
        let label = "com.demo.Concurrent3"
        let queue = DispatchQueue(label: label, attributes: .concurrent)
        
        queue.async {
            for i in 0 ..< 2 {
                print("First i: \(i)")
            }
        }
        queue.async {
            for i in 0 ..< 2 {
                print("Second i: \(i)")
            }
        }
        
        queue.async(flags: .barrier) {
            print("This is a barrier.")
        }
        
        queue.async {
            for i in 0 ..< 2 {
                print("Third i: \(i)")
            }
        }
        queue.async {
            for i in 0 ..< 2 {
                print("Fourth i: \(i)")
            }
        }
    }
    
    @IBAction func semaphore(_ sender: Any) {
        let semaphore = DispatchSemaphore(value: 2)
        
        // semaphore 在串行队列需要注意死锁问题
        let queue = DispatchQueue(label: "com.demo.Concurrent4", qos: .default, attributes: .concurrent)
        
        queue.async {
            semaphore.wait()
            print("First car in.")
            sleep(3)
            print("First car out.")
            semaphore.signal()
        }
        
        queue.async {
            semaphore.wait()
            print("Second car in.")
            sleep(2)
            print("Second car out.")
            semaphore.signal()
        }
        
        queue.async {
            semaphore.wait()
            print("Third car in.")
            sleep(4)
            print("Third car out.")
            semaphore.signal()
        }
    }
    
    @IBAction func hideImage(_ sender: Any) {
        self.imageView1.isHidden = true
        self.imageView2.isHidden = true
        self.hideButton.isHidden = true
        self.indicator1.stopAnimating()
        self.indicator2.stopAnimating()
        self.imageView1.image = nil
        self.imageView2.image = nil
    }
    
}


