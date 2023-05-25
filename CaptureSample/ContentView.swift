/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The app's main view.
*/

import SwiftUI
import ScreenCaptureKit
import OSLog
import Combine
import Vision
import VisionKit
//import Differ

struct ContentView: View {
//    @State var capturedFrame = CapturedFrame(surface: nil, contentRect: .zero, contentScale: 0, scaleFactor: 0)
    @State var prevImage:CGImage?
    @State var windowPosition  = CGRect(x:0,y:0,width:0,height:0)
    @State var userStopped = false
    @State var disableInput = false
    @State var isUnauthorized = false
    @State private var recognizedTexts = [String]()
    @State private var prevRecognizedTexts = [String]()
    @State private var translatedText = ""
    @State private var recognizedTextString = ""
//    @State private var isLoading = true
    @ObservedObject var screenRecorder = ScreenRecorder()
    @StateObject var translator = NaverTranslator()
    @State var showConfigMenu = false
    @State var showTranslatedView = false
    @State var shouldStopTimer = true
//    private let currentIOSurface:IOSurface? = nil
//    var capturedFrame = CapturedFrame(surface: nil, contentRect: .zero, contentScale: 0, scaleFactor: 0)
    
//    func updateFrame(_ frame: CapturedFrame) {
//        print(frame)
//        capturedFrame = frame
//        print(capturedFrame)
//    }
    
    func pixelValues(fromCGImage imageRef: CGImage?) -> [UInt8]?
       {
           var width = 0
           var height = 0
           var pixelValues: [UInt8]?
        
           if let imageRef = imageRef {
               width = imageRef.width
               height = imageRef.height
               let bitsPerComponent = imageRef.bitsPerComponent
               let bytesPerRow = imageRef.bytesPerRow
               let totalBytes = height * bytesPerRow
               let bitmapInfo = imageRef.bitmapInfo
        
               let colorSpace = CGColorSpaceCreateDeviceRGB()
               var intensities = [UInt8](repeating: 0, count: totalBytes)
        
               let contextRef = CGContext(data: &intensities,
                                         width: width,
                                        height: height,
                              bitsPerComponent: bitsPerComponent,
                                   bytesPerRow: bytesPerRow,
                                         space: colorSpace,
                                    bitmapInfo: bitmapInfo.rawValue)
               contextRef?.draw(imageRef, in: CGRect(x: 0.0, y: 0.0, width: CGFloat(width), height: CGFloat(height)))
        
               pixelValues = intensities
           }
        
           return pixelValues
       }
    
    func handleRecognizeText() async {
        await recognizeText()
    }
    
    func recognizeText () {
//        guard let currentFrame = screenRecorder.currentFrame else {print("currentFrame X"); return}
//        guard let surface = capturedFrame.surface else {print("surface X"); return}
//        print(capturedFrame)
        if let currentFrame = screenRecorder.currentFrame {
            if let capturedFrame = currentFrame.currentFrame {
                // capturedFrame을 사용하여 원하는 동작 수행
                guard let surface = capturedFrame.surface else {print("surface X"); return}
                
                
                let ciImage = CIImage.init(ioSurface: surface as IOSurface)
                
                //        let prevImage = NSImage(ioSurface: ioSurface)
                //        let curImage = NSImage(ioSurface: surface as IOSurface)
                //
                //        prevImage = ciImage
                
                let ciContext = CIContext(options: nil)
                guard let cgImage = ciContext.createCGImage(ciImage, from: ciImage.extent) else {
                    print("cgImage가 CGImage 타입이 아니다")
                    return
                }
                
                let requestHandler = VNImageRequestHandler(cgImage: cgImage)
                
                let recognizeTextRequest = VNRecognizeTextRequest {(request, error) in
                    guard let observations = request.results as? [VNRecognizedTextObservation] else {return}
                    
                    self.recognizedTexts = []
                    for observation in observations {
                        let recogizedText = observation.topCandidates(1).first!.string
                        self.recognizedTexts.append(recogizedText)
                        
                    }
                    
                }
                
                DispatchQueue.global(qos: .userInitiated).async {
                    do {
                        try requestHandler.perform([recognizeTextRequest])
                        //                self.isLoading = false
                    }
                    catch {
                        print("DispatchQueue.global")
                        print(error)
                    }
                }
//               여기서 prevRecogizedText 와 recogizedText diff로 비교해서 얼마나 다른지 보기
//                let diff = prevRecognizedTexts.diff(recognizedTexts)
//                print("diff:",diff)
//                prevRecognizedTexts = recognizedTexts
//                let diff = difference(self.prevRecognizedTexts, self.recognizedTexts)
                
                
                if #available(iOS 16.0, *) {
                    let revision3 = VNRecognizeTextRequestRevision3
                    recognizeTextRequest.revision = revision3
                    recognizeTextRequest.recognitionLevel = .accurate
                    recognizeTextRequest.recognitionLanguages =  ["ja-JP"]
                    recognizeTextRequest.usesLanguageCorrection = true
                    //            do {
                    //                var possibleLanguages: Array<String> = []
                    //                possibleLanguages = try recognizeTextRequest.supportedRecognitionLanguages()
                    //                print(possibleLanguages)
                    //            } catch {
                    //                print("Error getting the supported languages.")
                    //            }
                } else {
                    recognizeTextRequest.recognitionLanguages =  ["en-US"]
                    recognizeTextRequest.usesLanguageCorrection = true
                }
            }
        }
    }
    

    
    

    
    func addObserver () {
        NotificationCenter.default.addObserver(
            forName: NSWindow.didMoveNotification, object: nil, queue: nil) { (notification) in
                if let window = notification.object as? NSWindow
//                   type(of: window).description() == "SwiftUI.SwiftUIWindow"
                {
//                    window.titlebarAppearsTransparent = true
//                    window.isOpaque = false
//                    window.backgroundColor = NSColor.clear
                    
                    
                    self.windowPosition = window.frame
                    screenRecorder.saveWindowPosition(position: windowPosition)
//                    let y = window.frame.minY
                    print("addObserver: ",window.frame.minY, window.frame.midY, window.frame.maxY)
//                    print(window.frame)
                }
            }
    }

    @Environment(\.openURL) var openURL
    var body: some View {

        VStack(alignment: .leading) {
            HSplitView {
                if (showConfigMenu) {
                    ConfigurationView(screenRecorder: screenRecorder, userStopped: $userStopped)
                        .frame(minWidth: 0, maxWidth: 280)
                        .disabled(disableInput)
                }
                
                VStack {
                    //                    Button {
                    //                        Task { self.recognizeText() }
                    //                    } label: {
                    //                        Text("Get Texts")
                    //                    }
                    //                Button {
                    //                    Task {
                    //                        guard let url = URL(string:"trans://detail") else {return}
                    //                        openURL(url)
                    //
                    //                    }
                    //                } label: {
                    //                    Text("Open trans-area")
                    //                }
                    //                    Button {
                    //                        Task {
                    //                            showConfigMenu = !showConfigMenu
                    //
                    //                        }
                    //                    } label: {
                    //                        Text("Toggle Window Config")
                    //                    }
                    //                    Button {
                    //                        Task {
                    //                            addObserver()
                    //                        }
                    //                    } label: {
                    //                        Text("addObserver")
                    //                    }
                    //                HStack {
                    
                    
                    HStack {
                        Text("번역")
                        Button {
                            Task {
                                
                                let joinedString = self.recognizedTexts.reduce("", { $0.isEmpty ? $1 : $0 + " " + $1 })
                                
                                translator.translateText(original_texts:joinedString) { translatedText in
                                    if let translated = translatedText {
                                        self.translatedText = translated
                                        print("번역 성공")
                                    } else {
                                        print("번역 실패?")
                                    }
                                    
                                }
                                print(self.translatedText)
                                self.showTranslatedView = true
                                print("translate")
                                
                            }
                            // Fades the paused screen out.
                            withAnimation(Animation.easeOut(duration: 0.25)) {
                                userStopped = false
                            }
                        } label: {
                            Text("on")
                        }
                        Button {
                            Task {
                                self.showTranslatedView = false
                                
                            }
                            // Fades the paused screen out.
                            withAnimation(Animation.easeOut(duration: 0.25)) {
                                userStopped = false
                            }
                        } label: {
                            Text("off")
                        }
                    }
//                    .padding()
                    HStack {
                        Button {
                            Task {
    //                          **이미 실행 중일 경우 껐다가 다시 켬**
                                await screenRecorder.restart()
                                print("screenRecorder.restart")
                                
                            }
                            // Fades the paused screen out.
                            withAnimation(Animation.easeOut(duration: 0.25)) {
                                userStopped = false
                            }
                        } label: {
                            Text("번역 범위 지정")
                        }
                        Button {
                            Task {
    //                          **인스턴스 재할당 테스트**
//                                self.screenRecorder = nil
//                                screenRecorder = ScreenRecorder()
                                
                            }
                            // Fades the paused screen out.
                            withAnimation(Animation.easeOut(duration: 0.25)) {
                                userStopped = false
                            }
                        } label: {
                            Text("restart")
                        }
                    }
                    
                    HStack {
                        Text("OCR")
                        Button {
                            Task {
                                self.shouldStopTimer = false
                                let timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { timer in
//                                    capturedFrame = screenRecorder.getFrame()
                                    recognizeText()
                                    if shouldStopTimer {
                                        timer.invalidate() // 타이머 중지
                                    }
                                })
//                                    recognizeText()

                               
                            }
                            // Fades the paused screen out.
                            withAnimation(Animation.easeOut(duration: 0.25)) {
                                userStopped = false
                            }
                        } label: {
                            Text("시작")
                        }
                        Button {
                            Task {
                                self.shouldStopTimer = true
                            }
                            // Fades the paused screen out.
                            withAnimation(Animation.easeOut(duration: 0.25)) {
                                userStopped = false
                            }
                        } label: {
                            Text("종료")
                        }

                    }
                    HStack{
                        Text("메모리")
                        Button {
                            Task {
                                await screenRecorder.memoryOff()
                            }
                            // Fades the paused screen out.
                            withAnimation(Animation.easeOut(duration: 0.25)) {
                                userStopped = false
                            }
                        } label: {
                            Text("해제")
                        }
                        Button {
                            Task {
                                await screenRecorder.memoryOn()
                            }
                            // Fades the paused screen out.
                            withAnimation(Animation.easeOut(duration: 0.25)) {
                                userStopped = false
                            }
                        } label: {
                            Text("재시작")
                        }
                        Button {
                            Task {
                                screenRecorder.checkCount()
                            }
                            // Fades the paused screen out.
                            withAnimation(Animation.easeOut(duration: 0.25)) {
                                userStopped = false
                            }
                        } label: {
                            Text("참조체크")
                        }
                    }
                }.frame(minWidth: 0, maxWidth: 280)
                ScrollView{
                    VStack {
//                        ForEach(self.recognizedTexts.indices, id: \.self) {
//                            index in FieldView(value: Binding<String>(get: {
//                                self.recognizedTexts[index]
//                            }, set: { newValue in
//                                self.recognizedTexts[index] = newValue
//                            })){
//                                self.recognizedTexts.remove(at: index)
//                            }
//                        }
                        if self.showTranslatedView {
                            PlainTextView(text: self.translatedText)
                        } else {
//                            ArrayFieldView(text: self.recognizedTexts.reduce("", { $0.isEmpty ? $1 : $0 + " " + $1 }))
//                            ArrayFieldView(textArray: self.recognizedTexts)
                            PlainTextView(text: self.recognizedTexts.reduce("", { $0.isEmpty ? $1 : $0 + " " + $1 }))
                        }
                    }
                }.frame(maxWidth: .infinity, maxHeight: .infinity)
                
            }
            
            //            .frame(minWidth: NSScreen.main!.frame.size.width * 0.5, maxWidth: NSScreen.main!.frame.size.width)
            //            screenRecorder.capturePreview
            //                .frame(maxWidth: .infinity, maxHeight: .infinity)
            //                .aspectRatio(screenRecorder.contentSize, contentMode: .fit)
            //                .padding(8)
            //                .overlay {
            //                    if userStopped {
            //                        Image(systemName: "nosign")
            //                            .font(.system(size: 250, weight: .bold))
            //                            .foregroundColor(Color(white: 0.3, opacity: 1.0))
            //                            .frame(maxWidth: .infinity, maxHeight: .infinity)
            //                            .background(Color(white: 0.0, opacity: 0.5))
            //                    }
            //                }
            
        }
        .frame(maxWidth: .infinity)
        .overlay {
            if isUnauthorized {
                VStack() {
                    Spacer()
                    VStack {
                        Text("No screen recording permission.")
                            .font(.largeTitle)
                            .padding(.top)
                        Text("Open System Settings and go to Privacy & Security > Screen Recording to grant permission.")
                            .font(.title2)
                            .padding(.bottom)
                    }
                    .frame(maxWidth: .infinity)
                    .background(.red)
                    
                }
            }
        }
//        .navigationTitle("Screen Capture Sample")
        .onAppear {
            Task {
                addObserver()
                if await screenRecorder.canRecord {
//                    await screenRecorder.start()
                } else {
                    isUnauthorized = true
                    disableInput = true
                }
            }
        }
    }
}
struct FieldView: View {
    @Binding var value: String
//    let onDelete: () -> Void
    
    var body: some View {
        //        HStack {
        TextField("item", text: $value)
        //            Button(action: {
        //                onDelete()
        //            }, label: {
        //                Image(systemName: "multiply")
        //            })
        //        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
