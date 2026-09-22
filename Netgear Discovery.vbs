Option Explicit
Dim shell, files, root, logDir, installCode, buildCode, firstRun, collectorReady, dashboardReady, trayCommand
Set shell = CreateObject("WScript.Shell")
Set files = CreateObject("Scripting.FileSystemObject")
root = files.GetParentFolderName(WScript.ScriptFullName)
logDir = root & "\logs"
shell.CurrentDirectory = root
If Not files.FolderExists(logDir) Then files.CreateFolder(logDir)

If Not files.FileExists(root & "\node_modules\.bin\next.cmd") Then
  If files.FolderExists(root & "\node_modules") Then files.DeleteFolder root & "\node_modules", True
  installCode = shell.Run("cmd.exe /c npm install > ""logs\install.log"" 2>&1", 0, True)
  If installCode <> 0 Then
    MsgBox "Netgear Discovery could not install its required components. Make sure Node.js LTS is installed. Details are in logs\install.log.", 16, "Netgear Discovery"
    WScript.Quit installCode
  End If
End If

buildCode = shell.Run("cmd.exe /c npm run build > ""logs\dashboard-build.log"" 2>&1", 0, True)
If buildCode <> 0 Then
  MsgBox "The dashboard could not be prepared. Details are in logs\dashboard-build.log.", 16, "Netgear Discovery"
  WScript.Quit buildCode
End If

firstRun = Not files.FileExists(root & "\collector\.env")
trayCommand = "powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File """ & root & "\scripts\switchboard-tray.ps1"""
shell.Run trayCommand, 0, False

collectorReady = WaitForUrl("http://localhost:8787/api/health", 30)
dashboardReady = WaitForUrl("http://localhost:3000", 45)

If firstRun And collectorReady Then
  shell.Run "http://localhost:8787/setup"
ElseIf dashboardReady Then
  shell.Run "http://localhost:3000"
ElseIf collectorReady Then
  MsgBox "The collector started, but the dashboard did not. Double-click Netgear Discovery again. If it still fails, check logs\dashboard.log.", 48, "Netgear Discovery"
  shell.Run "http://localhost:8787/setup"
Else
  MsgBox "Netgear Discovery could not start. Check the files in the logs folder for details.", 16, "Netgear Discovery"
End If

Function UrlReady(url)
  On Error Resume Next
  Dim request
  Set request = CreateObject("MSXML2.ServerXMLHTTP.6.0")
  request.setTimeouts 1000, 1000, 1000, 1000
  request.Open "GET", url, False
  request.Send
  If Err.Number = 0 Then
    UrlReady = (request.Status >= 200 And request.Status < 500)
  Else
    UrlReady = False
  End If
  Err.Clear
  On Error GoTo 0
End Function

Function WaitForUrl(url, attempts)
  Dim i
  WaitForUrl = False
  For i = 1 To attempts
    If UrlReady(url) Then
      WaitForUrl = True
      Exit Function
    End If
    WScript.Sleep 1000
  Next
End Function
