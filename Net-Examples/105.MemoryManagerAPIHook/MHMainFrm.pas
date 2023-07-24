unit MHMainFrm;


interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls,
  PasAI.Status, PasAI.PascalStrings, PasAI.Core, PasAI.UnicodeMixedLib, PasAI.ListEngine;

type
  TMHMainForm = class(TForm)
    Memo: TMemo;
    Panel1: TPanel;
    Button1: TButton;
    Button2: TButton;
    Button3: TButton;
    Button4: TButton;
    Button5: TButton;
    procedure Button1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure Button4Click(Sender: TObject);
    procedure Button5Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    procedure DoStatusMethod(AText: SystemString; const ID: Integer);
  end;

var
  MHMainForm: TMHMainForm;

implementation

{$R *.dfm}


uses PasAI.MH1, PasAI.MH2, PasAI.MH3, PasAI.MH;

procedure TMHMainForm.Button1Click(Sender: TObject);

  procedure leakproc(x, m: Integer);
  begin
    GetMemory(x);
    if x > m then
        leakproc(x - 1, m);
  end;

begin
  PasAI.MH.BeginMemoryHook_1;
  leakproc(100, 98);
  PasAI.MH.EndMemoryHook_1;

  // �������ǻᷢ��й©
  DoStatus('leakproc���������� %d �ֽڵ��ڴ�', [PasAI.MH.GetHookMemorySize_1]);

  PasAI.MH.GetHookPtrList_1.ProgressP(procedure(NPtr: Pointer; uData: NativeUInt)
    begin
      DoStatus('й©�ĵ�ַ:0x%s', [IntToHex(NativeUInt(NPtr), sizeof(Pointer) * 2)]);
      DoStatus(NPtr, uData, 80);

      // �������ǿ���ֱ���ͷŸõ�ַ
      Dispose(NPtr);

      DoStatus('�ѳɹ��ͷ� ��ַ:0x%s ռ���� %d �ֽ��ڴ�', [IntToHex(NativeUInt(NPtr), sizeof(Pointer) * 2), uData]);
    end);
end;

procedure TMHMainForm.Button2Click(Sender: TObject);
type
  PMyRec = ^TMyRec;

  TMyRec = record
    s1: string;
    s2: string;
    s3: TPascalString;
    obj: TObject;
  end;

var
  p: PMyRec;
begin
  PasAI.MH.BeginMemoryHook_1;
  new(p);
  p^.s1 := #7#8#9;
  p^.s2 := #$20#$20#$20#$20#$20#$20#$20#$20#$20#$20#$20#$20;
  p^.s3.Text := #1#2#3#4#5#6;
  p^.obj := TObject.Create;
  PasAI.MH.EndMemoryHook_1;

  // �������ǻᷢ��й©
  DoStatus('TMyRec�ַܷ����� %d ���ڴ棬ռ�� %d �ֽڿռ䣬', [PasAI.MH.GetHookPtrList_1.Count, PasAI.MH.GetHookMemorySize_1]);

  PasAI.MH.GetHookPtrList_1.ProgressP(procedure(NPtr: Pointer; uData: NativeUInt)
    begin
      DoStatus('й©�ĵ�ַ:0x%s', [IntToHex(NativeUInt(NPtr), sizeof(Pointer) * 2)]);
      DoStatus(NPtr, uData, 80);

      // �������ǿ���ֱ���ͷŸõ�ַ
      FreeMem(NPtr);

      DoStatus('�ѳɹ��ͷ� ��ַ:0x%s ռ���� %d �ֽ��ڴ�', [IntToHex(NativeUInt(NPtr), sizeof(Pointer) * 2), uData]);
    end);
end;

procedure TMHMainForm.DoStatusMethod(AText: SystemString; const ID: Integer);
begin
  Memo.Lines.Add(AText);
end;

procedure TMHMainForm.FormCreate(Sender: TObject);
begin
  AddDoStatusHook(Self, DoStatusMethod);
end;

procedure TMHMainForm.Button3Click(Sender: TObject);
type
  PMyRec = ^TMyRec;

  TMyRec = record
    s1: string;
    p: PMyRec;
  end;

var
  p: PMyRec;
  i: Integer;
begin
  // 10��εķ������������ͷ�
  // ���ֳ����������������ͳ����ĳ���������¼�ڴ�����
  for i := 0 to 10 * 10000 do
    begin
      PasAI.MH2.BeginMemoryHook(4);
      new(p);
      p^.s1 := '12345';
      new(p^.p);
      p^.p^.s1 := '54321';
      PasAI.MH2.EndMemoryHook;

      PasAI.MH2.GetHookPtrList.ProgressP(procedure(NPtr: Pointer; uData: NativeUInt)
        begin
          // �������ǿ����ͷŸõ�ַ
          FreeMem(NPtr);
        end);
    end;
end;

procedure TMHMainForm.Button4Click(Sender: TObject);
type
  PMyRec = ^TMyRec;

  TMyRec = record
    s1: string;
    p: PMyRec;
  end;

var
  p: PMyRec;
  i: Integer;
  hl: TPointerHashNativeUIntList;
begin
  // 20��εĴ�������¼�ڴ����룬���һ�����ͷ�
  // ���ֳ���������������������ͷ�й©���ڴ�

  // �����ڽ�20���Hash������д洢
  // BeginMemoryHook�Ĳ���Խ����ԶԴ������洢�ĸ�Ƶ�ʼ�¼���ܾ�Խ�ã���ҲԽ�����ڴ�
  PasAI.MH3.BeginMemoryHook(200000);

  for i := 0 to 20 * 10000 do
    begin
      new(p);
      new(p^.p);
      // ģ���ַ�����ֵ����Ƶ�ʴ���Realloc����
      p^.s1 := '111111111111111';
      p^.s1 := '1111111111111111111111111111111111';
      p^.s1 := '11111111111111111111111111111111111111111111111111111111111111';
      p^.p^.s1 := '1';
      p^.p^.s1 := '11111111111111111111';
      p^.p^.s1 := '1111111111111111111111111111111111111';
      p^.p^.s1 := '11111111111111111111111111111111111111111111111111111111111111111111111111';

      if i mod 99999 = 0 then
        begin
          // �����ǵ������ã����ǲ���¼����MH_3.MemoryHooked����ΪFalse����
          PasAI.MH3.GetMemoryHooked.V := False;
          Button1Click(nil);
          Application.ProcessMessages;
          // ������¼�ڴ�����
          PasAI.MH3.GetMemoryHooked.V := True;
        end;
    end;
  PasAI.MH3.EndMemoryHook;

  DoStatus('�ܹ��ڴ���� %d �� ռ�� %s �ռ䣬��ַ���Ϊ��%s ', [PasAI.MH3.GetHookPtrList.Count, umlSizeToStr(PasAI.MH3.GetHookMemorySize).Text,
    umlSizeToStr(NativeUInt(PasAI.MH3.GetHookMemoryMaximumPtr) - NativeUInt(PasAI.MH3.GetHookMemoryMinimizePtr)).Text]);

  PasAI.MH3.GetHookPtrList.ProgressP(procedure(NPtr: Pointer; uData: NativeUInt)
    begin
      // �������ǿ����ͷŸõ�ַ
      FreeMem(NPtr);
    end);
  PasAI.MH3.GetHookPtrList.PrintHashReport;
  PasAI.MH3.GetHookPtrList.SetHashBlockCount(0);
end;

procedure TMHMainForm.Button5Click(Sender: TObject);

var
  s: string;
  sptr: PString;
begin
  PasAI.MH1.BeginMemoryHook(16);

  Memo.Lines.Add('123'); // ��Ϊû��ǰ���Ĳο��������Realloc��GetMem�����ᱻ��¼
  s := '12345';           // ��Ϊs�ַ����ڵ��ÿ�ʼʱ�Ѿ���ʼ����û��ǰ���Ĳο��������Realloc���ᱻ��¼

  new(sptr); // ������¼sptr��GetMem��ַ
  sptr^ := '123';
  sptr^ := '123456789'; // �ڷ����˶�sptr��Reallocʱ��mh��Ѱ��ǰ���ģ����������realloc�ļ�¼������mh����¼���������ں����ͷ�

  // mh֧�ֿؼ��������ͷ�
  // mh��֧��tform�����ͷţ���Ϊtform���ڻ�ע��ȫ�ֲ�����mh���ͷ���tform�Ժ�ĳЩ�ص�����û�е�ַ�ͻᱨ��
  TButton.Create(Self).Free;

  PasAI.MH1.EndMemoryHook;

  PasAI.MH1.GetHookPtrList.ProgressP(procedure(NPtr: Pointer; uData: NativeUInt)
    begin
      // �������ǿ����ͷŸõ�ַ
      DoStatus(NPtr, uData, 80);
      FreeMem(NPtr);
    end);

  PasAI.MH1.GetHookPtrList.SetHashBlockCount(0);
end;

end.