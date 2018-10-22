//
//  ThreadViewController.swift
//  SwiftThread
//
//  Created by Oniityann on 2018/10/22.
//  Copyright © 2018 Oniityann. All rights reserved.
//

import UIKit

class ThreadViewController: UIViewController {
    
    @IBOutlet weak var remainingLabel: UILabel!
    
    var ticketCount = 30
    var firstTicketWindow: Thread!
    var secondTicketWindow: Thread!
    var thirdTicketWindow: Thread!

    override func viewDidLoad() {
        super.viewDidLoad()
        
    }

    @IBAction func threadCreation1(_ sender: Any) {
        // convenience init(target: Any, selector: Selector, object argument: Any?)
        let thread = Thread(target: self, selector: #selector(thread1Action(_:)), object: "Thread1")
        thread.name = "Background 1"
        thread.start()
    }
    
    @IBAction func threadCreation2(_ sender: Any) {
        // class func detachNewThreadSelector(_ selector: Selector, toTarget target: Any, with argument: Any?)
        Thread.detachNewThreadSelector(#selector(thread2Action(_:)), toTarget: self, with: "Thread2")
    }
    
    @IBAction func threadCreation3(_ sender: Any) {
        performSelector(inBackground: #selector(thread3Action(_:)), with: "Thread3")
    }
    
    @IBAction func saleTicket(_ sender: Any) {
        
        firstTicketWindow = Thread(target: self, selector: #selector(saleTicketAction), object: "Ticket Window 1")
        firstTicketWindow.name = "Ticket Window 1"
        
        secondTicketWindow = Thread(target: self, selector: #selector(saleTicketAction), object: "Ticket Window 2")
        secondTicketWindow.name = "Ticket Window 2"
        
        thirdTicketWindow = Thread(target: self, selector: #selector(saleTicketAction), object: "Ticket Window 3")
        thirdTicketWindow.name = "Ticket Window 3"
        
        firstTicketWindow.start()
        secondTicketWindow.start()
        thirdTicketWindow.start()
    }
    
    @objc func thread1Action(_ obj: Any) {
        print("Thread 1 action parameter: \(obj), current thread: \(Thread.current)")
    }
    
    @objc func thread2Action(_ obj: Any) {
        print("Thread 2 action parameter: \(obj), current thread: \(Thread.current)")
    }
    
    @objc func thread3Action(_ obj: Any) {
        print("Thread 3 action parameter: \(obj), current thread: \(Thread.current)")
    }
    
    @objc func saleTicketAction() {
        
        while ticketCount > 0 {
            synchronized(self) {
                Thread.sleep(forTimeInterval: 0.1)
                if ticketCount > 0 {
                    ticketCount -= 1
                    print("\(Thread.current.name!) sold 1 ticket, \(self.ticketCount) remains.")
                    
                    // 主线程显示余票
                    self.performSelector(onMainThread: #selector(showTicketNum), with: nil, waitUntilDone: true)
                } else {
                    print("Tickets have been sold out.")
                }
            }
        }
    }
    
    func synchronized(_ lock: AnyObject, closure:() -> ()) {
        objc_sync_enter(lock)
        closure()
        objc_sync_exit(lock)
    }
    
    @objc func showTicketNum() {
        remainingLabel.text = "Ticket remains: \(ticketCount)"
    }
}




