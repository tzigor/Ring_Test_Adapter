unit Main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, Spin,
  synaser, jwawinbase, jwawinnt, Port;

type

  { TRT }

  TRT = class(TForm)
    AllSetBtn: TButton;
    Label45: TLabel;
    Label46: TLabel;
    Label47: TLabel;
    Label48: TLabel;
    Label49: TLabel;
    Label50: TLabel;
    SkipTime: TSpinEdit;
    Label41: TLabel;
    Label42: TLabel;
    AllMin: TSpinEdit;
    AllSec: TSpinEdit;
    Label43: TLabel;
    Label44: TLabel;
    Step13Min: TSpinEdit;
    Step14Min: TSpinEdit;
    Step13Sec: TSpinEdit;
    Step14Sec: TSpinEdit;
    UploadBtn: TButton;
    CloseBtn: TButton;
    ConnectBtn: TButton;
    COMselectCB: TComboBox;
    GroupBox1: TGroupBox;
    SoleniodPower: TSpinEdit;
    Label1: TLabel;
    Label10: TLabel;
    Label11: TLabel;
    Label12: TLabel;
    Label13: TLabel;
    Label14: TLabel;
    Label15: TLabel;
    Label16: TLabel;
    Label17: TLabel;
    Label18: TLabel;
    Label19: TLabel;
    Label2: TLabel;
    Label20: TLabel;
    Label21: TLabel;
    Label22: TLabel;
    Label23: TLabel;
    Label24: TLabel;
    Label25: TLabel;
    Label26: TLabel;
    Label27: TLabel;
    Label28: TLabel;
    Label29: TLabel;
    Label3: TLabel;
    Label30: TLabel;
    Label31: TLabel;
    Label32: TLabel;
    Label33: TLabel;
    Label34: TLabel;
    Label35: TLabel;
    Label36: TLabel;
    Label37: TLabel;
    Label38: TLabel;
    Label39: TLabel;
    Label4: TLabel;
    Label40: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    Label7: TLabel;
    Label8: TLabel;
    Label9: TLabel;
    HoldTime: TSpinEdit;
    Step1Min: TSpinEdit;
    Step2Min: TSpinEdit;
    Step11Min: TSpinEdit;
    Step12Min: TSpinEdit;
    Step3Min: TSpinEdit;
    Step4Min: TSpinEdit;
    Step5Min: TSpinEdit;
    Step6Min: TSpinEdit;
    Step7Min: TSpinEdit;
    Step8Min: TSpinEdit;
    Step9Min: TSpinEdit;
    Step10Min: TSpinEdit;
    Step1Sec: TSpinEdit;
    Step2Sec: TSpinEdit;
    Step11Sec: TSpinEdit;
    Step12Sec: TSpinEdit;
    Step3Sec: TSpinEdit;
    Step4Sec: TSpinEdit;
    Step5Sec: TSpinEdit;
    Step6Sec: TSpinEdit;
    Step7Sec: TSpinEdit;
    Step8Sec: TSpinEdit;
    Step9Sec: TSpinEdit;
    Step10Sec: TSpinEdit;
    procedure AllSetBtnClick(Sender: TObject);
    procedure CloseBtnClick(Sender: TObject);
    procedure ConnectBtnClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure UploadBtnClick(Sender: TObject);
  private

  public

  end;

 Const
  NewLine     = #13#10;
  TIME_OUT    = 3000;  { 3 sec }
var

  RT: TRT;

  ser                 : TBlockSerial; { current serial port }
  mon                 : Boolean;      { port monitoring enable }
  FreePortsAvailable  : Boolean;

implementation

{$R *.lfm}

{ TRT }

procedure TRT.FormCreate(Sender: TObject);
var
i       : Integer;
Phandle : Thandle;
begin
  FreePortsAvailable:= False;
   for i:=1 to 30 do
   begin
      { try connect to porn i }
      Phandle:= CreateFile(Pchar('COM'+intToStr(i)), Generic_Read or Generic_Write, 0, nil, open_existing,file_flag_overlapped, 0);
      if Phandle <> invalid_handle_value then { if port enable }
      begin
         RT.COMselectCB.Items.Add('COM'+ IntToStr(i));
         CloseHandle(Phandle);
         FreePortsAvailable:= True;
         RT.COMselectCB.ItemIndex:= 0;
      end;
   end;
end;

procedure TRT.UploadBtnClick(Sender: TObject);
var
   i               : Byte;
   SendData        : String = '';
   receivedMessage : String;
begin
  for i:=1 to 14 do
    SendData:= SendData + IntToStr(TSpinEdit(RT.FindComponent('Step' + IntToStr(i) + 'Min')).value * 60 +
                                   TSpinEdit(RT.FindComponent('Step' + IntToStr(i) + 'Sec')).value) + ';';
  SendData:= SendData + IntToStr(HoldTime.Value) + ';';
  SendData:= SendData + IntToStr(SkipTime.Value) + ';';
  SendData:= SendData + IntToStr(SoleniodPower.Value) + ';';
  ShowMessage(SendData);
  receivedMessage:= GetResponse(SendData);
  ShowMessage(receivedMessage);
  if receivedMessage = 'success' then ShowMessage('Parameters saved successfully')
  else ShowMessage('Something went wrong :(');
end;

procedure TRT.ConnectBtnClick(Sender: TObject);
var
  receivedData : String;
  DataLength   : Integer;
  n            : Integer = 1;
  wStr         : String = '';
  ParamNumber  : Byte = 0;
  Secs         : Word;
begin
  if FreePortsAvailable then begin
    if ser <> nil then ser.Destroy;
    ser := TBlockSerial.Create;
    Sleep(25); //250
    ser.Connect(RT.COMselectCB.Text);
    Sleep(25);  //250
    ser.Config(9600, 8, 'N', SB1, False, False);
    ser.RTS := false; // comment this if needed
    ser.DTR := false; // comment this if needed
    Sleep(3000);
    receivedData:= GetResponse('query');
    ShowMessage(receivedData);
    if receivedData <> 'Time out' then begin
       DataLength:= receivedData.Length;
       while n <= DataLength do begin
          if receivedData[n] <> ';' then wStr:= wStr + receivedData[n]
          else begin
            Inc(ParamNumber);
            if ParamNumber <= 14 then begin
              Secs:= StrToInt(wStr);
              TSpinEdit(RT.FindComponent('Step' + IntToStr(ParamNumber) + 'Min')).value:= Secs Div 60;
              if Secs < 60 then TSpinEdit(RT.FindComponent('Step' + IntToStr(ParamNumber) + 'Sec')).value:= Secs
              else TSpinEdit(RT.FindComponent('Step' + IntToStr(ParamNumber) + 'Sec')).value:= Secs - (Secs Div 60) * 60;
            end
            else if ParamNumber = 15 then HoldTime.Value:= StrToInt(wStr)
                 else if ParamNumber = 16 then SkipTime.Value:= StrToInt(wStr)
                      else if ParamNumber = 17 then SoleniodPower.Value:= StrToInt(wStr);
            wStr:= '';
          end;
          Inc(n);
       end;
       UploadBtn.Enabled:= True;
    end
    else ShowMessage('Time out');
  end;
end;

procedure TRT.CloseBtnClick(Sender: TObject);
begin
  RT.Close;
end;

procedure TRT.AllSetBtnClick(Sender: TObject);
var i : Byte;
begin
  for i:=1 to 14 do begin
    TSpinEdit(RT.FindComponent('Step' + IntToStr(i) + 'Min')).value:= AllMin.Value;
    TSpinEdit(RT.FindComponent('Step' + IntToStr(i) + 'Sec')).value:= AllSec.Value;
  end;
end;

end.

