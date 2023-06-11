//
//  NaverTranslater.swift
//  CaptureSample
//
//  Created by sujung Hwang on 2023/05/21.
//  Copyright © 2023 Apple. All rights reserved.
//
struct Private: Decodable {
    let client_id: String
    let client_secret: String
}

let API_CALL_LIMIT_EXCEEDED = 429

import Foundation

@MainActor
class NaverTranslator: ObservableObject {

    let API_URL = "https://openapi.naver.com/v1/papago/n2mt"
    private var privateKeys:[Private] = []
    private var currentPrivateIndex = 0

    @Published var fromLanguageCode: String = "jp"
    @Published var toLanguageCode: String = "ko"
    @Published var languageCodes = [
        "en",
        "ko",
        "ja",
        "zh-CN",
        "zh-TW"
    ]
    
    func setCurrentPrivate (index:Int) {
        self.currentPrivateIndex = index
        
        // Log
        print("<API Privates 변경>")
        print("index:", index)
        let privateKey = privateKeys[index]
        print("client_id:", privateKey.client_id)
        print("client_secret:", privateKey.client_secret)

    }
    
    func setPrivateKeys (keys:[Private]) {
        self.privateKeys = keys
    }
    func getKeysFromFile() {
        
        let fileManager = FileManager.default
        let desktopURL = fileManager.urls(for: .downloadsDirectory, in: .userDomainMask).first!
        let fileURL = desktopURL.appendingPathComponent("privates.txt")

        if fileManager.isReadableFile(atPath: fileURL.path) {
            do {
                let fileContents = try String(contentsOf: fileURL, encoding: .utf8)
                if let jsonData = fileContents.data(using: .utf8) {
                    do {
                        let privates = try JSONDecoder().decode([Private].self, from: jsonData)
                        print(privates)
                        setPrivateKeys(keys:privates)
                        
                    } catch {
                        print("JSON 파싱 오류: \(error)")
                    }
                }
                
            } catch {
                print("파일을 읽을 수 없습니다: \(error)")
            }
        } else {
            print("파일 접근이 거부되었습니다.")
        }
        
    }
  
    
    func translateText(original_texts:String, completion: @escaping (String?) -> Void) {
        let apiUrl = URL(string: API_URL)!
        let query = original_texts
        let currentPrivate = privateKeys[currentPrivateIndex]
        let clientId = currentPrivate.client_id
        let clientSecret = currentPrivate.client_secret

        
        
        var request = URLRequest(url: apiUrl)
        request.httpMethod = "POST"
        request.addValue(clientId, forHTTPHeaderField: "X-Naver-Client-Id")
        request.addValue(clientSecret, forHTTPHeaderField: "X-Naver-Client-Secret")
        request.addValue("application/x-www-form-urlencoded; charset=UTF-8", forHTTPHeaderField: "Content-Type")
        

//            request.httpBody = try JSONSerialization.data(withJSONObject: params, options: [])
            let bodyString = "source=\(fromLanguageCode)&target=\(toLanguageCode)&text=\(query)"
            request.httpBody = bodyString.data(using: .utf8)
            
            print(request)
            let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
                if let error = error {
                    print("Error: \(error)")
                    return
                }
                
                if let httpURLResponse = response as? HTTPURLResponse {
                    let statusCode = httpURLResponse.statusCode
                    // statusCode를 사용하여 원하는 작업을 수행할 수 있습니다.
                    if (statusCode == API_CALL_LIMIT_EXCEEDED) {
                        print(httpURLResponse)
                        print("오픈 API를 호출 하루 허용량 초과!")
                        if (self.currentPrivateIndex != self.privateKeys.count - 1) {
                            self.setCurrentPrivate(index: self.currentPrivateIndex+1)
                        }
                        else {
                            print("오픈 API 한도를 모두 소진했습니다")
                        }
                        
                    }
                }
                
                
                if let data = data {
                    if let JSONData = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                        // JSON 데이터에서 번역된 텍스트 추출
                        if let message = JSONData["message"] as? [String: Any],
                           let result = message["result"] as? [String: Any],
                           let translated = result["translatedText"] as? String {
                            print("message: ", message as Any)
                            print("result: ", result as Any)
                            print("번역 결과: \(translated)")
                            completion(translated)
                        }
                        else {
                            completion(nil)
                        }
                    }
                }
                
            }
        
            task.resume()
    }
}
