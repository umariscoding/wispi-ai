import Foundation
import Cocoa

let _BAKED_KEY = ""
let OPENAI_API_KEY = ProcessInfo.processInfo.environment["OPENAI_API_KEY"] ?? _BAKED_KEY
var WINDOW_WIDTH: CGFloat = 480
var WINDOW_HEIGHT: CGFloat = 480
let WINDOW_WIDTH_NARROW: CGFloat = 380
let WINDOW_WIDTH_WIDE: CGFloat = 650
let APP_NAME = "safari"
