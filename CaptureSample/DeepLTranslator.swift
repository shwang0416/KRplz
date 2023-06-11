//
//  NaverTranslater.swift
//  CaptureSample
//
//  Created by sujung Hwang on 2023/05/21.
//  Copyright © 2023 Apple. All rights reserved.
//

import Foundation
import WebKit


@MainActor
class DeepLTranslator: ObservableObject {

//    let API_URL = "https://api-free.deepl.com/v2/translate"


    private var privateKeys:[Private] = []
    private var currentPrivateIndex = 0

    @Published var fromLanguageCode: String = "en"
    @Published var toLanguageCode: String = "ko"
    @Published var languageCodes = [
        "EN",
        "KO",
        "JA",
        "zh-CN",
        "zh-TW"
    ]
//    let API_URL = "https://www.deepl.com/translator#en/ko/"
    let API_URL = "http://127.0.0.1:1188/translate"
    let testJP = "パラノマサイト FILE23 本所七不思議"
    let testEN = "Integrate the world’s best machine translation technology directly into your own products and platforms."
//text: string
//source_lang: string
//target_lang: string
//
    
    func translateText(original_texts:String, completion: @escaping (String?) -> Void) {
        let apiUrl = URL(string: API_URL)!
        let query = original_texts
//        let currentPrivate = privateKeys[currentPrivateIndex]
//        let clientId = currentPrivate.client_id
//        let clientSecret = currentPrivate.client_secret

        
        
        var request = URLRequest(url: apiUrl)
        request.httpMethod = "POST"
//        request.addValue(clientId, forHTTPHeaderField: "X-Naver-Client-Id")
//        request.addValue(clientSecret, forHTTPHeaderField: "X-Naver-Client-Secret")
        request.addValue("application/x-www-form-urlencoded; charset=UTF-8", forHTTPHeaderField: "Content-Type")
        
            let params = [
                "text": original_texts,
                "source_lang": fromLanguageCode,
                "target_lang": toLanguageCode
            ]
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: params, options: [])
        }
        catch {
            // JSON serialization error handling
            print("Error serializing JSON: \(error)")
        }
//            let bodyString = "text=\(query)&target_lang=\(toLanguageCode)"
//            let bodyString = "\(testEN)"
//            request.httpBody = bodyString.data(using: .utf8)
            
            print(request)
            let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
                if let error = error {
                    print("Error: \(error)")
                    return
                }
                
                if let httpURLResponse = response as? HTTPURLResponse {
                    let statusCode = httpURLResponse.statusCode
                    print(httpURLResponse)
                    print(statusCode)
                    // statusCode를 사용하여 원하는 작업을 수행할 수 있습니다.
//                    if (statusCode == API_CALL_LIMIT_EXCEEDED) {
//                        print(httpURLResponse)
//                        print("오픈 API를 호출 하루 허용량 초과!")
//                        if (self.currentPrivateIndex != self.privateKeys.count - 1) {
//                            self.setCurrentPrivate(index: self.currentPrivateIndex+1)
//                        }
//                        else {
//                            print("오픈 API 한도를 모두 소진했습니다")
//                        }
//
//                    }
                }
                
                
                if let data = data {
                    print("data",data)
                    if let JSONData = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                        // JSON 데이터에서 번역된 텍스트 추출
                        print("JSONData",JSONData)
                        if let translated = JSONData["data"] as? String {
                            print("번역 결과: \(translated)")
                            completion(translated)
                        }
                        else {
                            print("DeepLTranslator: has no translated")
                            completion(nil)
                        }
                    }
                    else {
                        print("DeepLTranslator: has no JSONData")
                    }
                }
                else {
                    print("DeepLTranslator: has no data")
                }
                
            }
        
            task.resume()
    }
}
