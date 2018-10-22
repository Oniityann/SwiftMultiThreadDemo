//
//  OperationViewController.swift
//  SwiftThread
//
//  Created by Oniityann on 2018/10/22.
//  Copyright © 2018 Oniityann. All rights reserved.
//

import UIKit

class OperationViewController: UIViewController {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var hideButton: UIButton!
    
    @IBOutlet weak var indicator: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    @IBAction func invocationCreation(_ sender: Any) {
        print("NSInvocationOperation is no longer available in swift, for it's not type-safe & ARC Safe.")
    }
    
    @IBAction func blockOperationCreation(_ sender: Any) {
        let operation = BlockOperation {
            print("An block operation without being added in a queue, the thread is: \(Thread.current)")
        }
        operation.start()
    }
    
    @IBAction func subclassOperationCreation(_ sender: Any) {
        let operation = CustomOperation()
        operation.start()
    }
    
    @IBAction func addExecutionBlock(_ sender: Any) {
        let operation = BlockOperation {
            print("Create a block operation in \(Thread.current).")
        }
        operation.addExecutionBlock {
            print("The block operation has add an execution block in \(Thread.current).")
        }
        operation.addExecutionBlock {
            print("The block operation has add an execution block in \(Thread.current).")
        }
        operation.start()
    }
    
    @IBAction func addOperationToQueue(_ sender: Any) {
        let queue = OperationQueue()
        
        let operation1 = BlockOperation {
            print("Operation 1 has beed added in a queue, in \(Thread.current).")
        }
        
        let operation2 = BlockOperation {
            print("Operation 2 has beed added in a queue, in \(Thread.current).")
        }
        
        // Operation1 和 Operation2 执行顺序是不固定的
        queue.addOperation(operation1)
        queue.addOperation(operation2)
    }
    
    @IBAction func queueAddOperationWithBlock(_ sender: Any) {
        let queue = OperationQueue()
        queue.addOperation {
            for _ in 0 ..< 2 {
                print("A queue add operation with block in \(Thread.current).")
            }
        }
    }
    
    @IBAction func downloadImageAndShow(_ sender: Any) {
        let downloadQueue = OperationQueue()
        
        indicator.startAnimating()
        
        downloadQueue.addOperation {
            
            Thread.sleep(forTimeInterval: 1)
            
            let imageURLString = "https://clutchpoints.com/wp-content/uploads/2018/09/lebron-james.png"
            let imageURL = URL(string: imageURLString)
            let data = try? Data(contentsOf: imageURL!)
            
            guard let theData = data else {
                OperationQueue.main.addOperation {
                    self.indicator.stopAnimating()
                }
                print("Download failed.")
                return
            }
            let image = UIImage(data: theData)
            
            OperationQueue.main.addOperation {
                if let image = image {
                    self.imageView.image = image
                    self.hideButton.isHidden = false
                    self.imageView.isHidden = false
                    self.indicator.stopAnimating()
                }
            }
        }
    }
    
    @IBAction func maxConcurrentNumber(_ sender: Any) {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        queue.addOperation {
            print("First operation - max concurrent number in \(Thread.current).")
        }
        queue.addOperation {
            print("Second operation - max concurrent number in \(Thread.current).")
        }
        queue.addOperation {
            print("Third operation - max concurrent number in \(Thread.current).")
        }
        queue.addOperation {
            print("Fourth operation - max concurrent number in \(Thread.current).")
        }
    }
    
    @IBAction func threadDependency(_ sender: Any) {
        let queue = OperationQueue()
        
        var flag = false
        let operation1 = BlockOperation {
            flag = true
            print("Operation 1 in \(Thread.current).")
            Thread.sleep(forTimeInterval: 2)
        }
        
        // 监听 Operation 1 是否完成
        operation1.completionBlock = {
            print("Operation 1 is completed.")
        }
        
        let operation2 = BlockOperation {
            if flag {
                print("Operation 2 in \(Thread.current).")
            } else {
                print("Something went wrong.")
            }
        }
        
        operation2.addDependency(operation1)
        
        queue.addOperation(operation1)
        queue.addOperation(operation2)
    }
    
    @IBAction func cancelOperation(_ sender: Any) {
        let queue = OperationQueue()
        queue.addOperation {
            for i in 0 ... 100000000 {
                print("i: \(i) in \(Thread.current)")
            }
        }
        queue.cancelAllOperations()
        queue.addOperation {
            print("Second operation in \(Thread.current)")
        }
        
        let operation = CustomOperation()
        operation.cancel()
    }
    
    @IBAction func hideImageView(_ sender: UIButton) {
        imageView.isHidden = true
        imageView.image = nil
        sender.isHidden = true
    }
}
