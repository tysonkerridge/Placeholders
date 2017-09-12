//
//  Placeholders.swift
//  Placeholders
//
//  Created by Олег on 13.04.17.
//  Copyright © 2017 AnySuggestion. All rights reserved.
//

import Foundation

public struct PlaceholdersOptions : OptionSet {
    
    public var rawValue: Int
    
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
    
    public static var infinite = PlaceholdersOptions(rawValue: 1 << 0)
    public static var shuffle = PlaceholdersOptions(rawValue: 1 << 1)
    
}

final public class Placeholders<Element> {
    
    public var iterator: AnyIterator<Element>
    var timer: Timer?
    var action: (Element) -> () = { _ in }
    
    /// Used to check if the first element should be skipped, for reasons where the first element might already be showing and we should skip it.
    /// Mainly useful for cases where an infinite shuffle is used as any placeholder could be used first and already be showing.
    /// This is used once in the first timer handler if set via the `start(...)` method and then deleted and never set or called again.
    private var shouldSkipFirstElement: ((Element) -> Bool)?

    public init<Iterator : IteratorProtocol>(iterator: Iterator) where Iterator.Element == Element {
        self.iterator = AnyIterator(iterator)
    }
    
    public convenience init(placeholders: [Element], options: PlaceholdersOptions = []) {
        var finalPlaceholders = placeholders
        if options.contains(.shuffle) { finalPlaceholders.shuffle() }
        if options.contains(.infinite) {
            self.init(iterator: finalPlaceholders.makeIterator().infinite())
        } else {
            self.init(iterator: finalPlaceholders.makeIterator())
        }
    }
    
    deinit {
        timer?.invalidate()
    }
    
    /// - Parameter shouldSkipFirstElement: A closure which sends the first placeholder to show, to decide whether it should be shown. Return `true` if the element passed is the same as the element already showing.
    public func start(interval: TimeInterval, fireInitial: Bool, shouldSkipFirstElement: ((Element) -> Bool)? = nil, action: @escaping (Element) -> ()) {
        self.shouldSkipFirstElement = shouldSkipFirstElement
        self.action = action
        let timer = Timer(timeInterval: interval,
                          target: self,
                          selector: #selector(act(timer:)),
                          userInfo: nil,
                          repeats: true)
        RunLoop.current.add(timer, forMode: .defaultRunLoopMode)
        self.timer = timer
        if fireInitial {
            if let firstPlaceholder = iterator.next() {
                actionIfNeeded(firstPlaceholder)
            }
        }
    }
    
    @objc private func act(timer: Timer) {

        // Bail, invalidating the timer, if there's no more placeholders
        guard let nextPlaceholder = iterator.next() else {
            timer.invalidate()
            return
        }

        // Action the placeholder
        actionIfNeeded(nextPlaceholder)

    }
    
    private func actionIfNeeded(_ placeholder: Element) {

        // If there's a check to skip, we need to do it and remove the reference before we can continue
        if let shouldSkipFirstElement = self.shouldSkipFirstElement {
            self.shouldSkipFirstElement = nil

            // Now that we've removed the reference, do the check
            // If we shouldn't skip, we can continue and action the placeholder, otherwise bail to skip it and get the next one instead
            guard !shouldSkipFirstElement(placeholder) else {

                // If there's a timer, use it's action to invalidate now if no more placeholders
                if let timer = self.timer {
                    act(timer: timer)

                    // Otherwise action the next placeholder, if any
                } else if let secondPlaceholder = iterator.next() {
                    actionIfNeeded(secondPlaceholder)
                }
                return
            }

        }

        // No check to skip, or it passed and we didn't need to skip, so action the placeholder
        action(placeholder)

    }

}
