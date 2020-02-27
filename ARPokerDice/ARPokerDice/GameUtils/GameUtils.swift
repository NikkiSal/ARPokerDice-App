
import Foundation
import CoreGraphics

let DegreesPerRadians = Float(Double.pi/180)
let RadiansPerDegrees = Float(180/Double.pi)

func convertToRadians(angle: Float) -> Float {
  return angle * DegreesPerRadians
}

func convertToRadians(angle: CGFloat) -> CGFloat {
  return CGFloat(CGFloat(angle) * CGFloat(DegreesPerRadians))
}

/// Convert Radians to Degrees
func convertToDegrees(angle: Float) -> Float {
  return angle * RadiansPerDegrees
}

func convertToDegrees(angle: CGFloat) -> CGFloat {
  return CGFloat(CGFloat(angle) * CGFloat(RadiansPerDegrees))
}

