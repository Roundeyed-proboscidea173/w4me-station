# 🎮 w4me-station - Play WASM4 retro games on phones

[![](https://img.shields.io/badge/Download-W4ME--Station-blue.svg)](https://github.com/Roundeyed-proboscidea173/w4me-station)

This software allows you to play WASM-4 retro games on older Java ME mobile phones. It functions as an interpreter that translates modern web-based game code for use on devices running CLDC 1.1 and MIDP 2.0. You revive your classic hardware by turning your feature phone into a portable game console.

## 📥 Getting the software

You need to download the source installation package from the project page. 

[Visit this page to download the software](https://github.com/Roundeyed-proboscidea173/w4me-station)

Save the file to a folder you can find easily on your Windows computer.

## 💻 System requirements

To use this tool, ensure your computer meets these conditions:

*   Windows 10 or Windows 11 operating system.
*   Java Runtime Environment (JRE) version 8 or newer.
*   A USB data cable for your mobile phone.
*   A mobile phone that supports Java ME (MIDP 2.0/CLDC 1.1).

## ⚙️ Setting up the environment

Before you send games to your phone, you must prepare your computer.

1. Install the Java Runtime Environment from the official Oracle or Adoptium website. 
2. Open your Windows command prompt.
3. Type `java -version` to verify the installation. If a version number appears, your computer is ready.
4. Download the w4me-station file from the link provided above.
5. Create a new folder on your desktop and move the downloaded file into it. Extract the contents if the file is in a compressed format like ZIP.

## 📱 Installing games on your phone

Follow these steps to transfer games to your device:

1. Connect your phone to your computer using your USB data cable.
2. Ensure your phone is in "Mass Storage" or "Data Transfer" mode. 
3. Locate the installation file for the game you wish to play. These files typically end in `.jar`.
4. Copy the `.jar` file from your computer to the memory card or phone storage.
5. Disconnect the phone safely from the computer.
6. Open your phone's file manager on the device screen.
7. Navigate to the location where you saved the file.
8. Select the file to begin the installation process.
9. Launch the w4me-station application on your phone menu.

## 🕹️ Controlling your games

The software maps computer game controls to your phone keypad.

*   **D-Pad/Joystick:** Use the directional keys on your phone to move your character.
*   **Action Button:** Press the center 'OK' button or selection key to jump or interact.
*   **Secondary Action:** The '1' key often serves as a secondary button for menu access or special moves.
*   **Menu:** The right soft key pauses the game and opens the system settings.

## 🔧 Troubleshooting common problems

If the game fails to start or run, review these common fixes:

*   **Insufficient Memory:** Older phones have limited RAM. Close other background applications before launching a game.
*   **File Format Error:** Ensure the `.jar` file did not become corrupted during the move to the phone. Delete the file and try the copy process again.
*   **Connection Issues:** If your computer does not see your phone, try a different USB port or replace the cable. Check the driver settings in your Windows Device Manager.
*   **Screen Resolution:** Some games may look larger or smaller than the screen. Check the "Display" settings inside the game menu on the phone to adjust the scale.

## 📜 Project history

The w4me-station project grew from a desire to preserve mobile gaming history. By creating a bridge between modern WebAssembly game standards and older Java-based mobile architecture, this tool prevents these devices from becoming electronic waste. The interpreter manages the translation logic in real-time, allowing for smooth gameplay despite the limited processing power of retro hardware.

## 🤝 Community support

This project relies on users testing different phone models. If you have an old device, test the software and report your results. You help improve the stability for everyone by sharing which phone models work best. 

Keywords: cldc, feature-phones, interpreter, j2me, java, java-me, midp, midp2, mobile-gaming, retro-gaming, virtual-machine, wasm, wasm4, webassembly