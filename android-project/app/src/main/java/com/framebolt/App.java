package com.framebolt;

import org.libsdl.app.SDLActivity;

/**
 * A sample wrapper class that just calls SDLActivity
 */

public class App extends SDLActivity {
    @Override
    protected String[] getLibraries() {
        // Do NOT load SDL3, since it's statically linked into libmain.so
        return new String[] {
            "main"
        };
    }
}
