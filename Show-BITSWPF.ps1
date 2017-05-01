#Requires -Version 3

#Либо MTA, либо Open/SaveFileDialog... =(
if ([threading.thread]::CurrentThread.GetApartmentState() -ne [System.Threading.ApartmentState]::STA) {
    Start-Process powershell.exe -ArgumentList ("-sta " + $MyInvocation.MyCommand.Definition);
    Exit;
}
#Чит, однако

Add-Type –assemblyName PresentationFramework;
Add-Type –assemblyName PresentationCore;
Add-Type –assemblyName WindowsBase;

$window = New-Object Windows.Window

$window.Title = $window.Content = “Hello World.  Check out PowerShell and WPF Together.”

$window.SizeToContent = “WidthAndHeight”

$null = $window.ShowDialog()