package w4me.midp;

import javax.microedition.lcdui.Alert;
import javax.microedition.lcdui.AlertType;
import javax.microedition.lcdui.Command;
import javax.microedition.lcdui.CommandListener;
import javax.microedition.lcdui.Display;
import javax.microedition.lcdui.Displayable;
import javax.microedition.lcdui.TextBox;
import javax.microedition.lcdui.TextField;
import javax.microedition.midlet.MIDlet;

import w4me.runtime.audio.AudioControl;
import w4me.runtime.audio.Wasm4Apu;

public class W4MeMidlet extends MIDlet implements CommandListener {
    private LibraryList library;
    private W4Canvas canvas;
    private TextBox locationEntry;
    private boolean autostartChecked;
    private boolean audioPreferenceLoaded;
    private boolean compatibilityAudio;
    private boolean soundMuted;
    private int audioGain = 100;
    private final Command runLocationCommand = new Command("Run", Command.OK, 1);
    private final Command cancelLocationCommand = new Command("Cancel", Command.CANCEL, 2);

    protected void startApp() {
        if (!autostartChecked) {
            autostartChecked = true;
            String location = getAppProperty("W4ME-Cartridge-URL");
            if (location != null && location.trim().length() != 0) {
                location = location.trim();
                openCartridge(
                        location,
                        titleFromLocation(location));
                return;
            }
        }
        if (canvas != null) {
            Display.getDisplay(this).setCurrent(canvas);
            canvas.start();
        } else {
            showLibrary();
        }
    }

    protected void pauseApp() {
        if (canvas != null) {
            canvas.stop();
        }
    }

    protected void destroyApp(boolean unconditional) {
        if (canvas != null) {
            canvas.stop();
        }
    }

    void showLibrary() {
        if (canvas != null) {
            canvas.stop();
            canvas = null;
        }
        showLibraryDisplayable();
    }

    void showCartridgeFailure(W4Canvas source, String title, Throwable failure) {
        if (canvas != source) {
            return;
        }
        source.stop();
        canvas = null;
        LibraryList returnTo = libraryDisplayable();
        String message = explain(failure);
        if (message.length() > 512) {
            message = message.substring(0, 512);
        }
        Alert alert = new Alert("Cart cannot run: " + title, message, null, AlertType.ERROR);
        alert.setTimeout(Alert.FOREVER);
        Display.getDisplay(this).setCurrent(alert, returnTo);
    }

    /**
     * Turns a runtime failure into something a phone user can act on. The internal
     * trap text stays as-is for logs and tests; only what reaches the Alert changes.
     */
    private static String explain(Throwable failure) {
        String raw = failure.toString();
        if (raw.indexOf("instruction budget exhausted") >= 0) {
            return "One frame of this cartridge needed more work than a single frame"
                    + " is allowed, so it was stopped. This is a limit of running"
                    + " WebAssembly on this phone, not a damaged cartridge. Some"
                    + " cartridges compute a whole move or level inside one frame"
                    + " and cannot finish in time.";
        }
        return raw;
    }

    private void showLibraryDisplayable() {
        Display.getDisplay(this).setCurrent(libraryDisplayable());
    }

    private LibraryList libraryDisplayable() {
        if (library == null) {
            library = new LibraryList(this);
        } else {
            library.reloadInstalled();
        }
        return library;
    }

    void showLocationEntry() {
        if (locationEntry == null) {
            locationEntry =
                    new TextBox("Enter URL/file location", "", 512, TextField.URL);
            locationEntry.addCommand(runLocationCommand);
            locationEntry.addCommand(cancelLocationCommand);
            locationEntry.setCommandListener(this);
        }
        Display.getDisplay(this).setCurrent(locationEntry);
    }

    void showInstallOptions() {
        if (!FileSystemAccessFactory.isAvailable()) {
            showLocationEntry();
            return;
        }
        showFileBrowser();
    }

    private void showFileBrowser() {
        try {
            FileBrowserList browser =
                    new FileBrowserList(this, FileSystemAccessFactory.create());
            browser.show();
        } catch (Throwable failure) {
            String message = failure.toString();
            Alert alert =
                    new Alert(
                            "Local files unavailable",
                            message,
                            null,
                            AlertType.ERROR);
            alert.setTimeout(Alert.FOREVER);
            Display.getDisplay(this).setCurrent(alert, locationEntryDisplayable());
        }
    }

    void showFileSelection(FileBrowserList browser, FileSelection selection) {
        Display.getDisplay(this)
                .setCurrent(new FileSelectionForm(this, browser, selection));
    }

    private TextBox locationEntryDisplayable() {
        if (locationEntry == null) {
            locationEntry =
                    new TextBox("Enter URL/file location", "", 512, TextField.URL);
            locationEntry.addCommand(runLocationCommand);
            locationEntry.addCommand(cancelLocationCommand);
            locationEntry.setCommandListener(this);
        }
        return locationEntry;
    }

    public void commandAction(Command command, Displayable displayable) {
        if (command == runLocationCommand) {
            String location = locationEntry.getString().trim();
            if (location.length() != 0) {
                openCartridge(location, titleFromLocation(location));
                return;
            }
        }
        showLibrary();
    }

    void openCartridge(String resource, String title) {
        canvas =
                new W4Canvas(
                        this,
                        resource,
                        title,
                        createSessionMonitor(resource, title));
        Display.getDisplay(this).setCurrent(canvas);
        canvas.start();
    }

    String audioBackendPreference() {
        loadAudioPreference();
        return compatibilityAudio ? "midi" : null;
    }

    boolean compatibilityAudioEnabled() {
        loadAudioPreference();
        return compatibilityAudio;
    }

    boolean soundMuted() {
        loadAudioPreference();
        return soundMuted;
    }

    int audioGain() {
        loadAudioPreference();
        return audioGain;
    }

    void configureAudio(Wasm4Apu audio) {
        loadAudioPreference();
        audio.setMasterGain(audioGain);
        audio.setMuted(soundMuted);
    }

    void showAudioSettings(W4Canvas source) {
        loadAudioPreference();
        int capability =
                source == null
                        ? AudioControl.VOLUME_CONTINUOUS
                        : source.audioVolumeCapability();
        if (source != null) {
            source.openAudioSettings();
        }
        Display.getDisplay(this)
                .setCurrent(
                        new AudioSettingsForm(
                                this,
                                source,
                                capability,
                                compatibilityAudio,
                                soundMuted,
                                audioGain));
    }

    void finishAudioSettings(
            W4Canvas source,
            boolean apply,
            boolean compatible,
            boolean muted,
            int gain) {
        boolean saved = true;
        if (apply) {
            compatibilityAudio = compatible;
            soundMuted = muted;
            audioGain = gain;
            saved =
                    AudioPreferences.save(
                            new AudioPreferences.Settings(
                                    compatibilityAudio,
                                    soundMuted,
                                    audioGain));
        }

        Displayable target;
        if (source != null && canvas == source) {
            source.closeAudioSettings(apply, soundMuted, audioGain);
            target = source;
        } else {
            target = libraryDisplayable();
        }

        if (apply && !saved) {
            Alert alert =
                    new Alert(
                            "Sound settings",
                            "Settings are active for this session, but could not be saved.",
                            null,
                            AlertType.WARNING);
            alert.setTimeout(Alert.FOREVER);
            Display.getDisplay(this).setCurrent(alert, target);
        } else {
            Display.getDisplay(this).setCurrent(target);
        }
    }

    protected W4SessionMonitor createSessionMonitor(String resource, String title) {
        return null;
    }

    void exit() {
        notifyDestroyed();
    }

    private void loadAudioPreference() {
        if (audioPreferenceLoaded) {
            return;
        }
        audioPreferenceLoaded = true;
        AudioPreferences.Settings saved = AudioPreferences.load();
        String preference = getAppProperty("W4ME-Audio-Backend");
        compatibilityAudio =
                ("midi".equals(preference) || "tone".equals(preference))
                        || saved.compatibilityMode;
        soundMuted = saved.muted;
        audioGain = saved.gain;
    }

    private String titleFromLocation(String location) {
        int end = location.length();
        int query = location.indexOf('?');
        if (query >= 0 && query < end) {
            end = query;
        }
        int fragment = location.indexOf('#');
        if (fragment >= 0 && fragment < end) {
            end = fragment;
        }
        int slash = location.lastIndexOf('/', end - 1);
        int backslash = location.lastIndexOf('\\', end - 1);
        int start = (slash > backslash ? slash : backslash) + 1;
        if (start >= end) {
            return "External cartridge";
        }
        String title = location.substring(start, end);
        if (title.toLowerCase().endsWith(".wasm")) {
            title = title.substring(0, title.length() - 5);
        }
        return title.length() == 0 ? "External cartridge" : title;
    }
}
