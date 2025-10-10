using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace ModLoader
{
    public class Logger
    {
        public static string logPath = Path.Combine(Application.StartupPath, "log.txt");
        public static void Log(string content)
        {
            if(!File.Exists(logPath)) File.WriteAllText(logPath, "");

            File.AppendAllText(logPath, content + Environment.NewLine);
        }

        public static void Clear()
        {
            if (File.Exists(logPath)) File.WriteAllText(logPath, "");
        }
    }
}
