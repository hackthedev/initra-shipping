using System.IO.Pipes;

namespace ModLoader
{
    static class Program
    {
        [STAThread]
        static void Main(string[] args)
        {
            Initra.Properties.Settings.Default.Upgrade();
            Initra.Properties.Settings.Default.Save();
            Initra.Properties.Settings.Default.Reload();


            bool isNewInstance;
            using (Mutex mutex = new Mutex(true, "MySuperSickAppMutexForInitra", out isNewInstance))
            {
                if (isNewInstance)
                {
                    ApplicationConfiguration.Initialize();
                    Application.Run(new Form1(args.Length > 0 ? args[0] : null));
                }
                else
                {
                    // send uri to first instance
                    if (args.Length > 0)
                        SendUriToExistingInstance(args[0]);
                }
            }
        }

        static void SendUriToExistingInstance(string uri)
        {
            try
            {
                using (NamedPipeClientStream pipeClient = new NamedPipeClientStream(".", "MySuperSickAppPipeForInitra", PipeDirection.Out))
                {
                    pipeClient.Connect(1000); 
                    using (StreamWriter writer = new StreamWriter(pipeClient))
                    {
                        writer.AutoFlush = true;
                        writer.WriteLine(uri);
                    }
                }
            }
            catch (Exception ex)
            {
                MessageBox.Show("Could not communicate with running instance: " + ex.Message);
            }
        }
    }

}