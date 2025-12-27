import SwiftUI
import UIKit

/// Renders characters using a CP437 tileset image
class TilesetRenderer {
    static let shared = TilesetRenderer()
    
    private var tilesetImage: UIImage?
    private var tileCache: [TileCacheKey: UIImage] = [:]
    
    // CP437 tileset is 16x16 characters, each tile is 16x16 pixels in the source
    let tilesPerRow = 16
    let tilesPerCol = 16
    let sourceTileWidth = 16
    let sourceTileHeight = 16
    
    private init() {
        loadTileset()
    }
    
    private func loadTileset() {
        // Try to load from bundle
        if let path = Bundle.main.path(forResource: "curses_800x600", ofType: "png"),
           let image = UIImage(contentsOfFile: path) {
            tilesetImage = image
            print("✅ Loaded tileset: \(image.size)")
        } else if let path = Bundle.main.path(forResource: "tileset", ofType: "png"),
                  let image = UIImage(contentsOfFile: path) {
            tilesetImage = image
            print("✅ Loaded tileset: \(image.size)")
        } else {
            print("⚠️ Tileset not found, will use system font fallback")
        }
    }
    
    /// Get the tile index for a character (CP437 encoding)
    func tileIndex(for char: Character) -> Int {
        let scalar = char.unicodeScalars.first?.value ?? 0
        // CP437 maps ASCII 0-255
        return Int(min(scalar, 255))
    }
    
    /// Extract a tile from the tileset as a CGImage
    func getTile(index: Int, color: UIColor, scale: CGFloat = 2.0) -> UIImage? {
        let cacheKey = TileCacheKey(index: index, color: color, scale: scale)
        if let cached = tileCache[cacheKey] {
            return cached
        }
        
        guard let tileset = tilesetImage, let cgImage = tileset.cgImage else {
            return nil
        }
        
        // Calculate tile position in the tileset
        let row = index / tilesPerRow
        let col = index % tilesPerRow
        
        // Actual tile size in the source image (might be scaled)
        let actualTileWidth = Int(tileset.size.width) / tilesPerRow
        let actualTileHeight = Int(tileset.size.height) / tilesPerCol
        
        let x = col * actualTileWidth
        let y = row * actualTileHeight
        
        // Extract the tile
        guard let croppedCG = cgImage.cropping(to: CGRect(x: x, y: y, width: actualTileWidth, height: actualTileHeight)) else {
            return nil
        }
        
        // Colorize the tile (the tileset uses magenta as transparent)
        let colorizedImage = colorizeTile(croppedCG, with: color, scale: scale)
        
        if let result = colorizedImage {
            tileCache[cacheKey] = result
        }
        
        return colorizedImage
    }
    
    /// Colorize a tile - replace white pixels with the target color, magenta becomes transparent
    private func colorizeTile(_ tile: CGImage, with color: UIColor, scale: CGFloat) -> UIImage? {
        let sourceWidth = tile.width
        let sourceHeight = tile.height
        let width = Int(CGFloat(sourceWidth) * scale)
        let height = Int(CGFloat(sourceHeight) * scale)
        
        guard width > 0, height > 0 else { return nil }
        
        // Create a bitmap context to read pixel data
        guard let colorSpace = CGColorSpaceCreateDeviceRGB() as CGColorSpace?,
              let bitmapContext = CGContext(
                data: nil,
                width: sourceWidth,
                height: sourceHeight,
                bitsPerComponent: 8,
                bytesPerRow: sourceWidth * 4,
                space: colorSpace,
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
              ) else { return nil }
        
        // Draw the source tile into our context
        bitmapContext.draw(tile, in: CGRect(x: 0, y: 0, width: sourceWidth, height: sourceHeight))
        
        // Get pixel data
        guard let pixelData = bitmapContext.data else { return nil }
        let pixels = pixelData.bindMemory(to: UInt8.self, capacity: sourceWidth * sourceHeight * 4)
        
        // Get target color components
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        color.getRed(&r, green: &g, blue: &b, alpha: &a)
        let targetR = UInt8(r * 255)
        let targetG = UInt8(g * 255)
        let targetB = UInt8(b * 255)
        
        // Process each pixel
        for y in 0..<sourceHeight {
            for x in 0..<sourceWidth {
                let offset = (y * sourceWidth + x) * 4
                let red = pixels[offset]
                let green = pixels[offset + 1]
                let blue = pixels[offset + 2]
                
                // Check if pixel is magenta (RGB: 255, 0, 255) - make it transparent
                // More precise magenta detection: red and blue high, green very low
                let isMagenta = (red > 200 && blue > 200 && green < 50) ||
                               (red > 240 && blue > 240 && green < 100)
                
                if isMagenta {
                    pixels[offset] = 0
                    pixels[offset + 1] = 0
                    pixels[offset + 2] = 0
                    pixels[offset + 3] = 0  // Alpha = 0 (transparent)
                }
                // Check if pixel is white or bright - colorize it
                else if red > 50 || green > 50 || blue > 50 {
                    // Use the brightness to modulate the target color
                    let brightness = CGFloat(max(red, green, blue)) / 255.0
                    pixels[offset] = UInt8(CGFloat(targetR) * brightness)
                    pixels[offset + 1] = UInt8(CGFloat(targetG) * brightness)
                    pixels[offset + 2] = UInt8(CGFloat(targetB) * brightness)
                    pixels[offset + 3] = 255  // Keep opaque
                } else {
                    // Dark pixels become transparent
                    pixels[offset] = 0
                    pixels[offset + 1] = 0
                    pixels[offset + 2] = 0
                    pixels[offset + 3] = 0
                }
            }
        }
        
        // Create image from modified pixel data
        guard let outputImage = bitmapContext.makeImage() else { return nil }
        
        // Scale if needed
        if scale != 1.0 {
            UIGraphicsBeginImageContextWithOptions(CGSize(width: width, height: height), false, 1.0)
            guard let drawContext = UIGraphicsGetCurrentContext() else {
                UIGraphicsEndImageContext()
                return nil
            }
            
            // Use nearest neighbor for pixel-perfect scaling
            drawContext.interpolationQuality = .none
            drawContext.setShouldAntialias(false)
            
            // Flip coordinate system for proper drawing
            drawContext.translateBy(x: 0, y: CGFloat(height))
            drawContext.scaleBy(x: 1.0, y: -1.0)
            
            drawContext.draw(outputImage, in: CGRect(x: 0, y: 0, width: width, height: height))
            
            let result = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            return result
        }
        
        return UIImage(cgImage: outputImage)
    }
    
    /// Check if tileset is available
    var isAvailable: Bool {
        tilesetImage != nil
    }
    
    /// Clear the cache (call when memory is low)
    func clearCache() {
        tileCache.removeAll()
    }
}

private struct TileCacheKey: Hashable {
    let index: Int
    let color: UIColor
    let scale: CGFloat
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(index)
        hasher.combine(scale)
        // Hash color components
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        color.getRed(&r, green: &g, blue: &b, alpha: &a)
        hasher.combine(Int(r * 255))
        hasher.combine(Int(g * 255))
        hasher.combine(Int(b * 255))
    }
    
    static func == (lhs: TileCacheKey, rhs: TileCacheKey) -> Bool {
        guard lhs.index == rhs.index, lhs.scale == rhs.scale else { return false }
        var lr: CGFloat = 0, lg: CGFloat = 0, lb: CGFloat = 0, la: CGFloat = 0
        var rr: CGFloat = 0, rg: CGFloat = 0, rb: CGFloat = 0, ra: CGFloat = 0
        lhs.color.getRed(&lr, green: &lg, blue: &lb, alpha: &la)
        rhs.color.getRed(&rr, green: &rg, blue: &rb, alpha: &ra)
        return lr == rr && lg == rg && lb == rb
    }
}
