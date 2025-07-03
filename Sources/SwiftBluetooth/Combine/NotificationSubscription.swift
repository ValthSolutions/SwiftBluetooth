//
//  NotificationSubscription.swift
//  SwiftBluetooth
//
//  Created by Dmytro Akulinin on 03.07.2025.
//

import Combine
import CoreBluetooth

final class NotificationSubscription<Downstream: Subscriber>: Subscription where Downstream.Input == Data, Downstream.Failure == Error {

    // MARK: Stored properties

    private weak var parent: Peripheral?
    private let characteristic: Characteristic
    private var downstream: Downstream?
    private var demand: Subscribers.Demand = .none
    private var task: Task<Void, Never>?

    // MARK: Init
    init(parent: Peripheral?, characteristic: Characteristic, downstream: Downstream) {
        self.parent = parent
        self.characteristic = characteristic
        self.downstream = downstream

        guard let parent else { return }

        // Launch asynchronous bridge from AsyncStream → Combine.
        task = Task(priority: .userInitiated) { [weak self] in
            guard let self else { return }

            for await value in parent.readValues(for: characteristic) {
                guard !Task.isCancelled else { break }
                guard demand > .none else { continue }

                demand -= 1
                let more = downstream.receive(value)
                demand += more
            }

            downstream.receive(completion: .finished)
            self.cancel()
        }
    }

    // MARK: Subscription protocol

    func request(_ newDemand: Subscribers.Demand) {
        demand += newDemand
    }

    func cancel() {
        task?.cancel()
        task = nil
        downstream = nil
        parent = nil
    }
}
