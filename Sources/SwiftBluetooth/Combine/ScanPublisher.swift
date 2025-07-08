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

    func receive<S: Subscriber>(subscriber: S)
    where S.Input == Output, S.Failure == Failure {

        let subscription = AsyncStreamSubscription(
            parent: parent,
            factory: { parent in
                await parent.scanForPeripherals(withServices: services,
                                                options: options)   
            },
            downstream: subscriber
        )
        subscriber.receive(subscription: subscription)
    }
}
