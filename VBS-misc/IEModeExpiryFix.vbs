'Sets the date added for all Edge IE Mode pages to 2099
'This causes the expiry dates to also be 2099
'How to use:
'1. Add your IE Mode pages in Microsoft Edge
'2. Close Microsoft Edge
'3. Run this script
'Repeat the above steps whenever you add more IE Mode pages

Silent = False
Const ForReading = 1
Const ForWriting = 2
Const Ansi = 0
Dim PrefsFile
DateAdded = "10/28/2099 10:00:00 PM"

Set oDateTime = CreateObject("WbemScripting.SWbemDateTime")
Call oDateTime.SetVarDate(DateAdded,True)
EdgeDateAdded = Left(oDateTime.GetFileTime,17)

Set oWSH = CreateObject("WScript.Shell")
Set oFSO = CreateObject("Scripting.FileSystemObject")
EdgeData = oWSH.ExpandEnvironmentStrings("%LocalAppData%") & "\Microsoft\Edge\User Data\"

If Not Silent Then
  Response = MsgBox("Change expiry of all Edge IE Mode pages to:" & VBCRLF & VBCRLF & DateAdded & " + 30 days?",VBOKCancel)
  If Response=VBCancel Then WScript.Quit
End If

'Edge must be closed to modify the Preferences file
oWSH.Run "TaskKill /im MSEdge.exe /f",0,True

Sub EditProfile
  'Read contents of Edge Preferences file into a variable
  Set oInput = oFSO.OpenTextFile(PrefsFile,ForReading)
  Data = oInput.ReadAll
  oInput.Close

  'Find and change ever IE Mode page entry
  'Possible enhancement: replace this loop with a regexp
  StartPos = 1
  Do
    FoundPos = InStr(StartPos,Data,"date_added")
    If FoundPos=0 Then Exit Do
    Data = Mid(Data,1,FoundPos + 12) & EdgeDateAdded & Mid(Data,FoundPos + 30)
    StartPos = FoundPos + 1
  Loop
  
  'Set "Allow sites to be reloaded in Internet Explorer mode" to "Allow"
  Data = Replace(Data,"{""ie_user""","{""enabled_state"":1,""ie_user""")
  Data = Replace(Data,"{""enabled_state"":0,""ie_user""","{""enabled_state"":1,""ie_user""")
  Data = Replace(Data,"{""enabled_state"":2,""ie_user""","{""enabled_state"":1,""ie_user""")

  'Overwrite the Preferences file with the new data
  Set oOutput = oFSO.OpenTextFile(PrefsFile,ForWriting,True,Ansi)
  oOutput.Write Data
  oOutput.Close
End Sub

PrefsFile = EdgeData & "Default\Preferences"
If oFSO.FileExists(PrefsFile) Then EditProfile

For Each oFolder In oFSO.GetFolder(EdgeData).SubFolders
  PrefsFile = oFolder.Path & "\Preferences"
  If oFSO.FileExists(PrefsFile) Then EditProfile
Next

If Not Silent Then MsgBox "Done"
