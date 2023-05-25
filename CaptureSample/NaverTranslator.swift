//
//  NaverTranslater.swift
//  CaptureSample
//
//  Created by sujung Hwang on 2023/05/21.
//  Copyright © 2023 Apple. All rights reserved.
//

import Foundation

@MainActor
class NaverTranslator: ObservableObject {
    
    let CLIENT_ID = "v01qO4j91BMIvA1t6Lwf"
    let CLIENT_SECRET = "ALkMAS_jpY"
    let API_URL = "https://openapi.naver.com/v1/papago/n2mt"
    
    @Published var fromLanguageCode: String = "en"
    @Published var toLanguageCode: String = "ko"
    @Published var languageCodes = [
        "en",
        "ko",
        "ja",
        "zh-CN",
        "zh-TW"
    ]
    
    func translateText(original_texts:String, completion: @escaping (String?) -> Void) {
        let apiUrl = URL(string: API_URL)!
        let query = original_texts
        let clientId = CLIENT_ID
        let clientSecret = CLIENT_SECRET

        
        var request = URLRequest(url: apiUrl)
        request.httpMethod = "POST"
        request.addValue(clientId, forHTTPHeaderField: "X-Naver-Client-Id")
        request.addValue(clientSecret, forHTTPHeaderField: "X-Naver-Client-Secret")
        request.addValue("application/x-www-form-urlencoded; charset=UTF-8", forHTTPHeaderField: "Content-Type")
        

//            request.httpBody = try JSONSerialization.data(withJSONObject: params, options: [])
            let bodyString = "source=\(fromLanguageCode)&target=\(toLanguageCode)&text=\(query)"
            request.httpBody = bodyString.data(using: .utf8)
            

            let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
                if let error = error {
                    print("Error: \(error)")
                    return
                }
                print("response: ", response as Any)

                if let data = data {
                    if let JSONData = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                        // JSON 데이터에서 번역된 텍스트 추출
                        if let message = JSONData["message"] as? [String: Any],
                           let result = message["result"] as? [String: Any],
                           let translated = result["translatedText"] as? String {
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
