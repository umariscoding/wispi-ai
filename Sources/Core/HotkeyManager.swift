import Cocoa
import Carbon.HIToolbox

class HotkeyManager {
    private var handler: EventHandlerRef?
    private var hotkeys: [(UInt32, () -> Void)] = []

    func add(key: Int, mod: UInt32, id: UInt32, action: @escaping () -> Void) {
        var ref: EventHotKeyRef?
        let hkid = EventHotKeyID(signature: 0x53544C54, id: id)
        RegisterEventHotKey(UInt32(key), mod, hkid, GetApplicationEventTarget(), 0, &ref)
        hotkeys.append((id, action))
    }

    func start() {
        var spec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        InstallEventHandler(GetApplicationEventTarget(), { _, event, ud -> OSStatus in
            var hkid = EventHotKeyID()
            GetEventParameter(event!, EventParamName(kEventParamDirectObject), EventParamType(typeEventHotKeyID),
                              nil, MemoryLayout<EventHotKeyID>.size, nil, &hkid)
            Unmanaged<HotkeyManager>.fromOpaque(ud!).takeUnretainedValue().hotkeys.first { $0.0 == hkid.id }?.1()
            return noErr
        }, 1, &spec, Unmanaged.passUnretained(self).toOpaque(), &handler)
    }
}
