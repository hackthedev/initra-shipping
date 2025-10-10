let servers = {};

function addServerActions(element){
    let actionButtonAddServer = document.createElement('div');
    actionButtonAddServer.classList.add('action-button');
    actionButtonAddServer.innerHTML = '&#10010; Add Server';

    actionButtonAddServer.onclick = function(){
        addServer()
    }

    element.appendChild(actionButtonAddServer);
}

async function populateServers(){
    if(!isLauncher()) return;

    let savedServers = await Initra().GetServers();
    servers = JSON.parse(savedServers);
    return true;
}

async function displayServers(container){
    if(!container) return;

    if(!await populateServers()) return;

    setTitle("Servers")

    container.innerHTML = `
        <div class="actions"></div>
        <div class='app-container'></div>`;

    addServerActions(container.querySelector(".actions"));

    for(let serverData in servers){
        let server = servers[serverData];

        let serverElement = document.createElement("div");
        serverElement.classList.add("app");
        serverElement.classList.add("server");
        serverElement.id = `server_${server.Nickname}`;

        serverElement.insertAdjacentHTML("beforeend",
            `<div class="right">
                <div class="title">${server.Nickname}</div>
                <div class="author">${server.Username}@${server.Address}</div>
            </div>

            <div class="buttons"></div>`
        );

        /*
        let editButton = document.createElement("div");
        editButton.classList.add("install");
        editButton.innerHTML = "&#9998; Edit";
        editButton.onclick = async () => {
            // to be implemented
        }*/

        let deleteButton = document.createElement("div");
        deleteButton.classList.add("install");
        deleteButton.classList.add("delete");
        deleteButton.innerHTML = "&#x1F5D1; Delete";
        deleteButton.onclick = async () => {
            deleteServer(`${server.Username}@${server.Address}`);
        }

        //serverElement.querySelector(".buttons").appendChild(editButton);
        serverElement.querySelector(".buttons").appendChild(deleteButton);
        container.querySelector(".app-container").insertAdjacentElement("beforeend", serverElement);
    }
}

async function promptString(type, title, text) {
    return new Promise((resolve) => {
        let inputHTML = "";

        switch (type) {
            case "string":
                inputHTML = `
                    <input class="prompt-input" type="text" name="value" placeholder="Enter text">
                `;
                break;

            case "number":
                inputHTML = `
                    <input class="prompt-input" type="number" name="value" placeholder="Enter number">
                `;
                break;

            case "boolean":
                inputHTML = `
                    <label><input type="radio" name="value" value="true"> Yes</label><br>
                    <label><input type="radio" name="value" value="false"> No</label>
                `;
                break;

            case "password":
                inputHTML = `
                    <input class="prompt-input" type="password" name="value" placeholder="Enter password">
                `;
                break;

            default:
                inputHTML = `
                    <input class="prompt-input" type="text" name="value" placeholder="Enter value">
                `;
                break;
        }

        customPrompts.showPrompt(
            title,
            `
            <p>${text}</p>
            <div class="prompt-form-group">
                ${inputHTML}
            </div>
            `,
            async (values) => {
                let val = "";

                if (type === "boolean") {
                    const checked = document.querySelector('input[name="value"]:checked');
                    val = checked ? checked.value : "false";
                } else {
                    val = values?.value ?? "";
                }

                if(isLauncher()){
                    await Initra().ResolveFromJS(val)
                    resolve(val);
                }
                else{
                    resolve(val);
                }

            },
            ["OK", null],
            null,
            400
        );
    });
}


async function promptPassword(){
   return await promptString("password", "SSH Password",
       "Please enter your password.<br>" +
       "It's required for the installation and wont be saved.")
}

async function pickServer(){
    if(!await populateServers()) return;
    let serverArray = Object.values(servers);

    return new Promise((resolve, reject) => {
        customPrompts.showPrompt(
            "Pick a server",
            `
        <div class="prompt-form-group" id="loginNameContainer">
            <select name="address" class="prompt-select">
                ${serverArray.map(server =>
                `<option value="${server.Username}@${server.Address}">${server.Nickname} - ${server.Username}@(${server.Address})</option>`
            ).join("")}
            </select>
        </div>
        `,
            async (values) => {
                console.log(values);
                resolve(values);
            },
            ["Select", null],
            null,
            400
        );
    });
}

async function deleteServer(address){
    customPrompts.showConfirm(
        `Do you want to delete the server ${address}?`,
        [["Yes", "success"], ["No", "error"]],
        async (selectedOption) => {
            if (selectedOption == "yes") {
                await Initra().DeleteServer(address)
                loadServers();
            }
        }
    )
}

function addServer(){
    customPrompts.showPrompt(
        "Add a server",
        `
        <div class="prompt-form-group" id="loginNameContainer">
            <label class="prompt-label" for="nickname">Nickname</label>
            <input class="prompt-input" name="nickname"><br><br>
            
            <label class="prompt-label" for="address">Address</label>
            <input class="prompt-input" name="address"><br><br>
            
            <label class="prompt-label" for="username">Username</label>
            <input class="prompt-input" name="username"><br><br>
            
            <label class="prompt-label" for="port">Port</label>
            <input class="prompt-input" type="number" name="port" value="22">
        </div>
            `,
        async (values) => {
            console.log(values);

            if(!isLauncher()) return;

            if(!values?.nickname){
                values.nickname = "New Server";
            }

            if(!values?.address){
                return;
            }

            if(!values?.username){
                return;
            }

            await Initra().SaveServer(values.nickname, values.address, values.username, values.port)
            loadServers();
        },
        ["Select", null],
        null,
        400

    );
}