//
//  Syncable.swift
//  Pods
//
//  Created by Mitch Treece on 6/10/16.
//  Broadcast
//

import Foundation

internal var SyncObserverAssociationToken: UInt8 = 0

public typealias SyncBlock = (Syncable) -> ()

internal class SyncBlockContainer: NSObject {
    
    static let key = "SyncBlockContainer.key"
    var block: SyncBlock
    
    init(block: SyncBlock) {
        self.block = block
    }
    
}

/**
 The `Syncable` protocol defines an object who can notify other instances of itself when property changes occur.
 Objects wishing to conform to `Syncable` simply need to supply a `syncId`, and call `makeSyncable()` upon initialization.
 */
public protocol Syncable: class {
    
    var syncId: String { get }
    
}

public extension Syncable {
    
    func makeSyncable() {
        
        let observer = SyncObserver(name: notificationName(), object: nil) { [weak self] (notification) in
            
            guard let localSelf = self, info = notification.userInfo, container = info[SyncBlockContainer.key] as? SyncBlockContainer else { return }
            
            container.block(localSelf)
            
            // Broadcast the update to reactables
            if let reactable = localSelf as? Reactable {
                reactable.broadcast()
            }
            
        }
        
        objc_setAssociatedObject(self, &SyncObserverAssociationToken, observer, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        
    }
    
    func sync(block: SyncBlock) {
        let container = SyncBlockContainer(block: block)
        let info: [String: AnyObject] = [SyncBlockContainer.key: container]
        NSNotificationCenter.defaultCenter().postNotificationName(notificationName(), object: nil, userInfo: info)
    }
    
    internal func notificationName() -> String {
        return NSStringFromClass(self.dynamicType) + "_" + syncId + ".sync"
    }
    
}

public extension Syncable where Self: Reactable {
    
    var reactId: String {
        return syncId
    }
    
}