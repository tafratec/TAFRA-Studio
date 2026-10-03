unit uProjectSession;

{$mode objfpc}{$H+}

interface

uses
  uProjectModel, uProjectScanner, uResultTypes;

type
  TProjectSession = class
  private
    FCurrentProjectPath: string;
    FCurrentProject: TTAFRAProject;
    FScanner: TProjectScanner;
  public
    constructor Create(AScanner: TProjectScanner);
    destructor Destroy; override;
    function OpenProject(const AProjectPath: string): TOperationResult;
    function CloseProject: TOperationResult;
    property CurrentProjectPath: string read FCurrentProjectPath;
    property CurrentProject: TTAFRAProject read FCurrentProject;
  end;

implementation

uses
  SysUtils;

constructor TProjectSession.Create(AScanner: TProjectScanner);
begin
  inherited Create;
  FScanner := AScanner;
end;

destructor TProjectSession.Destroy;
begin
  FCurrentProject.Free;
  inherited Destroy;
end;

function TProjectSession.OpenProject(const AProjectPath: string
  ): TOperationResult;
begin
  if not DirectoryExists(AProjectPath) then
  begin
    Result := TOperationResult.Fail('PROJECT_DIRECTORY_NOT_FOUND',
      'Project directory not found: ' + AProjectPath);
    Exit;
  end;

  FCurrentProject.Free;
  FCurrentProject := nil;

  FCurrentProjectPath := ExcludeTrailingPathDelimiter(AProjectPath);
  if Assigned(FScanner) then
    FCurrentProject := FScanner.Scan(FCurrentProjectPath)
  else
    FCurrentProject := TTAFRAProject.Create(FCurrentProjectPath);

  Result := TOperationResult.Ok('Project opened: ' + FCurrentProjectPath);
end;

function TProjectSession.CloseProject: TOperationResult;
var
  ClosedPath: string;
begin
  if FCurrentProjectPath = '' then
  begin
    Result := TOperationResult.Ok('No project is open.');
    Exit;
  end;

  ClosedPath := FCurrentProjectPath;
  FCurrentProjectPath := '';
  FCurrentProject.Free;
  FCurrentProject := nil;

  Result := TOperationResult.Ok('Project closed: ' + ClosedPath);
end;

end.
