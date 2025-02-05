#include "splash_screen.h"
#include <windows.h>
#include <gdiplus.h>

SplashScreen::SplashScreen(HINSTANCE hInstance, int nCmdShow) {
    // Initialize GDI+
    Gdiplus::GdiplusStartupInput gdiplusStartupInput;
    Gdiplus::GdiplusStartup(&m_gdiplusToken, &gdiplusStartupInput, NULL);

    // Create splash window
    WNDCLASSEX wcex = { sizeof(WNDCLASSEX) };
    wcex.style = CS_HREDRAW | CS_VREDRAW;
    wcex.lpfnWndProc = WndProc;
    wcex.hInstance = hInstance;
    wcex.hCursor = LoadCursor(nullptr, IDC_ARROW);
    wcex.hbrBackground = (HBRUSH)(COLOR_WINDOW + 1);
    wcex.lpszClassName = L"SplashScreenClass";
    RegisterClassEx(&wcex);

    // Create the window
    m_hWnd = CreateWindow(
        L"SplashScreenClass", L"Orações Respondidas", 
        WS_POPUP | WS_VISIBLE, 
        CW_USEDEFAULT, CW_USEDEFAULT, 400, 300, 
        nullptr, nullptr, hInstance, this
    );

    ShowWindow(m_hWnd, nCmdShow);
    UpdateWindow(m_hWnd);
}

SplashScreen::~SplashScreen() {
    Gdiplus::GdiplusShutdown(m_gdiplusToken);
}

LRESULT CALLBACK SplashScreen::WndProc(HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam) {
    SplashScreen* pSplash = nullptr;

    if (message == WM_NCCREATE) {
        CREATESTRUCT* pCS = reinterpret_cast<CREATESTRUCT*>(lParam);
        pSplash = reinterpret_cast<SplashScreen*>(pCS->lpCreateParams);
        SetWindowLongPtr(hWnd, GWLP_USERDATA, reinterpret_cast<LONG_PTR>(pSplash));
    } else {
        pSplash = reinterpret_cast<SplashScreen*>(GetWindowLongPtr(hWnd, GWLP_USERDATA));
    }

    switch (message) {
    case WM_PAINT: {
        PAINTSTRUCT ps;
        HDC hdc = BeginPaint(hWnd, &ps);
        
        // Create graphics context
        Gdiplus::Graphics graphics(hdc);
        
        // Load splash image
        Gdiplus::Image image(L"assets/icons/app_icon.png");
        
        // Get window rect
        RECT rect;
        GetClientRect(hWnd, &rect);
        
        // Draw image centered
        int x = (rect.right - image.GetWidth()) / 2;
        int y = (rect.bottom - image.GetHeight()) / 2;
        graphics.DrawImage(&image, x, y);

        EndPaint(hWnd, &ps);
        break;
    }
    case WM_DESTROY:
        PostQuitMessage(0);
        break;
    default:
        return DefWindowProc(hWnd, message, wParam, lParam);
    }
    return 0;
}

void SplashScreen::Close() {
    if (m_hWnd) {
        DestroyWindow(m_hWnd);
    }
}
