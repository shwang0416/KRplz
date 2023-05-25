/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A model object that provides the interface to capture screen content and system audio.
*/

import Foundation
import ScreenCaptureKit
import Combine
import OSLog
import SwiftUI

/// A provider of audio levels from the captured samples.
//class AudioLevelsProvider: ObservableObject {
//    @Published var audioLevels = AudioLevels.zero
//}

@MainActor
class ScreenRecorder: ObservableObject {

   
    /// The supported capture types.
    enum CaptureType {
        case display
        case window
    }
    
    private let logger = Logger()
    
    @Published var isRunning = false
    
    // MARK: - Video Properties
    @Published var captureType: CaptureType = .display {
        didSet { updateEngine() }
    }
    
    @Published var selectedDisplay: SCDisplay? {
        didSet { updateEngine() }
    }
    
    @Published var selectedWindow: SCWindow? {
        didSet { updateEngine() }
    }
    
    @Published var isAppExcluded = true {
        didSet { updateEngine() }
    }
    
    @Published var contentSize = CGSize(width: 1, height: 1)
    private var scaleFactor: Int { Int(NSScreen.main?.backingScaleFactor ?? 2) }
    
    @Published var windowPosition =  CGRect(x: 0,y: 0,width: 100,height: 100) {
        didSet { updateEngine() }
    }
    /// A view that renders the screen content.
//    lazy var capturePreview: CapturePreview = {
//        CapturePreview()
//    }()
    
    /// A view that renders the screen content.
//    lazy var contentView: ContentView = {
//        ContentView()
//    }()
    
    
    private var availableApps = [SCRunningApplication]()
    @Published private(set) var availableDisplays = [SCDisplay]()
    @Published private(set) var availableWindows = [SCWindow]()
    
//    // MARK: - Audio Properties
//    @Published var isAudioCaptureEnabled = true {
//        didSet {
//            updateEngine()
//            if isAudioCapture
//                startAudioMetering()
//            } else {
//                stopAudioMetering()
//            }
//        }
//    }
//    @Published var isAppAudioExcluded = false { didSet { updateEngine() } }
//    @Published private(set) var audioLevelsProvider = AudioLevelsProvider()
    // A value that specifies how often to retrieve calculated audio levels.
//    private let audioLevelRefreshRate: TimeInterval = 0.1
//    private var audioMeterCancellable: AnyCancellable?
    
    // The object that manages the SCStream.
    private let captureEngine = CaptureEngine()
    
    private var isSetup = false
//    @Published var currentFrame:CapturedFrame? = CapturedFrame(surface: nil, contentRect: .zero, contentScale: 0, scaleFactor: 0)
    @Published var currentFrame:StoreFrame? = StoreFrame(currentFrame:CapturedFrame(surface: nil, contentRect: .zero, contentScale: 0, scaleFactor: 0))
//    weak var currentFrame:StoreFrame? = StoreFrame(currentFrame:CapturedFrame(surface: nil, contentRect: .zero, contentScale: 0, scaleFactor: 0))

//        let data1Length = CFDataGetLength(data1)
//        let data2Length = CFDataGetLength(data2)
    
    // Combine subscribers.
    private var subscriptions = Set<AnyCancellable>()

    
    var canRecord: Bool {
        get async {
            do {
                // If the app doesn't have Screen Recording permission, this call generates an exception.
                try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
                return true
            } catch {
                return false
            }
        }
    }
    
    func monitorAvailableContent() async {
        guard !isSetup else {  print("!isSetup"); return}
        // Refresh the lists of capturable content.
        await self.refreshAvailableContent()
        Timer.publish(every: 3, on: .main, in: .common).autoconnect().sink { [weak self] _ in
            guard let self = self else { return }
            Task {
                await self.refreshAvailableContent()
            }
        }
        .store(in: &subscriptions)
    }
    
    func getFrame() ->StoreFrame {
//        func getFrame() ->CapturedFrame {
        return currentFrame ?? StoreFrame(currentFrame:CapturedFrame(surface: nil, contentRect: .zero, contentScale: 0, scaleFactor: 0))
    }
    
    func restart() async {
//        실행 중인 start를 끄고, 다시 시작한다
        await stop()
        await start()
    }
    /// Starts capturing screen content.
    func start() async {
//        func start() async -> CapturedFrame? {
//        @State var capturedFrame:CapturedFrame?
        // Exit early if already running.
        print(isRunning)
        guard !isRunning else {print("!isRunning"); return}
        
        if !isSetup {
            // Starting polling for available screen content.
            await monitorAvailableContent()
            isSetup = true
            print(isRunning)
        }
        else {
            print("isSetup:true");
        }
        do {
            let config = streamConfiguration
            let filter = contentFilter
            // Update the running state.
            
            // FIXME: 나중에 이미지를 연속적으로/스트림으로 받게 되면 isRunning이 다시 필요해짐
//            isRunning = true
            // Start the stream and await new video frames.
            for try await frame in captureEngine.startCapture(configuration: config, filter: filter) {
//                capturePreview.updateFrame(frame)
//                contentView.updateFrame(frame )

                if let currentFrame = currentFrame {
                    currentFrame.currentFrame = frame
                }
                if contentSize != frame.size {
                    // Update the content size if it changed.
                    contentSize = frame.size
                }
            }
            

            
            
        } catch {

            logger.error("screenRecorder start error:\(error.localizedDescription)")
            // Unable to start the stream. Set the running state to false.
            isRunning = false
        }
//        return capturedFrame
    }
    func memoryOff() async {
            print("해제")
            currentFrame = nil
            print(currentFrame)

    }
    func memoryOn() async {
            print("재시작")
            currentFrame = StoreFrame(currentFrame:CapturedFrame(surface: nil, contentRect: .zero, contentScale: 0, scaleFactor: 0))
            print(currentFrame)
    }
    func checkCount() {
        if let currentFrame = self.currentFrame {
            let unmanaged = Unmanaged.passRetained(currentFrame)
            let retainCount = CFGetRetainCount(unmanaged.takeUnretainedValue())
            print(retainCount)
        }
        else {
            print("checkCount")
        }


    }
//    func memoryReset() async {
//        let timer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true, block: { timer in
//            if (self.currentFrame != nil) {
//                print("해제")
//                self.currentFrame = nil
//
//            }
//            else {
//                print("재시작")
//                self.currentFrame = StoreFrame(currentFrame:CapturedFrame(surface: nil, contentRect: .zero, contentScale: 0, scaleFactor: 0))
//            }
//            print(self.currentFrame)
//        })
//    }
    
    /// Stops capturing screen content.
    func stop() async {
        guard isRunning else { return }
        await captureEngine.stopCapture()
//        stopAudioMetering()
        isRunning = false
    }
    
    func saveWindowPosition (position:CGRect) {
        self.windowPosition = position
    }
//    private func startAudioMetering() {
//        audioMeterCancellable = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect().sink { [weak self] _ in
//            guard let self = self else { return }
//            self.audioLevelsProvider.audioLevels = self.captureEngine.audioLevels
//        }
//    }
//
//    private func stopAudioMetering() {
//        audioMeterCancellable?.cancel()
//        audioLevelsProvider.audioLevels = AudioLevels.zero
//    }
    
    /// - Tag: UpdateCaptureConfig
    private func updateEngine() {
        guard isRunning else { return }
        Task {
            await captureEngine.update(configuration: originalstreamConfiguration, filter: contentFilter)
//            await captureEngine.update(configuration: streamConfiguration, filter: contentFilter)
        }
    }
    
    /// - Tag: UpdateFilter
    private var contentFilter: SCContentFilter {
        let filter: SCContentFilter
        switch captureType {
        case .display:
            guard let display = selectedDisplay else { fatalError("No display selected.") }
            var excludedApps = [SCRunningApplication]()
            // If a user chooses to exclude the app from the stream,
            // exclude it by matching its bundle identifier.
            if isAppExcluded {
                excludedApps = availableApps.filter { app in
                    Bundle.main.bundleIdentifier == app.bundleIdentifier
                }
            }
            // Create a content filter with excluded apps.
            filter = SCContentFilter(display: display,
                                     excludingApplications: excludedApps,
                                     exceptingWindows: [])
        case .window:
            guard let window = selectedWindow else { fatalError("No window selected.") }
            
            // Create a content filter that includes a single window.
            filter = SCContentFilter(desktopIndependentWindow: window)
        }
        return filter
    }

    
    private var streamConfiguration: SCStreamConfiguration {

        let streamConfig = SCStreamConfiguration()
    
        guard let display = selectedDisplay else { fatalError("No display selected.") }
        streamConfig.sourceRect = CGRect(x: self.windowPosition.minX, y: CGFloat(display.height) - self.windowPosition.maxY, width: self.windowPosition.maxX-self.windowPosition.minX, height: self.windowPosition.maxY-self.windowPosition.minY)
        if captureType == .display, let display = selectedDisplay {
            streamConfig.width = display.width * scaleFactor
            streamConfig.height = display.height * scaleFactor
        }

        // Configure the window content width and height.
        if captureType == .window, let window = selectedWindow {
            streamConfig.width = Int(window.frame.width) * 2
            streamConfig.height = Int(window.frame.height) * 2
        }

        // Set the capture interval at 60 fps.
        streamConfig.minimumFrameInterval = CMTime(value: 1, timescale: 60)

        // Increase the depth of the frame queue to ensure high fps at the expense of increasing
        // the memory footprint of WindowServer.
        streamConfig.queueDepth = 5

        return streamConfig
    }
    
    private var originalstreamConfiguration: SCStreamConfiguration {
        
        let streamConfig = SCStreamConfiguration()

        
        // Configure the display content width and height.
        if captureType == .display, let display = selectedDisplay {
            streamConfig.width = display.width * scaleFactor
            streamConfig.height = display.height * scaleFactor
        }
        
//        // Configure the window content width and height.
//        if captureType == .window, let window = selectedWindow {
//            streamConfig.width = Int(window.frame.width) * 2
//            streamConfig.height = Int(window.frame.height) * 2
//        }
        
        // Set the capture interval at 60 fps.
        streamConfig.minimumFrameInterval = CMTime(value: 1, timescale: 60)
        
        // Increase the depth of the frame queue to ensure high fps at the expense of increasing
        // the memory footprint of WindowServer.
        streamConfig.queueDepth = 5
        
        return streamConfig
    }
    
    
    /// - Tag: GetAvailableContent
    private func refreshAvailableContent() async {
        do {
            // Retrieve the available screen content to capture.
            let availableContent = try await SCShareableContent.excludingDesktopWindows(false,
                                                                                        onScreenWindowsOnly: true)
            availableDisplays = availableContent.displays
            
            let windows = filterWindows(availableContent.windows)
            if windows != availableWindows {
                availableWindows = windows
            }
            availableApps = availableContent.applications
            
            if selectedDisplay == nil {
                selectedDisplay = availableDisplays.first
            }
            if selectedWindow == nil {
                selectedWindow = availableWindows.first
            }
        } catch {
            logger.error("Failed to get the shareable content: \(error.localizedDescription)")
        }
    }
    
    private func filterWindows(_ windows: [SCWindow]) -> [SCWindow] {
        windows
        // Sort the windows by app name.
            .sorted { $0.owningApplication?.applicationName ?? "" < $1.owningApplication?.applicationName ?? "" }
        // Remove windows that don't have an associated .app bundle.
            .filter { $0.owningApplication != nil && $0.owningApplication?.applicationName != "" }
        // Remove this app's window from the list.
            .filter { $0.owningApplication?.bundleIdentifier != Bundle.main.bundleIdentifier }
    }
}

extension SCWindow {
    var displayName: String {
        switch (owningApplication, title) {
        case (.some(let application), .some(let title)):
            return "\(application.applicationName): \(title)"
        case (.none, .some(let title)):
            return title
        case (.some(let application), .none):
            return "\(application.applicationName): \(windowID)"
        default:
            return ""
        }
    }
}

extension SCDisplay {
    var displayName: String {
        "Display: \(width) x \(height)"
    }
}
