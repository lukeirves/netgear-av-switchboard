Option Explicit
Dim shell, files, root, installCode, firstRun
Set shell = CreateObject("WScript.Shell")
Set files = CreateObject("Scripting.FileSystemObject")
root = files.GetParentFolderName(WScript.ScriptFullName)

If Not files.FolderExists(root & "\node_modules") Then
  installCode = shell.Run("cmd.exe /c cd /d """ & root & """ && npm install", 0, True)
  If installCode <> 0 Then
    MsgBox "Switchboard could not install its required components. Make sure Node.js LTS is installed, then try again.", 16, "NETGEAR AV Switchboard"
    WScript.Quit installCode
  End If
End If

firstRun = Not files.FileExists(root & "\collector\.env")
shell.Run "cmd.exe /c cd /d """ & root & """ && npm run collector", 0, False
shell.Run "cmd.exe /c cd /d """ & root & """ && npm run dev -- --host 0.0.0.0 --port 3000", 0, False
WScript.Sleep 4500
If firstRun Then
  shell.Run "http://localhost:8787/setup"
Else
  shell.Run "http://localhost:3000"
End If
