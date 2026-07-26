package w4me.midp;

import java.io.IOException;
import java.io.InputStream;
import java.util.Enumeration;

interface FileSystemAccess {
    FilePage listRoots(String afterKey, int limit) throws IOException;

    FilePage list(String directoryUrl, String afterKey, int limit) throws IOException;

    FileSelection inspect(String fileUrl) throws IOException;

    InputStream openInputStream(String fileUrl) throws IOException;
}

final class FileEntry {
    final String name;
    final String url;
    final String sortKey;
    final boolean directory;

    FileEntry(String name, String url, String sortKey, boolean directory) {
        this.name = name;
        this.url = url;
        this.sortKey = sortKey;
        this.directory = directory;
    }
}

final class FilePage {
    final FileEntry[] entries;
    final boolean hasMore;
    final String nextKey;

    FilePage(FileEntry[] entries, boolean hasMore, String nextKey) {
        this.entries = entries;
        this.hasMore = hasMore;
        this.nextKey = nextKey;
    }
}

final class FileSelection {
    final String name;
    final String url;
    final long size;

    FileSelection(String name, String url, long size) {
        this.name = name;
        this.url = url;
        this.size = size;
    }
}

final class FilePageBuilder {
    private FilePageBuilder() {}

    static FilePage roots(Enumeration roots, String afterKey, int limit) throws IOException {
        return build(roots, "file:///", afterKey, limit, true);
    }

    static FilePage directory(
            Enumeration names, String directoryUrl, String afterKey, int limit)
            throws IOException {
        if (directoryUrl == null || !directoryUrl.endsWith("/")) {
            throw new IOException("invalid directory URL");
        }
        return build(names, directoryUrl, afterKey, limit, false);
    }

    private static FilePage build(
            Enumeration names,
            String baseUrl,
            String afterKey,
            int limit,
            boolean roots)
            throws IOException {
        if (names == null) {
            throw new IOException("file system returned no directory listing");
        }
        if (limit < 1 || limit > 128) {
            throw new IOException("invalid file page size");
        }
        FileEntry[] selected = new FileEntry[limit + 1];
        int count = 0;
        while (names.hasMoreElements()) {
            Object raw = names.nextElement();
            if (!(raw instanceof String)) {
                continue;
            }
            FileEntry entry = entry((String) raw, baseUrl, roots);
            if (entry == null || (afterKey != null && entry.sortKey.compareTo(afterKey) <= 0)) {
                continue;
            }
            int insertAt = count;
            if (insertAt > limit) {
                insertAt = limit;
            }
            while (insertAt > 0
                    && entry.sortKey.compareTo(selected[insertAt - 1].sortKey) < 0) {
                if (insertAt <= limit) {
                    selected[insertAt] = selected[insertAt - 1];
                }
                insertAt--;
            }
            if (insertAt <= limit) {
                selected[insertAt] = entry;
                if (count <= limit) {
                    count++;
                }
            }
        }

        boolean hasMore = count > limit;
        int resultCount = hasMore ? limit : count;
        FileEntry[] result = new FileEntry[resultCount];
        System.arraycopy(selected, 0, result, 0, resultCount);
        String nextKey =
                hasMore && resultCount != 0 ? result[resultCount - 1].sortKey : null;
        return new FilePage(result, hasMore, nextKey);
    }

    private static FileEntry entry(String rawName, String baseUrl, boolean root) {
        if (rawName == null || rawName.length() == 0) {
            return null;
        }
        boolean directory = root || rawName.endsWith("/");
        String name =
                directory && rawName.length() > 1
                        ? rawName.substring(0, rawName.length() - 1)
                        : rawName;
        if (name.length() == 0
                || ".".equals(name)
                || "..".equals(name)
                || name.indexOf('/') >= 0
                || name.indexOf('\\') >= 0) {
            return null;
        }
        if (!directory && !endsWithIgnoreCase(name, ".wasm")) {
            return null;
        }
        String sortKey =
                (directory ? "0" : "1") + name.toLowerCase() + '\u0000' + name;
        return new FileEntry(name, baseUrl + rawName, sortKey, directory);
    }

    static boolean endsWithIgnoreCase(String value, String suffix) {
        if (value.length() < suffix.length()) {
            return false;
        }
        return value.regionMatches(
                true, value.length() - suffix.length(), suffix, 0, suffix.length());
    }
}

final class FileSystemAccessFactory {
    private static final String FILE_CONNECTION =
            "javax.microedition.io.file.FileConnection";
    private static final String FILE_REGISTRY =
            "javax.microedition.io.file.FileSystemRegistry";
    private static final String IMPLEMENTATION = "w4me.midp.Jsr75FileSystem";

    private FileSystemAccessFactory() {}

    static boolean isAvailable() {
        try {
            Class.forName(FILE_CONNECTION);
            Class.forName(FILE_REGISTRY);
            Class.forName(IMPLEMENTATION);
            return true;
        } catch (Throwable unavailable) {
            return false;
        }
    }

    static FileSystemAccess create() throws IOException {
        if (!isAvailable()) {
            throw new IOException("local file browser is not available");
        }
        try {
            return (FileSystemAccess) Class.forName(IMPLEMENTATION).newInstance();
        } catch (Throwable failure) {
            throw new IOException("cannot start local file browser: " + failure.toString());
        }
    }
}
