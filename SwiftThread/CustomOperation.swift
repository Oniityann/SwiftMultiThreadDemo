//
//  CustomOperation.swift
//  SwiftThread
//
//  Created by Oniityann on 2018/10/22.
//  Copyright © 2018 Oniityann. All rights reserved.
//

import UIKit

class CustomOperation: Operation {
    override func main() {
        
        // Things to do
        for _ in 0 ..< 2 {
            if isCancelled {
                print("Cunstom operation is cancelled.")
                break
            } else {
                print("Cunstom operation in thread: \(Thread.current)")
            }
        }
    }
}
