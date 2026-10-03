program TAFRAStudio;

{$mode objfpc}{$H+}

uses
  Interfaces,
  Forms,
  uMainForm;

{$R tafrastudio.res}

begin
  Application.Scaled := True;
  Application.Title := 'TAFRA Studio';
  Application.Initialize;
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
