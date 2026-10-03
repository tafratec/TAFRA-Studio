unit uProcessRunner;

{$mode objfpc}{$H+}

interface

uses
  Classes, Pipes, Process, uResultTypes;

type
  TProcessRunner = class
  private
    function ReadAvailable(AStream: TInputPipeStream): string;
  public
    function Execute(const AExecutablePath: string; AArguments: TStrings;
      const AWorkingDirectory: string; ATimeoutMS: Cardinal): TProcessResult;
  end;

implementation

uses
  SysUtils;

function TProcessRunner.ReadAvailable(AStream: TInputPipeStream): string;
var
  BytesAvailable: LongInt;
begin
  Result := '';
  BytesAvailable := AStream.NumBytesAvailable;
  if BytesAvailable <= 0 then
    Exit;

  SetLength(Result, BytesAvailable);
  AStream.ReadBuffer(Result[1], BytesAvailable);
end;

function TProcessRunner.Execute(const AExecutablePath: string;
  AArguments: TStrings; const AWorkingDirectory: string; ATimeoutMS: Cardinal
  ): TProcessResult;
var
  Proc: TProcess;
  StartTicks: QWord;
  I: Integer;
begin
  Result := TProcessResult.Create;
  Result.ExecutablePath := AExecutablePath;
  Result.ExitCode := -1;

  if not FileExists(AExecutablePath) then
  begin
    Result.Success := False;
    Result.ErrorCode := 'EXECUTABLE_NOT_FOUND';
    Result.MessageText := 'Executable not found: ' + AExecutablePath;
    Exit;
  end;

  Proc := TProcess.Create(nil);
  try
    Proc.Executable := AExecutablePath;
    if AWorkingDirectory <> '' then
      Proc.CurrentDirectory := AWorkingDirectory;

    if Assigned(AArguments) then
      for I := 0 to AArguments.Count - 1 do
        Proc.Parameters.Add(AArguments[I]);

    Proc.Options := [poUsePipes];
    StartTicks := GetTickCount64;

    try
      Proc.Execute;
      while Proc.Running do
      begin
        Result.StdOutText := Result.StdOutText + ReadAvailable(Proc.Output);
        Result.StdErrText := Result.StdErrText + ReadAvailable(Proc.Stderr);

        if (ATimeoutMS > 0) and ((GetTickCount64 - StartTicks) > ATimeoutMS) then
        begin
          Proc.Terminate(1);
          Result.TimedOut := True;
          Result.Success := False;
          Result.ErrorCode := 'PROCESS_TIMEOUT';
          Result.MessageText := 'Process timed out.';
          Exit;
        end;

        Sleep(10);
      end;

      Result.StdOutText := Result.StdOutText + ReadAvailable(Proc.Output);
      Result.StdErrText := Result.StdErrText + ReadAvailable(Proc.Stderr);

      Result.ExitCode := Proc.ExitStatus;
      Result.Success := Result.ExitCode = 0;
      if Result.Success then
        Result.MessageText := 'Process completed successfully.'
      else
      begin
        Result.ErrorCode := 'PROCESS_EXIT_ERROR';
        Result.MessageText := 'Process exited with code ' + IntToStr(Result.ExitCode) + '.';
      end;
    except
      on E: Exception do
      begin
        Result.Success := False;
        Result.ErrorCode := 'PROCESS_EXECUTION_ERROR';
        Result.MessageText := E.Message;
      end;
    end;
  finally
    Proc.Free;
  end;
end;

end.
