# **NUM‑LCKR**  

## *Auto‑Enable NumLock for Specific Applications (AutoHotkey v2)*

NUM‑LCKR is a lightweight AutoHotkey v2 utility that **automatically turns NumLock ON** whenever you focus a program you’ve added to its managed list — and turns it back **OFF** when you leave that program.

Perfect for users who rely on the numeric keypad in certain apps (Excel, accounting tools, calculators, data entry software, etc.) and want NumLock to “just be on” when needed.

---

## **✨ Features**

- Automatically **enables NumLock** when a chosen application becomes active  
- Automatically **disables NumLock** when switching away  
- Add apps from:
  - Running processes  
  - File browser (.exe picker)  
- Clean GUI for viewing and removing managed apps  
- Persistent configuration stored in an INI file  
- Tray icon with menu controls  
- Lightweight, fast, and unobtrusive  
- Built for **AutoHotkey v2**  

---

## **📦 Installation**

1. Install **AutoHotkey v2**  
2. Download the repository  
3. Place `NUM-LCKR.ahk` and the icon file (`num-lckr.ico`) in the same folder  
4. Run the script

To run at startup, place a shortcut to the script in:

```
shell:startup
```

---

## **🛠 Usage**

NUM‑LCKR runs in the system tray.

Right‑click the tray icon to access:

- **Add from Running Programs**  
- **Browse for .exe**  
- **View/Remove Programs**  
- **Reload Script**  
- **Exit**

Once an application is added, NUM‑LCKR will automatically manage NumLock state whenever that app is focused.

---

## **⚙ Configuration File**

NUM‑LCKR stores its configuration in:

```
numandapps.ini
```

This file contains the list of executable names that trigger NumLock.

You can edit it manually if needed, but the GUI handles everything cleanly.

---

## **📁 File Structure**

```
NUM-LCKR/
│
├── NUM-LCKR.ahk        ; Main script
├── num-lckr.ico        ; Tray icon (purple N)
├── numandapps.ini      ; Auto-generated config
└── README.md           ; This file
```

---

## **🧩 How It Works**

NUM‑LCKR monitors the active window every 250ms:

- If the active process matches one in the managed list → **NumLock ON**  
- If you leave that process and NumLock was forced → **NumLock OFF**

It never interferes with manual toggling unless the active app is in the list.

---

## **📜 License**

MIT License  
Copyright © 2026  
Paul R. Charovkine

---

## **🌐 Project Links**

GitHub:  
`https://github.com/krypdoh/NUM-LCKR`

---
