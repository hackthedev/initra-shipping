const customPrompts = new Prompt();

let apps = {}

function Initra() {
    return window.chrome.webview.hostObjects.initra;
}

function isLauncher() {
    return !!window.chrome?.webview?.hostObjects?.initra;
}

async function setupAppPackageFilter(container, includePackages){
    let showPackagesElement = container.querySelector("#appShowPackages");
    if(!showPackagesElement) {
        console.error("Couldnt find show package option element in apps")
        return;
    }

    showPackagesElement.checked = includePackages;
    showPackagesElement.addEventListener("change", async (event) => {
        const checked = showPackagesElement.checked;
        await displayApps(container, false, checked);
    })
}

async function searchAppsAndPackages(container, includePackages){
    let searchbar = container.querySelector("#appSearchInput");
    if(!searchbar) {
        console.error("Couldnt find search bar element in apps")
        return;
    }

    searchbar.addEventListener("input", async (event) => {
        await displayApps(container, false, includePackages, searchbar.value);
    })
}

function setAppSearchbarCursor(container){
    if(!container){
        console.error("Couldnt find container element in apps for search bar cursor")
        return;
    }

    let searchbar = container.querySelector("#appSearchInput");
    if (searchbar) {
        searchbar.focus();
        const val = searchbar.value;
        searchbar.setSelectionRange(val.length, val.length);
    }
}

function renderTestApp(appJson){
    displayApps(document.getElementById("content"), false, true, null, JSON.parse(appJson));
}

async function displayApps(container, refresh = true, includePackages = false, search = null, customApps = null){
    if(!container) return;

    container.innerHTML = `
        <div class='app-container'>
            <div id="app-filter">
                <input type="text" id="appSearchInput" placeholder="Search anything..." value="${search ? search : ""}">
                
                <label for="appShowPackages">Show Packages</label>
                <input type="checkbox" id="appShowPackages">
            </div>
        </div>
    `;

    await setupAppPackageFilter(container, includePackages);
    await searchAppsAndPackages(container, includePackages);

    setTitle("Apps")

    // only available in the launcher
    // maybe turn it into a website in the future
    // but domain costs money etc and im broke ;-;
    if(!isLauncher()) return
    if(refresh) apps = JSON.parse(await Initra().GetApps());

    let appsJson = customApps ? customApps : apps;
    if (!Array.isArray(appsJson)) appsJson = [appsJson];

    for(let githubAppData of appsJson){

        // get github raw data to parse app.json file from app
        let app = customApps ? customApps : JSON.parse(await Initra().GetAppInfo(githubAppData?.name))
        console.log(app)
        let appType = app?.type;

        if(appType && appType !== "app" && includePackages === false){
            setAppSearchbarCursor(container);
            continue
        }

        if (search !== null && search.trim().length > 0) {
            const s = search.toLowerCase();
            const inTitle = app.title?.toLowerCase().includes(s);
            const inDesc  = app.description?.toLowerCase().includes(s);
            const inAuth  = app.author?.toLowerCase().includes(s);

            setAppSearchbarCursor(container);
            if (!inTitle && !inDesc && !inAuth) continue;
        }


        let appElement = document.createElement("div");
        appElement.classList.add("app");
        appElement.id = `app_${app?.id}`;

        appElement.insertAdjacentHTML("beforeend",
            `<div class="left">
                ${app?.image ? `<div class="image" style="background-image: url('${app?.image}')"></div>` : ""}
            </div>

            <div class="right">
                <div class="title">${app.title}</div>
                <div class="author">by ${app.author}</div>
                <div class="description">${app.description}</div>
            </div>`
        );

        let installButton = document.createElement("div");
        installButton.classList.add("install");
        installButton.textContent = "Install";

        installButton.onclick = async () => {
            let server = await pickServer();
            let password = await promptPassword();
            let serverData = servers[server.address];

            await Initra().InstallApp(
                app.id,
                serverData.Address,
                serverData.Username,
                password,
                serverData.Port
            )
        }

        appElement.querySelector(".right").appendChild(installButton);
        container.querySelector(".app-container").insertAdjacentElement("beforeend", appElement);

        setAppSearchbarCursor(container);
    }
}

function appendToTtyLog(text) {
    const ttyLog = document.getElementById("ttyOutput");
    if (!ttyLog) return;

    let safe = String(text)
        .replace(/\x1B\[[0-9;]*[A-Za-z]/g, "")
        .replace(/\r\n/g, "\n")
        .replace(/\r/g, "\n")
        .replace(/\n{2,}/g, "\n")
        .replace(/\n/g, "<br>")
        .replace(/(<br>\s*){2,}/g, "<br>")
        .trim();

    if(ttyLog.innerText.includes("initra://install/done")){
        let progressContainer = document.querySelector("#promptContainer #installLoadingContainer")
        progressContainer.innerHTML =
        `
            <input 
                type="button" 
                value="Installation complete!" 
                class="prompt-button submit" 
                style="text-align: center" 
                onclick="customPrompts.closePrompt()"
            >
        `;
    }

    if(ttyLog.innerText.includes("initra://install/error")){
        let progressContainer = document.querySelector("#promptContainer #installLoadingContainer")
        progressContainer.innerHTML =
            `
            <input 
                type="button" 
                value="Installation failed :/" 
                class="prompt-button submit" 
                style="text-align: center; background-color: indianred;" 
                onclick="customPrompts.closePrompt()"
            >
        `;
    }

    const validator = document.createElement("p");
    validator.innerHTML = safe;
    if (validator.innerText.trim().length <= 0) return;

    ttyLog.insertAdjacentHTML("beforeend", safe);
    ttyLog.scrollTop = ttyLog.scrollHeight;
}


async function showInstallLog(title){

    let promptContainer = document.querySelector("#promptContainer");
    if(promptContainer){
        if(promptContainer.style.display !== "none"){
            return; // prompt already shown
        }
    }

    customPrompts.showPrompt(
        `Installing ${title}`,
        `


        <div class="form-group">
            <div id="ttyOutput" style="
                background-color: black;
                color: white;
                font-family: Consolas, serif;
                font-size: 10px;
                margin: 20px 0;
                display: block;
                
                width: 80vw;              
                height: 50vh;
                overflow: auto;
                
                
                padding: 10px;
                border-radius: 8px;
            ">
            
            </div>
        </div>

        <div style="margin-bottom: 10px;" id="installLoadingContainer">
            <div style="font-size: 13px;margin-bottom: 6px;"><i>Installing</i>...</div>
            <div id="powLoadingBar" style="
                width: 100%;
                height: 4px;
                background: #ccc;
                overflow: hidden;
                border-radius: 4px;
                position: relative;
            ">
                <div id="powLoadingBarInner" style="
                    height: 100%;
                    width: 30%;
                    background: linear-gradient(90deg,rgb(17, 184, 245),rgb(17, 184, 245));
                    position: absolute;
                    left: 0;
                    animation: powMove 2s linear infinite;
                "></div>
            </div>
        </div>

        <style>
        
        #ttyOutput p{
            margin: 2px 0;
        }
        
        @keyframes powMove {
            0% { left: -30%; }
            50% { left: 100%; }
            100% { left: -30%; }
        }
        </style>
  
        `,
        null, // all null cauz info
        null,
        null,
        null,
        null,
        null,
        true,
        false
    );
}