using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Linq;
using System.Text;
using System.Text.Json;
using System.Threading.Tasks;

namespace ModLoader
{
    public  class StorageHelper
    {
        public static StorageHelper instance { get; private set; }
        public StorageHelper()
        {
            instance = this;
        }

        public class ServerInfo
        {
            public string Address { get; set; }
            public string Nickname { get; set; }
            public string Username { get; set; }
            public int Port{ get; set; }
        }


        public Dictionary<string, ServerInfo> GetServers()
        {
            var json = Initra.Properties.Settings.Default.storedServers;

            if (!string.IsNullOrWhiteSpace(json))
            {
                try { return JsonSerializer.Deserialize<Dictionary<string, ServerInfo>>(json); }
                catch { return new(); }
            }

            return null;
        }

        public void SaveServers(Dictionary<string, ServerInfo> serverInfo) 
        {
            Initra.Properties.Settings.Default.storedServers = JsonSerializer.Serialize<Dictionary<string, ServerInfo>>(serverInfo);
            Initra.Properties.Settings.Default.Save();
            Initra.Properties.Settings.Default.Reload();
        }

        public bool SaveServer(string nickname, string address, string username, int port = 22)
        {
            try
            {
                Dictionary<string, ServerInfo> SavedServers = GetServers();

                // we dont check if it exists, we overwrite it.
                SavedServers[$"{username}@{address}"] = new ServerInfo
                {
                    Address = address,
                    Nickname = nickname,
                    Username = username,
                    Port = port
                };

                SaveServers(SavedServers);

                return true;
            }
            catch (Exception ex) { 
                Debug.WriteLine(ex.Message);

                return false;
            }
        }

        public void DeleteServer(string address)
        {
            Dictionary<string, ServerInfo> SavedServers = GetServers();

            if (SavedServers.ContainsKey(address))
            {
                SavedServers.Remove(address);
            }

            SaveServers(SavedServers);
        }
    }
}
