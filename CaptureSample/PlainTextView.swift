//
//  PlainTextView.swift
//  CaptureSample
//
//  Created by sujung Hwang on 2023/05/21.
//  Copyright © 2023 Apple. All rights reserved.
//

import SwiftUI

struct PlainTextView: View {
    var text: String
    
   
    var body: some View {
        
        Text(text).font(.largeTitle)
    }
}
