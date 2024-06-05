Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;

public static class fade{
    [DllImport("user32.dll", SetLastError=true, CharSet=CharSet.Auto)]
    public static extern IntPtr GetForegroundWindow();

    [DllImport("user32.dll")]
    public static extern int SetLayeredWindowAttributes(IntPtr hwnd, uint crKey, byte bAlpha, uint dwFlags);

    [DllImport("user32.dll")]
    public static extern int GetLayeredWindowAttributes(IntPtr hWnd, ref uint crKey, ref byte bAlpha, ref uint dwFlags);    

    [DllImport("user32.dll")]
    public static extern int SetWindowLongPtrA(IntPtr hWnd, int nIndex, int dwNewLong);

    [DllImport("user32.dll")]
    public static extern int GetWindowLongPtrA(IntPtr hWnd, int nIndex);

    [DllImport("user32.dll")]
    public static extern int GetAsyncKeyState(int vKey);

    [DllImport("user32.dll")]
    public static extern int GetKeyState(int vKey);
}
"@

while($true){
    if([fade]::GetKeyState(0x13) -gt 1){
        $fg = [fade]::GetForegroundWindow()
        # Find window with focus
        $prevSettings = [fade]::GetWindowLongPtrA($fg,-20)
        # Get the extended window settings 

        [void][fade]::SetWindowLongPtrA($fg, -20, ($prevSettings -bor 0x80000))
        # Pause/break pressed so at the BARE minimum we need to force the layered state to check alpha

        $colorKey = 0
        $alpha = 255
        $flags = 2
        $retVal = [fade]::GetLayeredWindowAttributes($fg, [ref]$colorKey, [ref]$alpha, [ref]$flags)
        # This is a pass by ref function so the variables need to exist first and their value gets updated

        if($retVal){
            if($alpha -eq 0){$alpha = 255} # The first call will succeed but alpha is always 0 in that case. IDK
            
            $newAlpha = 128
            if($alpha -eq 128){$newAlpha = 255} # Makes the values between alpha and newAlpha opposites

            [void][fade]::SetLayeredWindowAttributes($fg, 0, $newAlpha, 2)

            if([fade]::GetKeyState(0x10) -gt 1){ # If holding shift
                while([fade]::GetKeyState(0x13) -gt 1 -or [fade]::GetKeyState(0x10) -gt 1){[void]''}
                # Wait until they let go of both shift and pause/break
            }else{
                while([fade]::GetKeyState(0x13) -gt 1){[void]''}
                # Wait until they let go of pause/break
                [void][fade]::SetLayeredWindowAttributes($fg, 0, $alpha, 2)
                # Return the state to what it was
            }

            $retVal = [fade]::GetLayeredWindowAttributes($fg, [ref]$colorKey, [ref]$alpha, [ref]$flags)
            # Last check on current alpha value
            if($retVal -and $alpha -eq 255){ # If alpha = 255, then we must be done with it, change the type back
                [void][fade]::SetWindowLongPtrA($fg, -20, ($prevSettings -bxor 0x80000))
            }
        }
    }
}