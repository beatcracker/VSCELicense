using Microsoft.Deployment.WindowsInstaller;
using System;
using System.Text;
//using System.IO;
using System.Windows.Forms;
using WixSharp;
using WixSharp.CommonTasks;
using WixSharp.Forms;
using Microsoft.Win32.TaskScheduler;


namespace VSCELicense_WixSharpInstaller
{
    class Program
    {
        static Project createProject(Platform pt)
        {
            var project = new ManagedProject()
            {

                UI = WUI.WixUI_ProgressOnly,
                SourceBaseDir = @"..\..",
             
              
        };

            //project.BeforeInstall += Project_BeforeInstall;
            //project.AfterInstall += Project_AfterInstall;

            string shortArch;
            string longArch;
            switch (pt)
            {
                case Platform.x86:
                 shortArch = "x86";
                    longArch = "32-bit";                 
                    project.GUID = new Guid("1BB13514-397A-478E-82BA-117A9C276FD4");
                    break;
                case Platform.x64:
                    shortArch = "x64";
                    longArch = "64-bit";                
                    project.GUID = new Guid("2094AF85-9036-45A2-AADB-E44B935098E9");
                    break;
                default:
                    throw new NotImplementedException("Unsupported architecture");
            };

            project.Name = $"VSCE License Reset ({longArch})";
            project.OutFileName = $"VSCE_License_Reset_{shortArch}";
            project.Properties = new[]
         {
                    new Property("ShortArch",shortArch) { Hidden = true},
                    new Property("LongArch",longArch) { Hidden = true}
                };


            project.Dirs = new Dir[]
              {
              new Dir(@"%ProgramFiles%\WindowsPowershell\Modules",
                new WixSharp.File("VSCELicense.psd1"),
                new WixSharp.File("VSCELicense.psm1"),
                new WixSharp.File("License"),
                new File("Readme.md")
               )
      
            };

            return project;
        }

        private static void Project_AfterInstall(SetupEventArgs e)
        {
            string shortArch = e.Data["ShortArch"];
            string longArch = e.Data["LongArch"];
            if (e.IsInstalling)
            {
                TaskService ts = TaskService.Instance;
                TaskFolder tf = ts.RootFolder.CreateFolder("VSCELicense", exceptionOnExists: false);
                TaskDefinition td = ts.NewTask();
                ExecAction ea = new ExecAction();
                ea.Path = "powershell.exe";
                string PSCommand = @"
Import-Module VSCELicense;
@('VS2019','VS2017') | ForEach-Object {
    try {
   
        Get-VSCELicenseExpirationDate -Version `$_;
        Set-VSCELicenseExpirationDate -Version `$_;       
    } catch {
        Write-Verbose ""`$_ seems not be installed""
    }
}
";
                ea.Arguments = $"-command \"{PSCommand}\"";
                td.Actions.Add(ea);
                DailyTrigger dt = new DailyTrigger();
                dt.StartBoundary = DateTime.Today + TimeSpan.FromHours(1);  // 1am 
                td.Triggers.Add(dt);
                tf.RegisterTaskDefinition($"VSCELicense_{shortArch}", td);
            }
        }

        private static void Project_BeforeInstall(SetupEventArgs e)
        {
            string shortArch = e.Data["ShortArch"];
            string longArch = e.Data["LongArch"];
           if (e.IsUninstalling)
            {
                TaskService ts = TaskService.Instance;
                TaskFolder tf = ts.GetFolder("VSCELicense");
                if (null != tf)
                {
                    tf.DeleteTask($"VSCELicense_{shortArch}",false);
                }
            }
        }

        static void Main()
        {

           
            var projectx86 = createProject(Platform.x86);
           
            Compiler.BuildMsi(projectx86);

            var projectx64= createProject(Platform.x64);
           
     

            Compiler.BuildMsi(projectx64);
        }
        

        }


  
}