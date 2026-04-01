_: {
  flake.homeModules.startpage = {config, ...}: let
    c = config.colors;
  in {
    home.file."dotfiles/startpage/index.html".text = ''
      <!DOCTYPE html>
      <html lang="en">
      <head>
      <meta charset="utf-8">
      <title>~</title>
      <style>
      :root {
        --bg: ${c.bg};
        --mantle: ${c.mantle};
        --surface0: ${c.surface0};
        --surface1: ${c.surface1};
        --subtext0: ${c.subtext0};
        --text: ${c.text};
        --accent: ${c.accent};
        --red: ${c.red};
      }

      * { margin: 0; padding: 0; box-sizing: border-box; }

      body {
        height: 100vh;
        background: var(--bg);
        color: var(--text);
        font-family: 'JetBrainsMono Nerd Font', 'JetBrains Mono', monospace;
        display: grid;
        grid-template-rows: 1fr auto;
        place-items: center;
        opacity: 0;
        animation: arrive 600ms ease-out 100ms forwards;
      }

      @keyframes arrive {
        from { opacity: 0; transform: translateY(8px); }
        to { opacity: 1; transform: translateY(0); }
      }

      .card {
        display: flex;
        width: min(82vw, 1100px);
        min-height: 340px;
        background: var(--mantle);
        border-radius: 12px;
        box-shadow: 0 8px 32px rgba(0,0,0,0.6);
        overflow: hidden;
      }

      .art {
        width: 240px;
        min-height: 100%;
        flex-shrink: 0;
        background: var(--surface0);
        background-size: cover;
        background-position: center;
        position: relative;
        cursor: pointer;
        transition: filter 0.3s;
      }
      .art:hover { filter: brightness(1.1); }
      .art-counter {
        position: absolute;
        bottom: 8px;
        right: 10px;
        font-size: 0.6rem;
        color: var(--subtext0);
        opacity: 0.6;
      }

      .content {
        flex: 1;
        padding: 28px 36px;
        display: flex;
        flex-direction: column;
        justify-content: center;
        gap: 6px;
      }

      .greeting {
        font-size: 1.35rem;
        font-weight: 700;
        font-style: italic;
        letter-spacing: -0.02em;
      }
      .greeting .name { color: var(--accent); }

      .clock {
        font-size: 0.75rem;
        color: var(--subtext0);
        margin-bottom: 4px;
        letter-spacing: 0.04em;
      }

      .search {
        position: relative;
        margin: 8px 0 14px;
      }
      .search label {
        position: absolute;
        left: 0;
        top: 50%;
        transform: translateY(-50%);
        color: var(--accent);
        font-size: 0.85rem;
        pointer-events: none;
      }
      .search input {
        width: 100%;
        padding: 6px 0 6px 20px;
        background: transparent;
        border: none;
        border-bottom: 1px solid var(--surface0);
        color: var(--text);
        font: inherit;
        font-size: 0.85rem;
        outline: none;
        transition: border-color 0.2s;
      }
      .search input:focus { border-bottom-color: var(--accent); }
      .search input::placeholder { color: var(--surface1); transition: opacity 0.2s; }
      .search input:focus::placeholder { opacity: 0; }

      .links { display: flex; gap: 32px; flex-wrap: wrap; }

      .category h2 {
        font-size: 0.7rem;
        font-weight: 700;
        color: var(--accent);
        text-transform: uppercase;
        letter-spacing: 0.1em;
        margin-bottom: 6px;
      }

      .category ul { list-style: none; display: flex; flex-direction: column; gap: 3px; }

      .category a {
        color: var(--subtext0);
        text-decoration: none;
        font-size: 0.72rem;
        transition: color 0.15s;
        letter-spacing: 0.01em;
      }
      .category a:hover { color: var(--accent); }

      footer {
        padding: 10px 20px 14px;
        width: 100%;
        display: flex;
        justify-content: center;
        gap: 16px;
        font-size: 0.55rem;
        color: var(--surface1);
      }
      footer a {
        color: var(--subtext0);
        text-decoration: none;
        cursor: pointer;
        transition: color 0.15s;
      }
      footer a:hover { color: var(--accent); }
      </style>
      </head>
      <body>

      <main>
        <div class="card">
          <div class="art" id="art" onclick="cycleImage(1)" title="click to cycle">
            <span class="art-counter" id="art-counter"></span>
          </div>
          <div class="content">
            <div class="greeting">
              <span id="greeting"></span> <span class="name">fbad</span>
            </div>
            <div class="clock" id="clock"></div>

            <form class="search" action="https://duckduckgo.com" method="get" autocomplete="off">
              <label for="q">&gt;</label>
              <input autofocus id="q" name="q" placeholder="search" type="search">
            </form>

            <nav class="links">
              <div class="category">
                <h2>daily</h2>
                <ul>
                  <li><a href="https://gmail.com">gmail</a></li>
                  <li><a href="https://calendar.google.com">calendar</a></li>
                  <li><a href="https://github.com">github</a></li>
                  <li><a href="https://youtube.com">youtube</a></li>
                </ul>
              </div>
              <div class="category">
                <h2>nix</h2>
                <ul>
                  <li><a href="https://search.nixos.org/packages">packages</a></li>
                  <li><a href="https://search.nixos.org/options">options</a></li>
                  <li><a href="https://home-manager-options.extranix.com">home-manager</a></li>
                  <li><a href="https://wiki.nixos.org">wiki</a></li>
                </ul>
              </div>
              <div class="category">
                <h2>security</h2>
                <ul>
                  <li><a href="https://www.cve.org">cve.org</a></li>
                  <li><a href="https://www.exploit-db.com">exploit-db</a></li>
                  <li><a href="https://hackerone.com">hackerone</a></li>
                  <li><a href="https://nvd.nist.gov">nvd</a></li>
                </ul>
              </div>
              <div class="category">
                <h2>media</h2>
                <ul>
                  <li><a href="https://open.spotify.com">spotify</a></li>
                  <li><a href="https://music.youtube.com">yt music</a></li>
                  <li><a href="https://reddit.com">reddit</a></li>
                  <li><a href="https://news.ycombinator.com">hackernews</a></li>
                </ul>
              </div>
            </nav>
          </div>
        </div>
      </main>

      <footer>
        <a onclick="cycleImage(-1)">&lt; prev</a>
        <span>~</span>
        <a onclick="cycleImage(1)">next &gt;</a>
      </footer>

      <script>
      (function() {
        function getGreeting() {
          const h = new Date().getHours();
          if (h >= 5 && h < 12) return 'good morning,';
          if (h >= 12 && h < 17) return 'good afternoon,';
          if (h >= 17 && h < 22) return 'good evening,';
          return 'late night,';
        }
        document.getElementById('greeting').textContent = getGreeting();

        function tick() {
          const now = new Date();
          const days = ['sun','mon','tue','wed','thu','fri','sat'];
          const months = ['jan','feb','mar','apr','may','jun','jul','aug','sep','oct','nov','dec'];
          const d = days[now.getDay()];
          const m = months[now.getMonth()];
          const date = now.getDate();
          const h = String(now.getHours()).padStart(2,'0');
          const min = String(now.getMinutes()).padStart(2,'0');
          const s = String(now.getSeconds()).padStart(2,'0');
          document.getElementById('clock').textContent = d + ' ' + m + ' ' + date + '  ' + h + ':' + min + ':' + s;
        }
        tick();
        setInterval(tick, 1000);

        // add image filenames to this array as you add them to ~/dotfiles/startpage/img/
        const imageFiles = [];
        let imgIndex = 0;

        function showImage() {
          if (imageFiles.length === 0) return;
          const art = document.getElementById('art');
          art.style.backgroundImage = 'url(img/' + imageFiles[imgIndex] + ')';
          document.getElementById('art-counter').textContent = (imgIndex + 1) + '/' + imageFiles.length;
        }

        window.cycleImage = function(dir) {
          if (imageFiles.length === 0) return;
          imgIndex = (imgIndex + dir + imageFiles.length) % imageFiles.length;
          showImage();
        };

        if (imageFiles.length > 0) showImage();
      })();
      </script>
      </body>
      </html>
    '';
  };
}
