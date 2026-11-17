import 'dart:ffi';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';

import 'usb_printer_transport.dart';

/// Raw USB printing on Windows through the `usbprint.sys` device interface:
/// no print queue or driver install needed. The only file that touches
/// `win32`; create it only when `Platform.isWindows`.
///
/// Each call runs in a short-lived isolate so a stalled printer never
/// freezes the UI.
class WinUsbPrintApi implements UsbPrintApi {
  const WinUsbPrintApi();

  @override
  Future<List<UsbPrinterInfo>> list() => Isolate.run(_list);

  @override
  Future<int> open(String devicePath) => Isolate.run(() => _open(devicePath));

  // shortcut: WriteFile blocks until usbprint's own timeout if the printer
  // stalls; add overlapped I/O with a deadline if that shows up in use.
  @override
  Future<int> write(int handle, Uint8List bytes) =>
      Isolate.run(() => _write(handle, bytes));

  @override
  Future<void> close(int handle) => Isolate.run(() => _close(handle));
}

/// GUID_DEVINTERFACE_USBPRINT
const _usbPrintGuid = '{28D78FAD-5A12-11D1-AE5B-0000F803A8C2}';

final _vidPid = RegExp(
  'vid_([0-9a-f]{4})&pid_([0-9a-f]{4})',
  caseSensitive: false,
);

/// `VID_0483&PID_5743` from a device path, or null.
String? hardwareIdOf(String devicePath) {
  final m = _vidPid.firstMatch(devicePath);
  return m == null
      ? null
      : 'VID_${m[1]!.toUpperCase()}&PID_${m[2]!.toUpperCase()}';
}

List<UsbPrinterInfo> _list() => using((arena) {
  final guid = GUID(_usbPrintGuid).toNative(allocator: arena);
  final set = SetupDiGetClassDevs(
    guid,
    null,
    null,
    DIGCF_PRESENT | DIGCF_DEVICEINTERFACE,
  );
  if (!set.value.isValid) {
    throw UsbPrintException('SetupDiGetClassDevs', set.error);
  }
  final devInfoSet = set.value;
  try {
    final found = <UsbPrinterInfo>[];
    final iface = arena<SP_DEVICE_INTERFACE_DATA>()
      ..ref.cbSize = sizeOf<SP_DEVICE_INTERFACE_DATA>();
    final devInfo = arena<SP_DEVINFO_DATA>()
      ..ref.cbSize = sizeOf<SP_DEVINFO_DATA>();
    final size = arena<Uint32>();
    for (
      var i = 0;
      SetupDiEnumDeviceInterfaces(devInfoSet, null, guid, i, iface).value;
      i++
    ) {
      // First call only reports the size the detail struct needs.
      SetupDiGetDeviceInterfaceDetail(devInfoSet, iface, null, 0, size, null);
      final detail = arena.allocate<SP_DEVICE_INTERFACE_DETAIL_DATA>(
        size.value,
      );
      // cbSize is the fixed part of the struct: 8 on 64-bit Windows.
      detail.ref.cbSize = sizeOf<IntPtr>() == 8 ? 8 : 6;
      if (!SetupDiGetDeviceInterfaceDetail(
        devInfoSet,
        iface,
        detail,
        size.value,
        null,
        devInfo,
      ).value) {
        continue;
      }
      final path = detail.ref.DevicePath;
      final hardwareId = hardwareIdOf(path);
      if (hardwareId == null) continue;
      found.add(
        UsbPrinterInfo(
          name:
              _property(devInfoSet, devInfo, SPDRP_FRIENDLYNAME, arena) ??
              _property(devInfoSet, devInfo, SPDRP_DEVICEDESC, arena) ??
              'Impresora USB',
          hardwareId: hardwareId,
          devicePath: path,
        ),
      );
    }
    return found;
  } finally {
    SetupDiDestroyDeviceInfoList(devInfoSet);
  }
});

String? _property(
  HDEVINFO set,
  Pointer<SP_DEVINFO_DATA> devInfo,
  SETUP_DI_REGISTRY_PROPERTY property,
  Arena arena,
) {
  const bytes = 512;
  final buffer = arena<Uint8>(bytes);
  final ok = SetupDiGetDeviceRegistryProperty(
    set,
    devInfo,
    property,
    null,
    buffer,
    bytes,
    null,
  ).value;
  if (!ok) return null;
  final text = buffer.cast<Utf16>().toDartString();
  return text.isEmpty ? null : text;
}

int _open(String devicePath) => using((arena) {
  final r = CreateFile(
    arena.pcwstr(devicePath),
    GENERIC_WRITE,
    FILE_SHARE_READ,
    null,
    OPEN_EXISTING,
    FILE_ATTRIBUTE_NORMAL,
    null,
  );
  if (!r.value.isValid) throw UsbPrintException('CreateFile', r.error);
  return r.value.address;
});

int _write(int handle, Uint8List bytes) => using((arena) {
  final buffer = arena<Uint8>(bytes.length)
    ..asTypedList(bytes.length).setAll(0, bytes);
  final written = arena<Uint32>();
  final r = WriteFile(
    HANDLE(Pointer.fromAddress(handle)),
    buffer,
    bytes.length,
    written,
    null,
  );
  if (!r.value) throw UsbPrintException('WriteFile', r.error);
  return written.value;
});

void _close(int handle) {
  final r = CloseHandle(HANDLE(Pointer.fromAddress(handle)));
  if (!r.value) throw UsbPrintException('CloseHandle', r.error);
}
