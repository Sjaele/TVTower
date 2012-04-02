import brl.blitz
import brl.stream
import brl.glmax2d
TAdapterInfo^brl.blitz.Object{
.Device$&
.MAC@&[]&
.Address%&
.Broadcast%&
.Netmask%&
-New%()="_bb_TAdapterInfo_New"
-Delete%()="_bb_TAdapterInfo_Delete"
}="bb_TAdapterInfo"
TNetwork^brl.blitz.Object{
-New%()="_bb_TNetwork_New"
-Delete%()="_bb_TNetwork_Delete"
+GetHostIP%(HostName$)="_bb_TNetwork_GetHostIP"
+GetHostIPs%&[](HostName$)="_bb_TNetwork_GetHostIPs"
+GetHostName$(HostIp%)="_bb_TNetwork_GetHostName"
+StringIP$(IP%)="_bb_TNetwork_StringIP"
+StringMAC$(MAC@&[])="_bb_TNetwork_StringMAC"
+IntIP%(IP$)="_bb_TNetwork_IntIP"
+Ping%(RemoteIP%,Data@*,Size%,Sequence%=0,Timeout%=5000)="_bb_TNetwork_Ping"
+GetAdapterInfo%(Info:TAdapterInfo Var)="_bb_TNetwork_GetAdapterInfo"
}="bb_TNetwork"
TNetStream^brl.stream.TStream{
.Socket%&
.RecvBuffer@*&
.SendBuffer@*&
.RecvSize%&
.SendSize%&
-New%()="_bb_TNetStream_New"
-Delete%()="_bb_TNetStream_Delete"
-Init%()A="brl_blitz_NullMethodError"
-RecvMsg%()A="brl_blitz_NullMethodError"
-Read%(Buffer@*,Size%)="_bb_TNetStream_Read"
-SendMsg%()A="brl_blitz_NullMethodError"
-Write%(Buffer@*,Size%)="_bb_TNetStream_Write"
-Eof%()="_bb_TNetStream_Eof"
-Size%()="_bb_TNetStream_Size"
-Flush%()="_bb_TNetStream_Flush"
-Close%()="_bb_TNetStream_Close"
-RecvAvail%()="_bb_TNetStream_RecvAvail"
}A="bb_TNetStream"
TUDPStream^TNetStream{
.LocalIP%&
.LocalPort@@&
.RemotePort@@&
.RemoteIP%&
.MessageIP%&
.MessagePort@@&
.RecvTimeout%&
.SendTimeout%&
.fSpeed#&
.fDataGot#&
.fDataSent#&
.fDataSum#&
.fLastSecond#&
-New%()="_bb_TUDPStream_New"
-Delete%()="_bb_TUDPStream_Delete"
-Init%()="_bb_TUDPStream_Init"
-SetLocalPort%(Port@@=0)="_bb_TUDPStream_SetLocalPort"
-GetLocalPort@@()="_bb_TUDPStream_GetLocalPort"
-GetLocalIP%()="_bb_TUDPStream_GetLocalIP"
-SetRemotePort%(Port@@)="_bb_TUDPStream_SetRemotePort"
-GetRemotePort@@()="_bb_TUDPStream_GetRemotePort"
-SetRemoteIP%(IP%)="_bb_TUDPStream_SetRemoteIP"
-GetRemoteIP%()="_bb_TUDPStream_GetRemoteIP"
-SetBroadcast%(Enable%)="_bb_TUDPStream_SetBroadcast"
-GetBroadcast%()="_bb_TUDPStream_GetBroadcast"
-GetMsgPort@@()="_bb_TUDPStream_GetMsgPort"
-GetMsgIP%()="_bb_TUDPStream_GetMsgIP"
-SetTimeouts%(RecvMillisecs%,SendMillisecs%)="_bb_TUDPStream_SetTimeouts"
-GetRecvTimeout%()="_bb_TUDPStream_GetRecvTimeout"
-GetSendTimeout%()="_bb_TUDPStream_GetSendTimeout"
-RecvMsg%()="_bb_TUDPStream_RecvMsg"
-SendUDPMsg%(IP%,Port%=0)="_bb_TUDPStream_SendUDPMsg"
-SendMsg%()="_bb_TUDPStream_SendMsg"
}="bb_TUDPStream"
TTCPStream^TNetStream{
.LocalIP%&
.LocalPort@@&
.RemoteIP%&
.RemotePort@@&
.RecvTimeout%&
.SendTimeout%&
.AcceptTimeout%&
-New%()="_bb_TTCPStream_New"
-Delete%()="_bb_TTCPStream_Delete"
-Init%()="_bb_TTCPStream_Init"
-SetLocalPort%(Port@@=0)="_bb_TTCPStream_SetLocalPort"
-GetLocalPort@@()="_bb_TTCPStream_GetLocalPort"
-GetLocalIP%()="_bb_TTCPStream_GetLocalIP"
-SetRemotePort%(Port@@)="_bb_TTCPStream_SetRemotePort"
-GetRemotePort@@()="_bb_TTCPStream_GetRemotePort"
-SetRemoteIP%(IP%)="_bb_TTCPStream_SetRemoteIP"
-GetRemoteIP%()="_bb_TTCPStream_GetRemoteIP"
-SetTimeouts%(RecvMillisecs%,SendMillisecs%,AcceptMillisecs%=0)="_bb_TTCPStream_SetTimeouts"
-GetRecvTimeout%()="_bb_TTCPStream_GetRecvTimeout"
-GetSendTimeout%()="_bb_TTCPStream_GetSendTimeout"
-GetAcceptTimeout%()="_bb_TTCPStream_GetAcceptTimeout"
-Connect%()="_bb_TTCPStream_Connect"
-Listen%(MaxClients%=32)="_bb_TTCPStream_Listen"
-Accept:TTCPStream()="_bb_TTCPStream_Accept"
-RecvMsg%()="_bb_TTCPStream_RecvMsg"
-SendMsg%()="_bb_TTCPStream_SendMsg"
-GetState%()="_bb_TTCPStream_GetState"
}="bb_TTCPStream"