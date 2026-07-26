package w4me.runtime.audio;

import java.io.ByteArrayInputStream;

import javax.microedition.media.Manager;
import javax.microedition.media.Player;

/** Four independent synthesized WASM-4 channels over MMAPI WAV players. */
public final class MmapiPcmBackend implements AudioBackend, AudioControl {
    private final Player[] players = new Player[4];
    private AudioBackend fallback;
    private boolean pcmAvailable;
    private boolean pcmStarted;

    public MmapiPcmBackend() {
        pcmAvailable = supportsMixing() && supportsWav();
    }

    public synchronized void submitTone(int frequency, int duration, int volume, int flags) {
        int channel = flags & 3;
        closeChannel(channel);
        if (!pcmAvailable) {
            fallback().submitTone(frequency, duration, volume, flags);
            return;
        }

        Player player = null;
        try {
            byte[] wav = Wasm4Pcm.synthesize(frequency, duration, volume, flags);
            if (wav == null) {
                return;
            }
            player = Manager.createPlayer(new ByteArrayInputStream(wav), "audio/x-wav");
            player.realize();
            player.prefetch();
            player.start();
            if (player.getState() != Player.STARTED) {
                throw new IllegalStateException("MMAPI PCM player did not start");
            }
            players[channel] = player;
            pcmStarted = true;
        } catch (Throwable unavailable) {
            closePlayer(player);
            disablePcm();
            fallback().submitTone(frequency, duration, volume, flags);
        }
    }

    public synchronized void tick() {
        int channel;
        for (channel = 0; channel < players.length; channel++) {
            Player player = players[channel];
            if (player != null && player.getState() != Player.STARTED) {
                closeChannel(channel);
            }
        }
        if (fallback != null) {
            fallback.tick();
        }
    }

    public synchronized void close() {
        int channel;
        for (channel = 0; channel < players.length; channel++) {
            closeChannel(channel);
        }
        if (fallback != null) {
            fallback.close();
        }
    }

    public String grade() {
        if (!pcmAvailable) {
            return fallback().grade();
        }
        return pcmStarted ? "C-pcm4" : "C-pcm4-ready";
    }

    public synchronized void silence() {
        int channel;
        for (channel = 0; channel < players.length; channel++) {
            closeChannel(channel);
        }
        silence(fallback);
    }

    public int volumeCapability() {
        if (pcmAvailable) {
            return VOLUME_CONTINUOUS;
        }
        return capability(fallback());
    }

    public int activeChannels() {
        int active = 0;
        int channel;
        for (channel = 0; channel < players.length; channel++) {
            Player player = players[channel];
            if (player != null && player.getState() == Player.STARTED) {
                active++;
            }
        }
        return active;
    }

    private boolean supportsWav() {
        try {
            String[] types = Manager.getSupportedContentTypes(null);
            int index;
            for (index = 0; index < types.length; index++) {
                String type = types[index].toLowerCase();
                if (type.equals("audio/x-wav")
                        || type.equals("audio/wav")
                        || type.equals("audio/wave")) {
                    return true;
                }
            }
        } catch (Throwable unavailable) {
            return false;
        }
        return false;
    }

    private boolean supportsMixing() {
        try {
            // Four WASM-4 channels require concurrent sampled-audio Players.
            // A WAV MIME entry alone does not promise that the device can mix them.
            return "true".equals(System.getProperty("supports.mixing"));
        } catch (Throwable unavailable) {
            return false;
        }
    }

    private AudioBackend fallback() {
        if (fallback == null) {
            fallback = AudioBackends.createCompatible();
        }
        return fallback;
    }

    private void disablePcm() {
        pcmAvailable = false;
        int channel;
        for (channel = 0; channel < players.length; channel++) {
            closeChannel(channel);
        }
    }

    private void closeChannel(int channel) {
        Player player = players[channel];
        players[channel] = null;
        closePlayer(player);
    }

    private void closePlayer(Player player) {
        if (player == null) {
            return;
        }
        try {
            player.stop();
        } catch (Throwable ignored) {
            // Some implementations already stop a player when media ends.
        }
        try {
            player.close();
        } catch (Throwable ignored) {
            // Best effort during channel replacement or MIDlet shutdown.
        }
    }

    private static int capability(AudioBackend backend) {
        if (backend instanceof AudioControl) {
            return ((AudioControl) backend).volumeCapability();
        }
        return VOLUME_CONTINUOUS;
    }

    private static void silence(AudioBackend backend) {
        if (backend instanceof AudioControl) {
            ((AudioControl) backend).silence();
        }
    }
}
