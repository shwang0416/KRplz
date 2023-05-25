//
//  CaptureSampleApp.swift
//  CaptureSample
//
//  Created by sujung Hwang on 2023/05/25.
//

import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        print("applicationDidFinishLaunching")
        
        let contentView = ContentView()
        if let window = NSApplication.shared.windows.first {
            print(window)
            window.contentRect(forFrameRect: .zero)
//            window.styleMask([.fullSizeContentView])
            window.titlebarAppearsTransparent = true
//            window.center()
            window.level = .statusBar
//            window.setFrameAutosaveName("MyApp")
            
            let visualEffect = NSVisualEffectView()

            visualEffect.translatesAutoresizingMaskIntoConstraints = false
                visualEffect.blendingMode = .behindWindow
                visualEffect.state = .active
                visualEffect.material = .light
            window.contentView = visualEffect
            
            guard let constraints = window.contentView else {
              return
            }
            
            visualEffect.leadingAnchor.constraint(equalTo: constraints.leadingAnchor).isActive = true
            visualEffect.trailingAnchor.constraint(equalTo: constraints.trailingAnchor).isActive = true
            visualEffect.topAnchor.constraint(equalTo: constraints.topAnchor).isActive = true
            visualEffect.bottomAnchor.constraint(equalTo: constraints.bottomAnchor).isActive = true
            
            let hosting = NSHostingView(rootView: contentView)
            window.contentView?.addSubview(hosting, positioned: .below, relativeTo: window.contentView?.subviews.first)
            hosting.autoresizingMask = [.width, .height]
            hosting.setFrameSize(CGSize(width:window.frame.width, height:window.frame.height))
//            hosting.frame(minWidth: 960, minHeight: 724)
            
            guard let constraints = window.contentView else {
              return
            }
            
            visualEffect.leadingAnchor.constraint(equalTo: constraints.leadingAnchor).isActive = true
            visualEffect.trailingAnchor.constraint(equalTo: constraints.trailingAnchor).isActive = true
            visualEffect.topAnchor.constraint(equalTo: constraints.topAnchor).isActive = true
            visualEffect.bottomAnchor.constraint(equalTo: constraints.bottomAnchor).isActive = true
        }
        else {
            print("no window")
        }
    }
}

struct TestView: View {
    //    @EnvironmentObject var windowInfo: WindowInfo
    //    override func viewWillAppear() {
    //        super.viewWillAppear()
    //        print(view.window?.frame.origin)
    //    }
    //    print(window.frame.origin)
    //    print(windowInfo)
    


    
    var body: some View {
        VStack {
            Text("No screen recording permission.")
                .font(.largeTitle)
                .padding(.top)
//                .frame(maxWidth: .infinity, maxHeight: .infinity)
            Text("Open System Settings and go to Privacy & Security > Screen Recording to grant permission.")
                .font(.title2)
                .padding(.bottom)
        }
        
    }
}

@main
struct CaptureSampleApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var delegate
//    func buttonClick {
//        let nsRect = NSMakeRect(100,100,500,500)
//        setFrame(nsRect)
//    }

    var body: some Scene {
        WindowGroup {
//            ContentView()
//                .frame(minWidth: 960, minHeight: 724)
//                .background(.black)
            
        }.handlesExternalEvents(matching: ["main"])
            
        WindowGroup {
            TestView()
            Button {
                Task {
                    
                    self
                }
            } label: {
                Text("adjust position and size")
            }
        }.handlesExternalEvents(matching: ["detail"])
//        self.frame.origin

    }
}
