// 사용법: cutout <입력이미지> <출력PNG>
// Apple Vision 전경 인스턴스 마스크로 인물 배경을 투명 처리한다(픽셀은 원본 그대로).
import Foundation
import Vision
import CoreImage
import AppKit

let args = CommandLine.arguments
guard args.count >= 3 else { print("usage: cutout in out.png"); exit(1) }
let inURL = URL(fileURLWithPath: args[1])
let outURL = URL(fileURLWithPath: args[2])
guard let ciImage = CIImage(contentsOf: inURL, options: [.applyOrientationProperty: true]) else { print("load fail"); exit(1) }

let handler = VNImageRequestHandler(ciImage: ciImage, options: [:])
let req = VNGenerateForegroundInstanceMaskRequest()
do { try handler.perform([req]) } catch { print("vision fail: \(error)"); exit(1) }
guard let result = req.results?.first else { print("no foreground"); exit(2) }
// 인스턴스 선택: 인자로 인덱스 목록을 주면 그것만, 아니면 전체
var instances = result.allInstances
if args.count >= 4 {
  let pick = IndexSet(args[3].split(separator: ",").compactMap { Int($0) })
  instances = pick
}
print("instances: \(Array(result.allInstances))")
do {
  let buf = try result.generateMaskedImage(ofInstances: instances, from: handler, croppedToInstancesExtent: false)
  let out = CIImage(cvPixelBuffer: buf)
  let ctx = CIContext()
  try ctx.writePNGRepresentation(of: out, to: outURL, format: .RGBA8, colorSpace: CGColorSpace(name: CGColorSpace.sRGB)!)
  print("ok \(outURL.path)")
} catch { print("mask fail: \(error)"); exit(1) }
