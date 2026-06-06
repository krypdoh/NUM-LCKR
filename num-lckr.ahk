#Requires AutoHotkey v2.0
#SingleInstance Force
Persistent

; Program:  NUM-LCKR.ahk
; Version:  0.1
; Author:   Paul R. Charovkine  
; Website:  github.com/krypdoh/Num-Apps
; License:  MIT
; Date:     2026-06-05

; === NumLock Auto-Enable for Specific Applications ===
; Enables NUM LOCK when the user is actively focused on a configured .exe program.
; Disables NUM LOCK when switching away from those programs.

; --- Configuration ---
global AppList := []
global ConfigFile := A_ScriptDir "\numandapps.ini"
global MonitorTimer := 0
global NumWasForced := false

; --- Startup ---
LoadConfig()
StartMonitor()
BuildTrayMenu()

; --- Tray Menu ---
BuildTrayMenu() {
    A_TrayMenu.Delete()
    A_TrayMenu.Add("Add from Running Programs", (*) => ShowRunningProcesses())
    A_TrayMenu.Add("Browse for .exe", (*) => BrowseForExe())
    A_TrayMenu.Add("View/Remove Programs", (*) => ShowManagedList())
    A_TrayMenu.Add()
    A_TrayMenu.Add("About", (*) => ShowAbout())
    A_TrayMenu.Add()
    A_TrayMenu.Add("Reload Script", (*) => Reload())
    A_TrayMenu.Add("Exit", (*) => ExitApp())
    A_TrayMenu.Default := "View/Remove Programs"

    TraySetIcon(A_ScriptDir "\numandapps.ico")   ; <-- Purple N icon
    A_IconTip := "NumLock Auto-Enable"
}

; --- Monitor Active Window ---
StartMonitor() {
    SetTimer(CheckActiveWindow, 250)
}

CheckActiveWindow() {
    global NumWasForced
    try {
        activeExe := WinGetProcessName("A")
    } catch {
        return
    }

    shouldBeOn := false
    for app in AppList {
        if (StrLower(app) = StrLower(activeExe)) {
            shouldBeOn := true
            break
        }
    }

    if (shouldBeOn && !GetKeyState("NumLock", "T")) {
        SetNumLockState("On")
        NumWasForced := true
    } else if (!shouldBeOn && NumWasForced && GetKeyState("NumLock", "T")) {
        SetNumLockState("Off")
        NumWasForced := false
    }
}

; --- Add from Running Processes ---
ShowRunningProcesses() {
    processList := GetUniqueProcesses()

    myGui := Gui("+Resize +MinSize400x300", "Select Running Program")
    myGui.SetFont("s10")
    myGui.Add("Text", "w380", "Select a program to add (double-click or select + OK):")
    lv := myGui.Add("ListView", "w380 h300 vProcessLV", ["Process Name", "PID", "Window Title"])
    lv.Opt("+Grid +Sort")

    for proc in processList {
        lv.Add(, proc.name, proc.pid, proc.title)
    }

    lv.ModifyCol(1, 150)
    lv.ModifyCol(2, 60)
    lv.ModifyCol(3, 160)

    btnOK := myGui.Add("Button", "w90 Default", "OK")
    btnCancel := myGui.Add("Button", "x+10 w90", "Cancel")

    btnOK.OnEvent("Click", (*) => ProcessSelection(myGui, lv))
    btnCancel.OnEvent("Click", (*) => myGui.Destroy())
    lv.OnEvent("DoubleClick", (ctrl, row) => ProcessSelection(myGui, lv))

    myGui.Show()
}

GetUniqueProcesses() {
    processes := []
    seen := Map()

    for proc in ComObjGet("winmgmts:").ExecQuery("SELECT Name, ProcessId FROM Win32_Process") {
        name := proc.Name
        if seen.Has(StrLower(name))
            continue
        seen[StrLower(name)] := true

        title := ""
        try {
            for hwnd in WinGetList() {
                if (WinGetProcessName(hwnd) = name) {
                    t := WinGetTitle(hwnd)
                    if (t != "") {
                        title := t
                        break
                    }
                }
            }
        }
        processes.Push({name: name, pid: proc.ProcessId, title: title})
    }
    return processes
}

ProcessSelection(myGui, lv) {
    row := lv.GetNext(0, "F")
    if (row = 0) {
        MsgBox("Please select a process first.", "No Selection", "Icon!")
        return
    }
    exeName := lv.GetText(row, 1)
    AddApplication(exeName)
    myGui.Destroy()
}

; --- Browse for .exe ---
BrowseForExe() {
    selectedFile := FileSelect(1,, "Select an Application", "Executables (*.exe)")
    if (selectedFile = "")
        return

    SplitPath(selectedFile, &fileName)
    AddApplication(fileName)
}

; --- Add Application to List ---
AddApplication(exeName) {
    for app in AppList {
        if (StrLower(app) = StrLower(exeName)) {
            MsgBox(exeName " is already in the list.", "Already Added", "Iconi")
            return
        }
    }
    AppList.Push(exeName)
    SaveConfig()
    MsgBox(exeName " has been added.`nNumLock will auto-enable when this program is active.", "Program Added", "Iconi")
}

; --- View/Remove Programs ---
ShowManagedList() {
    if (AppList.Length = 0) {
        MsgBox("No programs configured yet.`nUse the tray menu to add programs.", "Empty List", "Iconi")
        return
    }

    myGui := Gui("+Resize +MinSize350x250", "Managed Programs")
    myGui.SetFont("s10")
    myGui.Add("Text", "w350", "Programs that trigger NumLock (select to remove):")
    lb := myGui.Add("ListBox", "w350 h250 vAppLB Multi", AppList)

    btnRemove := myGui.Add("Button", "w120", "Remove Selected")
    btnClose := myGui.Add("Button", "x+10 w90", "Close")

    btnRemove.OnEvent("Click", (*) => RemoveSelected(myGui, lb))
    btnClose.OnEvent("Click", (*) => myGui.Destroy())

    myGui.Show()
}

RemoveSelected(myGui, lb) {
    selected := lb.Value
    if !IsObject(selected) {
        selected := selected ? [selected] : []
    }
    if (selected.Length = 0) {
        MsgBox("Please select one or more programs to remove.", "No Selection", "Icon!")
        return
    }

    indices := []
    for idx in selected
        indices.Push(idx)

    loop indices.Length - 1 {
        loop indices.Length - A_Index {
            if (indices[A_Index] < indices[A_Index + 1]) {
                temp := indices[A_Index]
                indices[A_Index] := indices[A_Index + 1]
                indices[A_Index + 1] := temp
            }
        }
    }

    for idx in indices
        AppList.RemoveAt(idx)

    SaveConfig()
    myGui.Destroy()
    MsgBox("Selected programs removed.", "Done", "Iconi")
}

; --- Config File (INI) ---
SaveConfig() {
    try FileDelete(ConfigFile)
    for i, app in AppList {
        IniWrite(app, ConfigFile, "Applications", "App" i)
    }
    IniWrite(AppList.Length, ConfigFile, "Applications", "Count")
}

LoadConfig() {
    global AppList := []
    if !FileExist(ConfigFile)
        return

    count := IniRead(ConfigFile, "Applications", "Count", "0")
    count := Integer(count)
    loop count {
        app := IniRead(ConfigFile, "Applications", "App" A_Index, "")
        if (app != "")
            AppList.Push(app)
    }
}

; --- Utility ---
StrLower(str) => StrReplace(Format("{:L}", str), "", "")

; --- About ---
ShowAbout() {
    aboutGui := Gui("+Owner +AlwaysOnTop", "About NUM-LCKR")
    aboutGui.SetFont("s10")
    aboutGui.Add("Text", "w360", "Program:  NUM-LCKR")
    aboutGui.Add("Text", "w360", "Version:  0.1")
    aboutGui.Add("Text", "w360", "Author:   Paul R. Charovkine")
    aboutGui.Add("Link", "w360", 'Website:  <a href="https://github.com/krypdoh/Num-Apps">github.com/krypdoh/NUM-LCKR</a>')
    aboutGui.Add("Text", "w360", "License:  MIT")
    aboutGui.Add("Text", "w360", "Date:     2026-06-05")
    btnClose := aboutGui.Add("Button", "w90 Default", "Close")
    btnClose.OnEvent("Click", (*) => aboutGui.Destroy())
    aboutGui.Show()
}

