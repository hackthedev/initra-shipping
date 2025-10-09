using Renci.SshNet;
using Renci.SshNet.Common;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Text.RegularExpressions;
using System.Threading.Tasks;

namespace Initra
{
    public class SshHelper : IDisposable
    {
        private SshClient _client;
        private ShellStream _shell;
        private bool _isRunning;

        public event Action<string> OnOutput;
        public event Action<string> OnError;

        public static SshHelper Instance { get; private set; }

        public SshHelper()
        {
            Instance = this;
        }

        public async Task Open(string host, int port, string username, string password)
        {
            await Task.Run(() =>
            {
                try
                {
                    _client = new SshClient(host, port, username, password);
                    _client.Connect();

                    var termModes = new Dictionary<TerminalModes, uint>();
                    _shell = _client.CreateShellStream("xterm", 80, 24, 800, 600, 1024, termModes);

                    _isRunning = true;
                    Task.Run(ReadLoop);

                    OnOutput?.Invoke($"[SSH] Connected to {host}:{port}");
                }
                catch (Exception ex)
                {
                    OnError?.Invoke($"SSH connection error: {ex.Message}");
                }
            });
        }

        private void ReadLoop()
        {
            try
            {
                while (_isRunning && _client?.IsConnected == true && _shell != null)
                {
                    if (_shell.DataAvailable)
                    {
                        string text = _shell.Read();
                        if (!string.IsNullOrEmpty(text))
                        {
                            // fix some stuff
                            text = Regex.Replace(text, @"\x1B\[[0-9;]*[BEF]", "\n"); 
                            text = Regex.Replace(text, @"\x1B\[K", "");
                            text = Regex.Replace(text, @"\x1B\[[0-9;]*[A-Za-z]", ""); 
                            text = text.Replace("\r", "\n");
                            OnOutput?.Invoke(text);
                        }

                    }
                    else
                    {
                        Task.Delay(50).Wait();
                    }
                }

                OnOutput?.Invoke("[SSH] Connection closed.");
            }
            catch (Exception ex)
            {
                OnError?.Invoke($"SSH read error: {ex.Message}");
            }
        }

        public void SendInput(string input)
        {
            if (_shell?.CanWrite == true)
                _shell.WriteLine(input);
            else
                OnError?.Invoke("[SSH] Shell is not writable.");
        }

        public async Task Close()
        {
            await Task.Run(() =>
            {
                try
                {
                    _isRunning = false;
                    _shell?.Close();
                    _client?.Disconnect();
                    OnOutput?.Invoke("[SSH] Disconnected.");
                }
                catch (Exception ex)
                {
                    OnError?.Invoke($"SSH close error: {ex.Message}");
                }
            });
        }

        public void Dispose()
        {
            _isRunning = false;
            _shell?.Dispose();
            _client?.Dispose();
        }
    }
}
