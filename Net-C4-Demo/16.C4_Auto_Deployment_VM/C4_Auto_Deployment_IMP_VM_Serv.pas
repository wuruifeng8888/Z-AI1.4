// �Զ���������������Ч���Ͳ�������
// �Զ���������ͨ����������Ӿ����Ŀͻ��������ʵ��
unit C4_Auto_Deployment_IMP_VM_Serv;

interface

uses
  System.SysUtils,
  PasAI.Core,
  PasAI.PascalStrings,
  PasAI.UnicodeMixedLib,
  PasAI.Net,
  PasAI.Net.DoubleTunnelIO.VirtualAuth,
  PasAI.Status,
  PasAI.Notify,
  PasAI.Net.PhysicsIO,
  PasAI.Net.C4, PasAI.Net.C4_UserDB, PasAI.Net.C4_Log_DB, PasAI.Net.C4.VM;

type
  TAuto_Deployment_Service = class;

  TTemp_Reg_Class = class // ����UserDB���������¼���
  public
    Service: TAuto_Deployment_Service;
    RegIO: TVirtualRegIO;
    procedure Do_Usr_Reg(Sender: TC40_UserDB_Client; State_: Boolean; info_: SystemString);
  end;

  TTemp_Auth_Class = class // ����UserDB���������¼���
  public
    Service: TAuto_Deployment_Service;
    AuthIO: TVirtualAuthIO;
    procedure Do_Usr_Auth(Sender: TC40_UserDB_Client; State_: Boolean; info_: SystemString);
  end;

  TAuto_Deployment_Service = class(TC40_VirtualAuth_VM_Service) // VM��ʽ������������C4��ͬ
  protected
    procedure DoUserReg_Event(Sender: TDTService_VirtualAuth; RegIO: TVirtualRegIO); override;
    procedure DoUserAuth_Event(Sender: TDTService_VirtualAuth; AuthIO: TVirtualAuthIO); override;
  protected
    // �Զ�����Ⲣ����c4����������ϵͳ
    procedure Do_C40_Deployment_Ready(States: TC40_Custom_ClientPool_Wait_States);
  public
    Log_Client: TC40_Log_DB_Client;
    UserDB_Client: TC40_UserDB_Client;

    constructor Create(Param_: U_String); override;
    destructor Destroy; override;
  end;

implementation

procedure TTemp_Reg_Class.Do_Usr_Reg(Sender: TC40_UserDB_Client; State_: Boolean; info_: SystemString);
begin
  if State_ then
      RegIO.Accept
  else
      RegIO.Reject;
  DelayFreeObj(1.0, self);
  if Service.Log_Client <> nil then
      Service.Log_Client.PostLog('User_' + MakeNowDateStr, Format('User Register "%s" = %s', [RegIO.UserID, umlBoolToStr(State_).Text]), info_);
end;

procedure TTemp_Auth_Class.Do_Usr_Auth(Sender: TC40_UserDB_Client; State_: Boolean; info_: SystemString);
begin
  if State_ then
      AuthIO.Accept
  else
      AuthIO.Reject;
  DelayFreeObj(1.0, self);
  if Service.Log_Client <> nil then
      Service.Log_Client.PostLog('User_' + MakeNowDateStr, Format('User Auth "%s" = %s', [AuthIO.UserID, umlBoolToStr(State_).Text]), info_);
end;

procedure TAuto_Deployment_Service.DoUserReg_Event(Sender: TDTService_VirtualAuth; RegIO: TVirtualRegIO);
var
  tmp: TTemp_Reg_Class;
begin
  if UserDB_Client = nil then
    begin
      RegIO.Reject;
      exit;
    end;
  tmp := TTemp_Reg_Class.Create;
  tmp.Service := self;
  tmp.RegIO := RegIO;
  UserDB_Client.Usr_RegM(RegIO.UserID, RegIO.Passwd, tmp.Do_Usr_Reg);
end;

procedure TAuto_Deployment_Service.DoUserAuth_Event(Sender: TDTService_VirtualAuth; AuthIO: TVirtualAuthIO);
var
  tmp: TTemp_Auth_Class;
begin
  if UserDB_Client = nil then
    begin
      AuthIO.Reject;
      exit;
    end;
  tmp := TTemp_Auth_Class.Create;
  tmp.Service := self;
  tmp.AuthIO := AuthIO;
  UserDB_Client.Usr_AuthM(AuthIO.UserID, AuthIO.Passwd, tmp.Do_Usr_Auth);
end;

procedure TAuto_Deployment_Service.Do_C40_Deployment_Ready(States: TC40_Custom_ClientPool_Wait_States);
var
  i: Integer;
  cc: TC40_Custom_Client;
begin
  Log_Client := nil;
  UserDB_Client := nil;
  for i := 0 to PasAI.Net.C4.C40_ClientPool.Count - 1 do
    begin
      cc := PasAI.Net.C4.C40_ClientPool[i];
      if cc is TC40_Log_DB_Client then
          Log_Client := cc as TC40_Log_DB_Client
      else if cc is TC40_UserDB_Client then
          UserDB_Client := cc as TC40_UserDB_Client;
    end;
  DoStatus('����ϵͳ׼������.');
end;

constructor TAuto_Deployment_Service.Create(Param_: U_String);
begin
  inherited;
  Log_Client := nil;
  UserDB_Client := nil;
  // �����������¼�
  C40_ClientPool.WaitConnectedDoneM('UserDB|Log', {$IFDEF FPC}@{$ENDIF FPC}Do_C40_Deployment_Ready);
end;

destructor TAuto_Deployment_Service.Destroy;
begin
  inherited;
end;

end.