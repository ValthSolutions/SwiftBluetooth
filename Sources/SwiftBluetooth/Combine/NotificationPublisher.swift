//
//  NotificationPublisher.swift
//  SwiftBluetooth
//
//  Created by Dmytro Akulinin on 03.07.2025.
//

import Combine
import CoreBluetooth

// MARK: – NotificationPublisher  (Peripheral ➜ Data)

struct NotificationPublisher: Publisher {
    typealias Output = Data
    typealias Failure = Error

    weak var parent: Peripheral?
    let characteristic: Characteristic

    func receive<S: Subscriber>(subscriber: S)
    where S.Input == Output, S.Failure == Failure {

        let subscription = AsyncStreamSubscription(
            parent: parent,
            factory: { parent in
                parent.readValues(for: characteristic)     
            },
            downstream: subscriber
        )
        subscriber.receive(subscription: subscription)
    }
}
