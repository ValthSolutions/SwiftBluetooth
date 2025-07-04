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
    // MARK: waitUntilReady
    func waitUntilReadyPublisher() -> AnyPublisher<Void, Error> {
        Deferred {
            Future { [weak self] promise in
                guard let self else {
                    promise(.failure(CentralError.unknown)); return
                }
                self.waitUntilReady { result in
                    promise(result)
                }
            }
        }
        .subscribe(on: eventQueue)
        .eraseToAnyPublisher()
    }

    // MARK: connect
    func connectPublisher(_ peripheral: Peripheral, timeout: TimeInterval,
                          options: [String: Any]? = nil) -> AnyPublisher<Peripheral, Error> {
        Deferred {
            Future { [weak self] promise in
                guard let self else {
                    promise(.failure(CentralError.unknown)); return
                }
                self.connect(peripheral, timeout: timeout, options: options, completionHandler: { result in
                    promise(result)
                })
            }
        }
        .subscribe(on: eventQueue)
        .eraseToAnyPublisher()
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
        Deferred {
            Future { [weak self] promise in
                guard let self else {
                    promise(.failure(CentralError.unknown)); return
                }
                self.cancelPeripheralConnection(peripheral, completionHandler: { result in
                    promise(result)
                })
            }
        }
        .subscribe(on: eventQueue)
        .eraseToAnyPublisher()
    }
}
