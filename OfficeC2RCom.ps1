$OfficeCOM = @"
using System;
using System.Runtime.InteropServices;

namespace OfficeC2RCom
{
    [ComImport]
    [Guid("90E166F0-D621-4793-BE78-F58008DDDD2A")]
    [InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    internal interface IUpdateNotify2
    {
        [return: MarshalAs(UnmanagedType.U4)]
        uint Download([MarshalAs(UnmanagedType.LPWStr)] string pcwszParameters);

        [return: MarshalAs(UnmanagedType.U4)]
        uint Apply([MarshalAs(UnmanagedType.LPWStr)] string pcwszParameters);

        [return: MarshalAs(UnmanagedType.U4)]
        uint Cancel();

        [return: MarshalAs(UnmanagedType.U4)]
        uint status(out UPDATE_STATUS_REPORT pUpdateStatusReport);

        [return: MarshalAs(UnmanagedType.U4)]
        uint GetBlockingApps(out string AppsList);

        [return: MarshalAs(UnmanagedType.U4)]
        uint GetOfficeDeploymentData(int dataType, string pcwszName, out string OfficeData);

    }

    [ComImport]
    [Guid("52C2F9C2-F1AC-4021-BF50-756A5FA8DDFE")]
    internal class UpdateNotifyObject2 { }

    [StructLayout(LayoutKind.Sequential)]
    internal struct UPDATE_STATUS_REPORT
    {
        public UPDATE_STATUS status;
        public uint error;
        [MarshalAs(UnmanagedType.BStr)] public string contentid;
    }

    internal enum UPDATE_STATUS
    {
        eUPDATE_UNKNOWN = 0,
        eDOWNLOAD_PENDING,
        eDOWNLOAD_WIP,
        eDOWNLOAD_CANCELLING,
        eDOWNLOAD_CANCELLED,
        eDOWNLOAD_FAILED,
        eDOWNLOAD_SUCCEEDED,
        eAPPLY_PENDING,
        eAPPLY_WIP,
        eAPPLY_SUCCEEDED,
        eAPPLY_FAILED
    }

    internal enum UPDATE_ERROR_CODE
    {
        eOK = 0,
        eFAILED_UNEXPECTED,
        eTRIGGER_DISABLED,
        ePIPELINE_IN_USE,
        eFAILED_STOP_C2RSERVICE,
        eFAILED_GET_CLIENTUPDATEFOLDER,
        eFAILED_LOCK_PACKAGE_TO_UPDATE,
        eFAILED_CREATE_STREAM_SESSION,
        eFAILED_PUBLISH_WORKING_CONFIGURATION,
        eFAILED_DOWNLOAD_UPGRADE_PACKAGE,
        eFAILED_APPLY_UPGRADE_PACKAGE,
        eFAILED_INITIALIZE_RSOD,
        eFAILED_PUBLISH_RSOD,
        // Keep this one as the last
        eUNKNOWN
    }

    public static class COMObject
    {
        static IUpdateNotify2 updater;
        static UPDATE_STATUS_REPORT report;

        public static uint Download(string parameters = "")
        {
            updater = (IUpdateNotify2)new UpdateNotifyObject2();
            return updater.Download(parameters);
        }

        public static uint Apply(string parameters = "")
        {
            updater = (IUpdateNotify2)new UpdateNotifyObject2();
            return updater.Apply(parameters);
        }

        public static string GetCOMObjectStatus()
        {
            updater = (IUpdateNotify2)new UpdateNotifyObject2();
            updater.status(out report);

            return "{ \"status\":\"" + report.status + "\", \"result\":\"" + report.error + "\"}";
        }

        public static string[] GetBlockingApps()
        {
            string blockingApps;

            updater = (IUpdateNotify2)new UpdateNotifyObject2();
            updater.GetBlockingApps(out blockingApps);
            return blockingApps.Split(',');
        }
    }
}
"@

Add-Type -TypeDefinition $OfficeCOM -Language CSharp
