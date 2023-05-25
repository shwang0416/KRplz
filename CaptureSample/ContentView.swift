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
import Differ

struct ContentView: View {
//    @State var capturedFrame = CapturedFrame(surface: nil, contentRect: .zero, contentScale: 0, scaleFactor: 0)
    @State var prevImage:CGImage?
    @State var windowPosition  = CGRect(x:0,y:0,width:0,height:0)
    @State var userStopped = false
    @State var disableInput = false
    @State var isUnauthorized = false
    @State private var recognizedTexts = [String]()
    @State private var prevRecognizedTextString = ""
    @State private var recognizedTextString = ""
    @State private var translatedText = ""
//    @State private var isTextUpdated = false
//    @State private var isLoading = true
    @ObservedObject var screenRecorder = ScreenRecorder()
    @StateObject var translator = NaverTranslator()
    @State var showConfigMenu = false
    @State var showTranslatedView = false
    @State var shouldStopTimer = true
    
    func recognizeText () {
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
                    
    //               여기서 prevRecogizedText 와 recogizedText diff로 비교해서 얼마나 다른지 보기
                    recognizedTextString = recognizedTexts.reduce("", { $0.isEmpty ? $1 : $0 + " " + $1 })
                    let diff = prevRecognizedTextString.diff(recognizedTextString)
                    print("---------------------------")
                    print("prev",prevRecognizedTextString)
                    print("cur",recognizedTextString)
                    print("diff: ",diff.count)
                    if (diff.count > 3 && showTranslatedView) {
                        print("텍스트가 바뀜")
                        translateTexts()
                    }
                    print("---------------------------")
                    prevRecognizedTextString = recognizedTextString
                    
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
    

    func translateTexts () {
        translator.translateText(original_texts:recognizedTextString) { translatedText in
            if let translated = translatedText {
                self.translatedText = translated
            } else {
                print("translator.translateText 오류")
            }
            
        }
        self.showTranslatedView = true
    }

    
    func addObserver () {
        NotificationCenter.default.addObserver(
            forName: NSWindow.didMoveNotification, object: nil, queue: nil) { (notification) in
                if let window = notification.object as? NSWindow
                {
                    self.windowPosition = window.frame
                    screenRecorder.saveWindowPosition(position: windowPosition)
                    print("addObserver: ",window.frame.minY, window.frame.midY, window.frame.maxY)
                }
            }
    }

    @Environment(\.openURL) var openURL
    var body: some View {

        VStack(alignment: .leading) {
            HSplitView {
                if (showConfigMenu) {
                    ConfigurationView(screenRecorder: screenRecorder, translator: translator, userStopped: $userStopped)
                        .frame(minWidth: 0, maxWidth: 280)
                        .disabled(disableInput)
                }
                VStack {
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
                    HStack {
                        Text("번역")
                        Button {
                            Task {
                                translateTexts()
                                
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

                    Button {
                        Task {
                            showConfigMenu = !showConfigMenu
                        }
                    } label: {
                        Text("Toggle Window Config")
                    }

//                    .padding()

                    

//                    HStack{
//                        Text("메모리")
//                        Button {
//                            Task {
//                                await screenRecorder.memoryOff()
//                            }
//                            // Fades the paused screen out.
//                            withAnimation(Animation.easeOut(duration: 0.25)) {
//                                userStopped = false
//                            }
//                        } label: {
//                            Text("해제")
//                        }
//                        Button {
//                            Task {
//                                await screenRecorder.memoryOn()
//                            }
//                            // Fades the paused screen out.
//                            withAnimation(Animation.easeOut(duration: 0.25)) {
//                                userStopped = false
//                            }
//                        } label: {
//                            Text("재시작")
//                        }
//                        Button {
//                            Task {
//                                screenRecorder.checkCount()
//                            }
//                            // Fades the paused screen out.
//                            withAnimation(Animation.easeOut(duration: 0.25)) {
//                                userStopped = false
//                            }
//                        } label: {
//                            Text("참조체크")
//                        }
//                    }
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
//                           번역 뷰
                            PlainTextView(text: self.translatedText)
                        } else {
//                           원문 뷰
                            PlainTextView(text: recognizedTextString)
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
