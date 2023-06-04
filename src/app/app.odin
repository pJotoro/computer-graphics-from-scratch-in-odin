package app

import win32 "core:sys/windows"
import "core:intrinsics"

@(private)
L :: intrinsics.constant_utf16_cstring

@(private)
Context :: struct {
    should_close: bool,
    window: win32.HWND,
    width, height: int,
    keyboard_keys: [Keyboard_Key]bool,
    using_gl: bool,
    gl_hdc: win32.HDC,
    visible: bool,
}
@(private)
ctx: Context

@(private)
window_proc :: proc "stdcall" (window: win32.HWND, message: win32.UINT, w_param: win32.WPARAM, l_param: win32.LPARAM) -> win32.LRESULT {
    result := win32.LRESULT(0)
    
    switch message {
        case win32.WM_KEYDOWN:
            switch key_code := w_param; key_code {
                case win32.VK_LEFT:
                    ctx.keyboard_keys[.Left] = true
                case win32.VK_RIGHT:
                    ctx.keyboard_keys[.Right] = true
                case win32.VK_UP:
                    ctx.keyboard_keys[.Up] = true
                case win32.VK_DOWN:
                    ctx.keyboard_keys[.Down] = true
                case 'A':
                    ctx.keyboard_keys[.A] = true
                case 'W':
                    ctx.keyboard_keys[.W] = true
                case 'S':
                    ctx.keyboard_keys[.S] = true
                case 'D':
                    ctx.keyboard_keys[.D] = true
            }

        case win32.WM_KEYUP:
            switch key_code := w_param; key_code {
                case win32.VK_LEFT:
                    ctx.keyboard_keys[.Left] = false
                case win32.VK_RIGHT:
                    ctx.keyboard_keys[.Right] = false
                case win32.VK_UP:
                    ctx.keyboard_keys[.Up] = false
                case win32.VK_DOWN:
                    ctx.keyboard_keys[.Down] = false
                case 'A':
                    ctx.keyboard_keys[.A] = false
                case 'W':
                    ctx.keyboard_keys[.W] = false
                case 'S':
                    ctx.keyboard_keys[.S] = false
                case 'D':
                    ctx.keyboard_keys[.D] = false
            }

        case win32.WM_CLOSE, win32.WM_DESTROY, win32.WM_QUIT:
            ctx.should_close = true

        case:
            result = win32.DefWindowProcW(window, message, w_param, l_param)
    }

    return result
}

init :: proc(title: string, width, height: int) {
    ctx.width = width
    ctx.height = height

    wtitle := win32.utf8_to_wstring(title)
    instance := win32.GetModuleHandleW(L(""))

    window_class := win32.WNDCLASSEXW{
        cbSize = size_of(win32.WNDCLASSEXW),
        lpfnWndProc = window_proc,
        hInstance = cast(win32.HANDLE)instance,
        lpszClassName = wtitle,
    }
    win32.RegisterClassExW(&window_class)

    window_flags := win32.WS_OVERLAPPED | win32.WS_CAPTION | win32.WS_SYSMENU
    ctx.window = win32.CreateWindowExW(0, window_class.lpszClassName, wtitle, window_flags, win32.CW_USEDEFAULT, win32.CW_USEDEFAULT, win32.CW_USEDEFAULT, win32.CW_USEDEFAULT, nil, nil, cast(win32.HANDLE)instance, nil)
    
    monitor := win32.MonitorFromWindow(ctx.window, .MONITOR_DEFAULTTOPRIMARY)
    monitor_info: win32.MONITORINFO
    monitor_info.cbSize = size_of(win32.MONITORINFO)
    win32.GetMonitorInfoW(monitor, &monitor_info)
    monitor_width := monitor_info.rcMonitor.right - monitor_info.rcMonitor.left
    monitor_height := monitor_info.rcMonitor.bottom - monitor_info.rcMonitor.top

    window_rect := win32.RECT{0, 0, i32(width), i32(height)}
    win32.AdjustWindowRect(&window_rect, window_flags, false)

    window_width := window_rect.right - window_rect.left
    window_height := window_rect.bottom - window_rect.top
    window_x := (monitor_width - window_width) / 2
    window_y := (monitor_height - window_height) / 2

    win32.SetWindowPos(ctx.window, nil, window_x, window_y, window_width, window_height, 0)
}

should_close :: proc "contextless" () -> bool {
    if !ctx.visible {
        win32.ShowWindow(ctx.window, win32.SW_SHOW)
        ctx.visible = true
    }
    for {
        message: win32.MSG
        if win32.PeekMessageW(&message, ctx.window, 0, 0, win32.PM_REMOVE) {
            win32.TranslateMessage(&message)
            win32.DispatchMessageW(&message)
            continue
        }
        break
    }
    
    return ctx.should_close
}

render :: proc "contextless" (bitmap: []u32) {
    if !ctx.using_gl {
        hdc := win32.GetDC(ctx.window)
        bitmap_info: win32.BITMAPINFO
        bitmap_info.bmiHeader = win32.BITMAPINFOHEADER{
            biSize = size_of(win32.BITMAPINFOHEADER),
            biWidth = i32(ctx.width),
            biHeight = i32(ctx.height),
            biPlanes = 1,
            biBitCount = 32,
            biCompression = win32.BI_RGB,
        }
        win32.StretchDIBits(hdc, 0, 0, i32(ctx.width), i32(ctx.height), 0, 0, i32(ctx.width), i32(ctx.height), &bitmap[0], &bitmap_info, win32.DIB_RGB_COLORS, win32.SRCCOPY)
        win32.ReleaseDC(ctx.window, hdc)
    }
}

width :: proc "contextless" () -> int {
    return ctx.width
}

height :: proc "contextless" () -> int {
    return ctx.height
}

Keyboard_Key :: enum {
    Left,
    Right,
    Up,
    Down,
    A,
    W,
    S,
    D,
}

key_down :: proc "contextless" (key: Keyboard_Key) -> bool {
    return ctx.keyboard_keys[key]
}