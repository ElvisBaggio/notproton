// Manual check for #44: hides the cursor like a mouselook game and logs every WM_INPUT mouse
// event (delta, usFlags, cursor) to rawprobe.log. Build: x86_64-w64-mingw32-clang -O2 -mwindows.
#include <windows.h>
#include <stdio.h>
static FILE *out;
static LRESULT CALLBACK proc(HWND w, UINT m, WPARAM wp, LPARAM lp) {
    if (m == WM_SETCURSOR && LOWORD(lp) == HTCLIENT) { SetCursor(NULL); return TRUE; }
    if (m == WM_INPUT) {
        RAWINPUT ri; UINT size = sizeof(ri);
        if (GetRawInputData((HRAWINPUT)lp, RID_INPUT, &ri, &size, sizeof(RAWINPUTHEADER)) != (UINT)-1
            && ri.header.dwType == RIM_TYPEMOUSE) {
            { POINT pt; GetCursorPos(&pt); fprintf(out, "%lu %ld %ld flags=%u cursor=%ld,%ld\n", GetTickCount(), ri.data.mouse.lLastX, ri.data.mouse.lLastY, ri.data.mouse.usFlags, pt.x, pt.y); }
            fflush(out);
        }
    }
    if (m == WM_DESTROY) PostQuitMessage(0);
    return DefWindowProcW(w, m, wp, lp);
}
int WINAPI WinMain(HINSTANCE h, HINSTANCE p, LPSTR c, int s) {
    out = fopen("rawprobe.log", "w");
    WNDCLASSW wc = {0}; wc.lpfnWndProc = proc; wc.hInstance = h; wc.lpszClassName = L"rawprobe";
    RegisterClassW(&wc);
    HWND w = CreateWindowW(L"rawprobe", L"rawprobe - mexa o mouse", WS_OVERLAPPEDWINDOW | WS_VISIBLE,
                           100, 100, 800, 600, 0, 0, h, 0);
    RAWINPUTDEVICE d = {1, 2, 0, w};
    RegisterRawInputDevices(&d, 1, sizeof(d));
    ShowCursor(FALSE);
    MSG msg;
    while (GetMessageW(&msg, 0, 0, 0) > 0) { TranslateMessage(&msg); DispatchMessageW(&msg); }
    return 0;
}
