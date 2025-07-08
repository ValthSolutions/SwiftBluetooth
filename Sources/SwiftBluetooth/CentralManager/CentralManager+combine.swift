//
//  File.swift
//  SwiftBluetooth
//
//  Created by Dmytro Akulinin on 03.07.2025.
//

import Foundation
import CoreBluetooth
import Combine

// MARK: – Combine helpers

public extension CentralManager {
    func bridgeToPublisher<T>(
        work: @escaping (CentralManager,
                         @escaping (Result<T, Error>) -> Void) -> Void
    ) -> AnyPublisher<T, Error> {

        Deferred {
            Future { [weak self] promise in
                guard let self = self else {
                    promise(.failure(CentralError.deallocated))
                    return
                }
                work(self, promise)
            }
        }
        .subscribe(on: eventQueue)
        .eraseToAnyPublisher()
    }

    // MARK: waitUntilReady
    func waitUntilReadyPublisher() -> AnyPublisher<Void, Error> {
        bridgeToPublisher { central, completion in
            central.waitUntilReady(completionHandler: completion)
        }
    }

    // MARK: connect
    func connectPublisher(_ peripheral: Peripheral, timeout: TimeInterval,
                          options: [String: Any]? = nil) -> AnyPublisher<Peripheral, Error> {
        bridgeToPublisher { central, completion in
            central.connect(peripheral,
                            timeout: timeout,
                            options: options,
                            completionHandler: completion)
        }
    }

    // MARK: scanForPeripherals
    func scanForPeripheralsPublisher(withServices services: [CBUUID]? = nil,
                                     timeout: TimeInterval? = nil,
                                     options: [String: Any]? = nil) -> AnyPublisher<Peripheral, Error> {
        ScanPublisher(parent: self, services: services, options: options)
            .eraseToAnyPublisher()
    }

    // MARK: cancelPeripheralConnection
    func cancelPeripheralConnectionPublisher(_ peripheral: Peripheral) -> AnyPublisher<Void, Error> {
        bridgeToPublisher { central, completion in
            central.cancelPeripheralConnection(peripheral,
                                               completionHandler: completion)
        }
    }
}
