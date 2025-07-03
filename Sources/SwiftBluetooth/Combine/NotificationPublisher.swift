//
//  NotificationPublisher.swift
//  SwiftBluetooth
//
//  Created by Dmytro Akulinin on 03.07.2025.
//

import Combine
import CoreBluetooth

struct NotificationPublisher: Publisher {
    typealias Output = Data
    typealias Failure = Error

    weak var parent: Peripheral?
    let characteristic: Characteristic

    func receive<S>(subscriber: S) where S : Subscriber, Failure == S.Failure, Output == S.Input {
        let subscription = NotificationSubscription(parent: parent,
                                                    characteristic: characteristic,
                                                    downstream: subscriber)
        subscriber.receive(subscription: subscription)
    }
}
