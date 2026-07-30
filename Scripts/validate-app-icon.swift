#!/usr/bin/env swift

import AppKit
import Foundation
import ImageIO

var paths = Array(CommandLine.arguments.dropFirst())
let allowSmall = paths.first == "--allow-small"
if allowSmall {
  paths.removeFirst()
}
guard !paths.isEmpty else {
  fputs("usage: validate-app-icon.swift [--allow-small] icon.png ...\n", stderr)
  exit(2)
}

for path in paths {
  let url = URL(fileURLWithPath: path)
  guard
    let source = CGImageSourceCreateWithURL(url as CFURL, nil),
    let image = CGImageSourceCreateImageAtIndex(source, 0, nil)
  else {
    fputs("\(path): could not decode image\n", stderr)
    exit(1)
  }
  guard image.width == image.height, allowSmall || image.width >= 1024 else {
    fputs("\(path): icon must be square\(allowSmall ? "" : " and at least 1024px")\n", stderr)
    exit(1)
  }

  let bitmap = NSBitmapImageRep(cgImage: image)
  let last = image.width - 1
  let corners = [(0, 0), (last, 0), (0, last), (last, last)]
  guard
    corners.allSatisfy({
      bitmap.colorAt(x: $0.0, y: $0.1)?.alphaComponent ?? 1 < 0.01
    })
  else {
    fputs("\(path): all four corners must be transparent\n", stderr)
    exit(1)
  }
  guard
    bitmap.colorAt(x: image.width / 2, y: image.height / 2)?.alphaComponent ?? 0 > 0.99
  else {
    fputs("\(path): icon center must remain opaque\n", stderr)
    exit(1)
  }
}
