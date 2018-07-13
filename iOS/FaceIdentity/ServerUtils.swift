//
//  ServerUtils.swift
//  FaceIdentity
//
//  Created by Pujun Lun on 7/12/18.
//  Copyright © 2018 Pujun Lun. All rights reserved.
//

import UIKit

class ServerUtils: NSObject {
    
    static let kServerAddress = "http://10.202.0.179:8100"
    
    public static func sendData(_ data: Data,
                                headerFields: [String : String]?,
                                responseHandler: @escaping (Data?) -> Void) {
        func didFail(reason: String) {
            responseHandler(nil)
        }
        
        // setup request
        var request = URLRequest(url: URL(string: ServerUtils.kServerAddress)!,
                                 cachePolicy: .reloadIgnoringCacheData,
                                 timeoutInterval: 10.0)
        
        func setHeaderFields(_ headerFields: [String : String]?, for request: inout URLRequest) {
            let _ = headerFields?.map { request.setValue($1, forHTTPHeaderField: $0) }
        }
        
        request.httpMethod = "POST"
        setHeaderFields(headerFields, for: &request)
        
        // start task
        let task = URLSession(configuration: .default).uploadTask(with: request, from: data) {
            (returnedData, response, error) in
            guard error == nil else {
                didFail(reason: error!.localizedDescription)
                return
            }
            let httpResponse = response as! HTTPURLResponse
            guard httpResponse.statusCode == 200 else {
                didFail(reason: "Code \(httpResponse.statusCode)")
                return
            }
            responseHandler(returnedData)
        }
        task.resume()
    }
    
}
