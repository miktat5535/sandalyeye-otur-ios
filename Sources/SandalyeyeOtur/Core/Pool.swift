import Foundation

/// Basit nesne havuzu.
///
/// Oyun dongusu icinde `new`/`alloc` YOK kurali: her karede coin, partikul
/// veya sandalye uretilirse ARC/GC devreye girer ve 60 FPS'te gorunur
/// takilma olur. Bu yuzden tum kisa omurlu nesneler buradan alinir ve
/// buraya iade edilir. (bkz. Pool.kt)
final class Pool<T: AnyObject> {
    private var free: [T]
    private let maxSize: Int
    private let factory: () -> T

    init(initialSize: Int, maxSize: Int = 256, factory: @escaping () -> T) {
        self.maxSize = maxSize
        self.factory = factory
        self.free = (0..<initialSize).map { _ in factory() }
    }

    func obtain() -> T {
        free.isEmpty ? factory() : free.removeLast()
    }

    func recycle(_ item: T) {
        if free.count < maxSize { free.append(item) }
    }

    var availableCount: Int { free.count }
}
