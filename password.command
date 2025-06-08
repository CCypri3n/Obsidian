#!/bin/bash

cd "$(dirname "$0")"

PASSWORD_CODE='// --- PASSWORD PROTECTION (HASHED) ---
(function() {
    const PASSWORD_HASH = "a686b1bef08ea17f5fed46c5aa49d1d9e958620a1dd2ae7df06ac615b1b13a79";

    // Helper: SHA-256 hash as hex
    async function sha256(str) {
        const buf = await crypto.subtle.digest("SHA-256", new TextEncoder().encode(str));
        return Array.from(new Uint8Array(buf)).map(x => x.toString(16).padStart(2, "0")).join("");
    }

    // Overlay UI
    const overlay = document.createElement("div");
    overlay.style.position = "fixed";
    overlay.style.zIndex = "99999";
    overlay.style.top = "0";
    overlay.style.left = "0";
    overlay.style.width = "100vw";
    overlay.style.height = "100vh";
    overlay.style.background = "rgba(0,0,0,0.96)";
    overlay.style.display = "flex";
    overlay.style.flexDirection = "column";
    overlay.style.alignItems = "center";
    overlay.style.justifyContent = "center";
    overlay.style.color = "#fff";
    overlay.style.fontFamily = "sans-serif";
    overlay.innerHTML = `
        <div style="background:#222;padding:2em 3em;border-radius:1em;box-shadow:0 0 20px #000;">
            <h2 style="margin-bottom:1em;">Protected</h2>
            <input id="pwinput" type="password" placeholder="Enter password" style="font-size:1.2em;padding:0.5em;border-radius:0.3em;border:none;width:100%;">
            <div id="pwmsg" style="color:#f66;margin-top:1em;min-height:1.5em;"></div>
            <button id="pwbtn" style="margin-top:1em;font-size:1em;padding:0.5em 2em;border-radius:0.3em;border:none;background:#444;color:#fff;cursor:pointer;">Unlock</button>
        </div>
    `;
    document.documentElement.appendChild(overlay);

    async function unlock() {
        const val = document.getElementById("pwinput").value;
        const hash = await sha256(val);
        if (hash === PASSWORD_HASH) {
            overlay.remove();
            sessionStorage.setItem("pwok", "1");
        } else {
            document.getElementById("pwmsg").textContent = "Wrong password!";
        }
    }

    // If already unlocked in this session, skip prompt
    if (sessionStorage.getItem("pwok") === "1") {
        overlay.remove();
    } else {
        document.getElementById("pwbtn").onclick = unlock;
        document.getElementById("pwinput").onkeydown = function(e) {
            if (e.key === "Enter") unlock();
        };
    }
})();
// --- END PASSWORD PROTECTION (HASHED) ---'

# Backup
cp lib/scripts/webpage.js lib/scripts/webpage.js.bak

# Save the password code to a temporary file
TMPFILE=$(mktemp)
echo "$PASSWORD_CODE" > "$TMPFILE"

# Use awk to replace or prepend the block
awk -v codefile="$TMPFILE" '
BEGIN {
    while ((getline line < codefile) > 0) {
        code = (code == "" ? line : code "\n" line)
    }
    close(codefile)
    in_block=0
}
/\/\/ --- PASSWORD PROTECTION \(HASHED\) ---/ { in_block=1; print code; next }
/\/\/ --- END PASSWORD PROTECTION \(HASHED\) ---/ { in_block=0; next }
in_block { next }
1
' lib/scripts/webpage.js.bak > lib/scripts/webpage.js

rm "$TMPFILE"

echo "Password protection code was updated in lib/scripts/webpage.js! A backup was created as lib/scripts/webpage.js.bak."
