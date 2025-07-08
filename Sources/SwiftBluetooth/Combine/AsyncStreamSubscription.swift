//
//  AsyncStreamSubscription.swift
//  SwiftBluetooth
//
//  Created by Dmytro Akulinin on 08.07.2025.
//

import Combine

final class AsyncStreamSubscription<Parent: AnyObject, Input, Downstream: Subscriber>: Subscription where Downstream.Input == Input, Downstream.Failure == Error {
    typealias StreamFactory = @Sendable (Parent) async -> AsyncStream<Input>

    private weak var parent: Parent?
    private var downstream: Downstream?
    private var demand: Subscribers.Demand = .none
    private var task: Task<Void, Never>?

    init(parent: Parent?,
         factory: @escaping StreamFactory,
         downstream: Downstream) {
        self.parent = parent
        self.downstream = downstream

        guard let parent else { return }

        task = Task(priority: .userInitiated) { [weak self] in
            guard let self else { return }

            let stream = await factory(parent)

            for await value in stream {
                guard !Task.isCancelled else { break }
                guard demand > .none else { continue }

                demand -= 1
                demand += downstream.receive(value)
            }

            downstream.receive(completion: .finished)
            cancel()
        }
    }

    // MARK: - Subscription
    func request(_ newDemand: Subscribers.Demand) { demand += newDemand }
    func cancel() {
        task?.cancel()
        task = nil
        downstream = nil
        parent = nil
    }
}
