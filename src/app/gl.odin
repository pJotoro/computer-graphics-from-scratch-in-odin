package app

import gl "vendor:OpenGL"
import win32 "core:sys/windows"

gl_init :: proc(major, minor: int) {
    ctx.using_gl = true

    {
        dummy := win32.CreateWindowExW(0, L("STATIC"), L("DummyWindow"), win32.WS_OVERLAPPED, win32.CW_USEDEFAULT, win32.CW_USEDEFAULT, win32.CW_USEDEFAULT, win32.CW_USEDEFAULT, nil, nil, nil, nil)
        defer win32.DestroyWindow(dummy)

        hdc := win32.GetDC(dummy)
        defer win32.ReleaseDC(dummy, hdc)

        desc := win32.PIXELFORMATDESCRIPTOR{
            nSize = size_of(win32.PIXELFORMATDESCRIPTOR),
            nVersion = 1,
            dwFlags = win32.PFD_DRAW_TO_WINDOW | win32.PFD_SUPPORT_OPENGL | win32.PFD_DOUBLEBUFFER,
            iPixelType = win32.PFD_TYPE_RGBA,
            cColorBits = 24,
        }
        format := win32.ChoosePixelFormat(hdc, &desc)
        win32.DescribePixelFormat(hdc, format, size_of(desc), &desc)
        win32.SetPixelFormat(hdc, format, &desc)

        rc := win32.wglCreateContext(hdc)
        defer win32.wglDeleteContext(rc)
        
        win32.wglMakeCurrent(hdc, rc)
        defer win32.wglMakeCurrent(nil, nil)

        win32.wglChoosePixelFormatARB = win32.ChoosePixelFormatARBType(win32.wglGetProcAddress("wglChoosePixelFormatARB"))
        win32.wglCreateContextAttribsARB = win32.CreateContextAttribsARBType(win32.wglGetProcAddress("wglCreateContextAttribsARB"))
        win32.wglSwapIntervalEXT = win32.SwapIntervalEXTType(win32.wglGetProcAddress("wglSwapIntervalEXT"))
    }

    ctx.gl_hdc = win32.GetDC(ctx.window)
    
    {
        attrib := [?]i32{
            win32.WGL_DRAW_TO_WINDOW_ARB, 1,
            win32.WGL_SUPPORT_OPENGL_ARB, 1,
            win32.WGL_DOUBLE_BUFFER_ARB, 1,
            win32.WGL_PIXEL_TYPE_ARB, win32.WGL_TYPE_RGBA_ARB,
            win32.WGL_COLOR_BITS_ARB, 24,
            win32.WGL_STENCIL_BITS_ARB, 8,

            0,
        }

        format: i32
        formats: u32
        win32.wglChoosePixelFormatARB(ctx.gl_hdc, &attrib[0], nil, 1, &format, &formats)
        desc := win32.PIXELFORMATDESCRIPTOR{
            nSize = size_of(win32.PIXELFORMATDESCRIPTOR),
        }
        win32.DescribePixelFormat(ctx.gl_hdc, format, size_of(desc), &desc)
        win32.SetPixelFormat(ctx.gl_hdc, format, &desc)
    }
    
    {
        attrib := [?]i32{
            win32.WGL_CONTEXT_MAJOR_VERSION_ARB, i32(major),
            win32.WGL_CONTEXT_MINOR_VERSION_ARB, i32(minor),
            win32.WGL_CONTEXT_PROFILE_MASK_ARB, win32.WGL_CONTEXT_CORE_PROFILE_BIT_ARB,

            win32.WGL_CONTEXT_FLAGS_ARB, win32.WGL_CONTEXT_DEBUG_BIT_ARB,

            0,
        }

        rc := win32.wglCreateContextAttribsARB(ctx.gl_hdc, nil, &attrib[0])
        win32.wglMakeCurrent(ctx.gl_hdc, rc)
    }

    gl.load_up_to(major, minor, win32.gl_set_proc_address)

    win32.wglSwapIntervalEXT(1)
}

gl_swap_buffers :: proc() {
    win32.SwapBuffers(ctx.gl_hdc)
}