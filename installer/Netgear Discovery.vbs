Option Explicit
Dim shell, files, root, dataRoot, firstRun, collectorReady, dashboardReady, trayCommand
Set shell = CreateObject("WScript.Shell")
Set files = CreateObject("Scripting.FileSystemObject")
root = files.GetParentFolderName(WScript.ScriptFullName)
dataRoot = shell.ExpandEnvironmentStrings("%ProgramData%") & "\Netgear Discovery"
If Not files.FolderExists(dataRoot) Then files.CreateFolder(dataRoot)
firstRun = Not files.FileExists(dataRoot & "\.env")

shell.CurrentDirectory = root
trayCommand = "powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File """ & root & "\scripts\installed-tray.ps1"""
shell.Run trayCommand, 0, False

collectorReady = WaitForUrl("http://localhost:8787/api/health", 30)
dashboardReady = WaitForUrl("http://localhost:3000", 45)

If firstRun And collectorReady Then
  shell.Run "http://localhost:8787/setup"
ElseIf dashboardReady Then
  shell.Run "http://localhost:3000"
ElseIf collectorReady Then
  MsgBox "The collector started, but the dashboard did not. Open the tray menu and choose Restart services. Logs are stored in ProgramData\Netgear Discovery\logs.", 48, "Netgear Discovery"
  shell.Run "http://localhost:8787/setup"
Else
  MsgBox "Netgear Discovery could not start. Check ProgramData\Netgear Discovery\logs for details.", 16, "Netgear Discovery"
End If

Function UrlReady(url)
  On Error Resume Next
  Dim request
  Set request = CreateObject("MSXML2.ServerXMLHTTP.6.0")
  request.setTimeouts 1000, 1000, 1000, 1000
  request.Open "GET", url, False
  request.Send
  UrlReady = (Err.Number = 0 And request.Status >= 200 And request.Status < 500)
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
