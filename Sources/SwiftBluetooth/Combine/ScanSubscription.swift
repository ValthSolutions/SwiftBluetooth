//
//  ScanSubscription.swift
//  SwiftBluetooth
//
//  Created by Dmytro Akulinin on 03.07.2025.
//

import Combine
import CoreBluetooth

final class ScanSubscription<Downstream: Subscriber>: Subscription where Downstream.Input == Peripheral, Downstream.Failure == Error {

    private weak var parent: CentralManager?
    private let services: [CBUUID]?
    private let options: [String: Any]?
    private var downstream: Downstream?
    private var task: Task<Void, Never>?
    private var demand: Subscribers.Demand = .none

    init(parent: CentralManager?, services: [CBUUID]? , options: [String: Any]?, downstream: Downstream) {
        self.parent = parent
        self.services = services
        self.options = options
        self.downstream = downstream

        guard let parent else { return }
        task = Task(priority: .userInitiated) { [weak self] in
            guard let self else { return }
            let stream = await parent.scanForPeripherals(
                withServices: services,
                options: options
            )

            for await peripheral in stream {
                guard !Task.isCancelled else { break }
                guard demand > .none else { continue }

                demand -= 1
                let more = downstream.receive(peripheral)
                demand += more
            }

            downstream.receive(completion: .finished)
            self.cancel()
        }
    }

    // MARK: Subscription

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
