//
//  ScanPublisher.swift
//  SwiftBluetooth
//
//  Created by Dmytro Akulinin on 03.07.2025.
//

import Combine
import CoreBluetooth

struct ScanPublisher: Publisher {
    typealias Output = Peripheral
    typealias Failure = Error

    weak var parent: CentralManager?
    let services: [CBUUID]?
    let options: [String: Any]?

    func receive<S>(subscriber: S) where S : Subscriber, Failure == S.Failure, Output == S.Input {
        let subscription = ScanSubscription(parent: parent,
                                            services: services,
                                            options: options,
                                            downstream: subscriber)
        subscriber.receive(subscription: subscription)
    }
}
