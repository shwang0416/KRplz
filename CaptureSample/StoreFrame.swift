//
//  StoreFrame.swift
//  CaptureSample
//
//  Created by sujung Hwang on 2023/05/24.
//  Copyright © 2023 Apple. All rights reserved.
//

import Foundation


@MainActor
class StoreFrame {
    
    var currentFrame:CapturedFrame? = CapturedFrame(surface: nil, contentRect: .zero, contentScale: 0, scaleFactor: 0)

    init(currentFrame: CapturedFrame) {
        self.currentFrame = currentFrame
    }

}
