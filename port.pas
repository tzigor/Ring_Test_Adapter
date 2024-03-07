unit Port;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, synaser,
  jwawinbase, jwawinnt, DateUtils;

procedure PortInit();
function GetResponse(cmd: String): String;

implementation
uses Main;

procedure PortInit();
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
      end;
   end;
   if FreePortsAvailable then begin
     RT.COMselectCB.ItemIndex:= RT.COMselectCB.Items.Count-1; { select the last eable port }
     ser:= TBlockSerial.Create;
     //ser.RaiseExcept:= True; { interrupt enable in case of error }
     ser.Connect(RT.COMselectCB.Text);
     ser.Config(9600, 8, 'N', 1, false, false);
   end;
end;

function GetResponse(cmd: String): String;
var
    value              : AnsiString; { received data }
    waiting            : integer; { number of received bits }
    StartListeningTime : TDateTime;
    Timer              : LongWord;
begin
  if FreePortsAvailable then begin
      mon:= True; { port monitoring enaable }
      ser.SendString(cmd);
      StartListeningTime:= Now;
      while mon do
      begin
         sleep(100);
         waiting:= ser.WaitingData; { save number of simbols in the incoming port }
         SetLength(value, waiting);
         ser.RecvBuffer(@value[1], waiting); { read buffer }
         Application.ProcessMessages; { let app to listen other events }
         if value <> '' then begin
            Result:= value;
            mon:= False;
         end;
         Timer:= MilliSecondsBetween(StartListeningTime, Now);
         if Timer > TIME_OUT then begin
            Result:= 'Time out';
            mon:= False;
         end;
      end;
  end
  else Result:= 'Port not available';
end;

end.

