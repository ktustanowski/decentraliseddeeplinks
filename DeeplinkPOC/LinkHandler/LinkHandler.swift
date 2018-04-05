//
//  LinkHandler.swift
//  LinkHandler
//
//  Created by Kamil Tustanowski on 05.04.2018.
//  Copyright © 2018 ktustanowski. All rights reserved.
//

import Foundation
import ReactiveSwift
import Result

public struct LinkHandler {

    public static func handle(_ userActivity: NSUserActivity) {
        let linkProducer = LinkFactory.make(with: userActivity)
        startLinkFlow(with: linkProducer)
    }
    
    public static func handle(_ url: URL) {
        let linkProducer = LinkFactory.make(with: url)
        startLinkFlow(with: linkProducer)
    }
    
    public static func handle(_ info: [String: String]) {
        let linkProducer = LinkFactory.make(with: info)
        startLinkFlow(with: linkProducer)
    }

    private static func startLinkFlow(with linkProducer: SignalProducer<Link?, NoError>) {
        let linkOnlyProducer = linkProducer
            .skipNil()
            .take(first: 1)
            .logEvents(identifier: "LPP")

        var linkFlowProducer = linkOnlyProducer.flatMap(.latest) { link in
            // Any other operation that needs to be done before linking flow
            // commences can be added to the zip
            SignalProducer.zip(ConfigurationProvider.load(), //load some config file
                               SingleSignOn.login(using: link), //try to login using SSO flow
                               SignalProducer.init(value: link)) // just pass the link
            }.startWithResult { result in
                switch result {
                case .success(let (isConfigLoaded, ssoLoginStatus, link)):
                    print("Start linking now!")
                    print("GOT: config loaded: \(isConfigLoaded), sso authenticated: \(ssoLoginStatus), link: \(link)")
                //TODO: Handle appropriately
                case .failure(let error):
                    print("GOT: \(error)")
                }
                //TODO: start navigation here based on outcome
        }
    }
}

/// Some pre-linking-needed config loading
struct ConfigurationProvider {
    static func load() -> SignalProducer<Bool, NoError> {
        return SignalProducer {observer, _ in
            dispatchAfter(1.0) {
                // Pretend we load anything here
                observer.send(value: true)
                observer.sendCompleted()
            }
            }.logEvents(identifier: "CP")
    }
}

//let linkParserProducer = LinkFactory.make(with: URL(string: "http://www.o2.pl?sso=go")!)
//    .skipNil()
//    .take(first: 1)
//    .logEvents(identifier: "LPP")

//let homeDataProducer = SignalProducer<Bool, NoError> {observer, _ in
//    dispatchAfter(1.0) {
//        observer.send(value: true)
//        observer.sendCompleted()
//    }
//}//.logEvents(identifier: "HP")
//
//let newRequirementProducer = SignalProducer<Bool, NoError> {observer, _ in
//    dispatchAfter(3.0) {
//        observer.send(value: false)
//        observer.sendCompleted()
//    }
//}//.logEvents(identifier: "NEW")
//
//let newestRequirementProducer = SignalProducer<Bool, NoError> {observer, _ in
//    dispatchAfter(3.5) {
//        observer.send(value: false)
//        observer.sendCompleted()
//    }
//}//.logEvents(identifier: "NEWEST")
//
//let x = linkParserProducer.flatMap(.latest) { link in
//    SignalProducer.zip(homeDataProducer,
//                       SingleSignOn.login(using: link),
//                       newRequirementProducer,
//                       newestRequirementProducer,
//                       SignalProducer.init(value: link))
//    }.startWithResult { result in
//        switch result {
//        case .success(let (isHomeLoaded, ssoLoginStatus, newFeature, newestFeature, link)):
//            print("GOT: home loaded: \(isHomeLoaded), sso authenticated: \(ssoLoginStatus), new requirement: \(newFeature), newest requirement: \(newestFeature) link: \(link)")
//        //TODO: Handle appropriately
//        case .failure(let error):
//            print("GOT: \(error)")
//        }
//        //TODO: start navigation here based on outcome
//}
//