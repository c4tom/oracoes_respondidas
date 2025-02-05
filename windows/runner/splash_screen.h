#ifndef SPLASH_SCREEN_H_
#define SPLASH_SCREEN_H_

#include <windows.h>
#include <gdiplus.h>

class SplashScreen {
public:
    SplashScreen(HINSTANCE hInstance, int nCmdShow);
    ~SplashScreen();

    void Close();

private:
    static LRESULT CALLBACK WndProc(HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam);

    HWND m_hWnd = nullptr;
    ULONG_PTR m_gdiplusToken = 0;
};

#endif  // SPLASH_SCREEN_H_
