using Initra;
using Microsoft.Web.WebView2.WinForms;
using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO.Compression;
using System.Linq;
using System.Runtime.InteropServices;
using System.Text;
using System.Text.Json;
using System.Text.Json.Nodes;
using System.Threading.Tasks;
using System.Transactions;
using static System.Net.Mime.MediaTypeNames;

namespace ModLoader
{
    [ClassInterface(ClassInterfaceType.AutoDual)]
    [ComVisible(true)]
    public class JSBridge
    {

        public static JSBridge instance { get; private set; }

        private TaskCompletionSource<string> waitForJsTcs;
        private TaskCompletionSource<bool> installDoneTcs;

        bool installError = false;


        public JSBridge()
        {
            instance = this;
        }

        public async Task<string> WaitForJS()
        {
            waitForJsTcs = new TaskCompletionSource<string>();
            return await waitForJsTcs.Task;
        }

        public async Task<string> GetBranches(string repo)
        {
            var node = await Form1.githubHelper.GetBranches(repo);
            return node?.ToJsonString() ?? "null";
        }

        public string GetCurrentBranch()
        {
            return Form1.branch;
        }

        public void SetCurrentBranch(string branch)
        {
            Form1.branch = branch;
            Initra.Properties.Settings.Default.branch = branch;
            Initra.Properties.Settings.Default.Save();
            Initra.Properties.Settings.Default.Reload();
        }


        public void ResolveFromJS(string value)
        {
            waitForJsTcs?.TrySetResult(value);
        }

        private async Task WaitForInstallDone()
        {
            installDoneTcs = new TaskCompletionSource<bool>();
            await installDoneTcs.Task;
        }

        private void SignalInstallDone()
        {
            installDoneTcs?.TrySetResult(true);
        }


        public async Task InstallApp(string appName, string ServerAddress, string Username, string Password, int port = 22, bool isDependency = false)
        {
            if (appName == null)
            {
                MessageBox.Show("Missing App Name for installation!", null, MessageBoxButtons.OK, MessageBoxIcon.Error);
                return;
            }

            // only reset error flag on main app install
            if(installError == true && isDependency == false)
            {
                installError = false;
            }


            var ssh = new Initra.SshHelper();

            // open install window
            await Form1.CallJsFunctionSafe("showInstallLog", appName);

            ssh.OnOutput += async (msg) =>
            {
                // if for some reason it wasnt shown anymore, show it again
                await Form1.CallJsFunctionSafe("showInstallLog", appName);

                Debug.WriteLine(msg);

                if (msg.Contains("initra://install/done"))
                {
                    SignalInstallDone();

                    if (!isDependency)
                    {
                        Form1.CallJsFunctionSafe("appendToTtyLog", msg);
                    }
                }
                else
                {
                    Form1.CallJsFunctionSafe("appendToTtyLog", msg);
                }

                if (msg.Contains("initra://ssh/close") && !isDependency)
                {
                    await ssh.Close();
                    Console.WriteLine("Connection closed.");
                }
            };



            ssh.OnError += async (err) =>
            {
                installError = true;
                Debug.WriteLine("ERR: " + err);
                await Form1.CallJsFunctionSafe("appendToTtyLog", $"<font style='color:red;font-weight:bold;'>{err}</font>\n");
                await Form1.CallJsFunctionSafe("appendToTtyLog", $"initra://install/error\n");
                await ssh.Close();
            };

            Debug.WriteLine("Connecting...");
            Form1.CallJsFunctionSafe("appendToTtyLog", $"Connecting to {ServerAddress}:{port} with user {Username}...\n");

            await ssh.Open(ServerAddress, port, Username, Password);
            Debug.WriteLine("Connected!");

            // if we got an error
            if (installError)
            {
                await Form1.CallJsFunctionSafe("appendToTtyLog", "<font style='color:red;font-weight:bold;'>Installation aborted due to an error.</font>\n");
                await Form1.CallJsFunctionSafe("appendToTtyLog", $"initra://install/error\n");
                return;
            }

            // app.json data
            JsonNode jsonData = await Form1.githubHelper.GetAppInfo(appName);

            // check and install dependencies first
            if (jsonData["dependencies"] is JsonArray deps && deps.Count > 0)
            {
                foreach (var depNode in deps)
                {
                    string depName = depNode?.ToString();
                    if (string.IsNullOrWhiteSpace(depName))
                        continue;

                    Debug.WriteLine($"Installing dependency: {depName}");
                    await Form1.CallJsFunctionSafe("appendToTtyLog", $"<br>Installing dependency: {depName}<br>");


                    await InstallApp(depName, ServerAddress, Username, Password, port, true);
                }
            }


            // check arguments
            var arguments = jsonData["args"].AsObject();
            var results = new Dictionary<string, string>();

            foreach (var kvp in arguments)
            {
                string key = kvp.Key;
                var argData = kvp.Value;

                string title = argData["title"]?.ToString();
                string text = argData["text"]?.ToString();
                string type = argData["type"]?.ToString();

                // do js prompt and wait for it to be done
                await Form1.CallJsFunctionSafe("promptString", type, title, text);
                string userInput = await WaitForJS();

                // save result
                results[key] = userInput;
            }

            string argumentString = "";
            foreach (var kvp in results)
            {
                argumentString += $"-{kvp.Key} {kvp.Value} ";
            }


            string scriptLink = Form1.githubHelper.GetAppInstallScriptLink(appName);
            string scriptName = scriptLink.Split('/').Last();


            ssh.SendInput($"wget -O {scriptName} {scriptLink}");
            ssh.SendInput($"bash {scriptName} {argumentString}");

            await WaitForInstallDone();
        }


        public async Task<string> GetApps()
        {
            var node = await Form1.githubHelper.GetAppsJson();
            return node?.ToJsonString() ?? "null";
        }

        public async Task<string> GetAppInfo(string appName)
        {
            var node = await Form1.githubHelper.GetAppInfo(appName);
            return node?.ToJsonString() ?? "null";
        }

        public bool SaveServer(string nickname, string address, string username, int port = 22)
        {
            return Form1.storage.SaveServer(nickname, address, username, port);
        }

        public string GetServers()
        {
            return JsonSerializer.Serialize(Form1.storage.GetServers());
        }

        public void DeleteServer(string address)
        {
            Form1.storage.DeleteServer(address);
        }

        public string GetJsonValue(string json, string key)
        {
            if(json == null) { return null; }

            try
            {
                using JsonDocument doc = JsonDocument.Parse(json);
                if (doc.RootElement.TryGetProperty(key, out JsonElement value))
                {
                    return value.ToString();
                }
            }
            catch (JsonException ex)
            {
                Console.WriteLine("Invalid JSON: " + ex.Message);
            }

            return null;

        }

        public void ShowMessage(string msg)
        {
            MessageBox.Show("JS says: " + msg);
        }

        public string PickPath(string description)
        {
            Logger.Log($"Picking a path..");

            using (var dialog = new FolderBrowserDialog())
            {
                dialog.Description = description;
                DialogResult result = dialog.ShowDialog();

                if (result == DialogResult.OK && !string.IsNullOrWhiteSpace(dialog.SelectedPath))
                {
                    Logger.Log($"Selected Path {dialog.SelectedPath}");
                    return dialog.SelectedPath;
                }
                return null;
            }
        }
    }
}
