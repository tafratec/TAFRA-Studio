unit uCodeQualityModel;

{$mode objfpc}{$H+}

interface

uses
  Classes;

type
  TCodeQualitySeverity = (
    cqsInfo,
    cqsWarning,
    cqsCritical
  );

  TCodeQualityRisk = (
    cqrSafe,
    cqrLow,
    cqrMedium,
    cqrHigh
  );

  TCodeQualityFinding = class
  private
    FToolName: string;
    FFilePath: string;
    FRelativePath: string;
    FLineNumber: Integer;
    FColumnNumber: Integer;
    FCategory: string;
    FSeverity: TCodeQualitySeverity;
    FRisk: TCodeQualityRisk;
    FMessageText: string;
    FRecommendation: string;
  public
    constructor Create(const AToolName, AFilePath, ARelativePath: string;
      ALineNumber, AColumnNumber: Integer; const ACategory: string;
      ASeverity: TCodeQualitySeverity; ARisk: TCodeQualityRisk;
      const AMessageText, ARecommendation: string);
    property ToolName: string read FToolName;
    property FilePath: string read FFilePath;
    property RelativePath: string read FRelativePath;
    property LineNumber: Integer read FLineNumber;
    property ColumnNumber: Integer read FColumnNumber;
    property Category: string read FCategory;
    property Severity: TCodeQualitySeverity read FSeverity;
    property Risk: TCodeQualityRisk read FRisk;
    property MessageText: string read FMessageText;
    property Recommendation: string read FRecommendation;
  end;

  TCodeQualityConfiguration = class
  private
    FIncludedPaths: TStringList;
    FExcludedPaths: TStringList;
    FTimeoutMS: Cardinal;
    FPHPCSFixerEnabled: Boolean;
    FPHPCSEnabled: Boolean;
    FPHPStanEnabled: Boolean;
    FRectorEnabled: Boolean;
  public
    constructor Create;
    destructor Destroy; override;
    procedure ApplyDefaults;
    property IncludedPaths: TStringList read FIncludedPaths;
    property ExcludedPaths: TStringList read FExcludedPaths;
    property TimeoutMS: Cardinal read FTimeoutMS write FTimeoutMS;
    property PHPCSFixerEnabled: Boolean read FPHPCSFixerEnabled
      write FPHPCSFixerEnabled;
    property PHPCSEnabled: Boolean read FPHPCSEnabled write FPHPCSEnabled;
    property PHPStanEnabled: Boolean read FPHPStanEnabled write FPHPStanEnabled;
    property RectorEnabled: Boolean read FRectorEnabled write FRectorEnabled;
  end;

  TCodeQualityReport = class
  private
    FProjectPath: string;
    FFindings: TList;
    FGeneratedAt: TDateTime;
  public
    constructor Create(const AProjectPath: string);
    destructor Destroy; override;
    function AddFinding(AFinding: TCodeQualityFinding): TCodeQualityFinding;
    procedure Clear;
    function CountBySeverity(ASeverity: TCodeQualitySeverity): Integer;
    function CountByRisk(ARisk: TCodeQualityRisk): Integer;
    property ProjectPath: string read FProjectPath;
    property Findings: TList read FFindings;
    property GeneratedAt: TDateTime read FGeneratedAt write FGeneratedAt;
  end;

function CodeQualitySeverityToString(
  ASeverity: TCodeQualitySeverity): string;
function CodeQualityRiskToString(ARisk: TCodeQualityRisk): string;

implementation

uses
  SysUtils;

constructor TCodeQualityFinding.Create(const AToolName, AFilePath,
  ARelativePath: string; ALineNumber, AColumnNumber: Integer;
  const ACategory: string; ASeverity: TCodeQualitySeverity;
  ARisk: TCodeQualityRisk; const AMessageText, ARecommendation: string);
begin
  inherited Create;
  FToolName := AToolName;
  FFilePath := AFilePath;
  FRelativePath := ARelativePath;
  FLineNumber := ALineNumber;
  FColumnNumber := AColumnNumber;
  FCategory := ACategory;
  FSeverity := ASeverity;
  FRisk := ARisk;
  FMessageText := AMessageText;
  FRecommendation := ARecommendation;
end;

constructor TCodeQualityConfiguration.Create;
begin
  inherited Create;
  FIncludedPaths := TStringList.Create;
  FExcludedPaths := TStringList.Create;
  ApplyDefaults;
end;

destructor TCodeQualityConfiguration.Destroy;
begin
  FExcludedPaths.Free;
  FIncludedPaths.Free;
  inherited Destroy;
end;

procedure TCodeQualityConfiguration.ApplyDefaults;
begin
  if FIncludedPaths.Count = 0 then
  begin
    FIncludedPaths.Add('app');
    FIncludedPaths.Add('public');
    FIncludedPaths.Add('config');
    FIncludedPaths.Add('routes');
  end;

  if FExcludedPaths.Count = 0 then
  begin
    FExcludedPaths.Add('.git');
    FExcludedPaths.Add('vendor');
    FExcludedPaths.Add('node_modules');
    FExcludedPaths.Add('cache');
    FExcludedPaths.Add('temp');
    FExcludedPaths.Add('tmp');
    FExcludedPaths.Add('logs');
  end;

  if FTimeoutMS = 0 then
    FTimeoutMS := 60000;

  FPHPCSFixerEnabled := True;
  FPHPCSEnabled := True;
  FPHPStanEnabled := True;
  FRectorEnabled := False;
end;

constructor TCodeQualityReport.Create(const AProjectPath: string);
begin
  inherited Create;
  FProjectPath := AProjectPath;
  FFindings := TList.Create;
  FGeneratedAt := Now;
end;

destructor TCodeQualityReport.Destroy;
begin
  Clear;
  FFindings.Free;
  inherited Destroy;
end;

function TCodeQualityReport.AddFinding(
  AFinding: TCodeQualityFinding): TCodeQualityFinding;
begin
  FFindings.Add(AFinding);
  Result := AFinding;
end;

procedure TCodeQualityReport.Clear;
var
  I: Integer;
begin
  for I := 0 to FFindings.Count - 1 do
    TObject(FFindings[I]).Free;
  FFindings.Clear;
end;

function TCodeQualityReport.CountBySeverity(
  ASeverity: TCodeQualitySeverity): Integer;
var
  I: Integer;
begin
  Result := 0;
  for I := 0 to FFindings.Count - 1 do
    if TCodeQualityFinding(FFindings[I]).Severity = ASeverity then
      Inc(Result);
end;

function TCodeQualityReport.CountByRisk(ARisk: TCodeQualityRisk): Integer;
var
  I: Integer;
begin
  Result := 0;
  for I := 0 to FFindings.Count - 1 do
    if TCodeQualityFinding(FFindings[I]).Risk = ARisk then
      Inc(Result);
end;

function CodeQualitySeverityToString(
  ASeverity: TCodeQualitySeverity): string;
begin
  case ASeverity of
    cqsInfo:
      Result := 'Info';
    cqsWarning:
      Result := 'Warning';
    cqsCritical:
      Result := 'Critical';
  end;
end;

function CodeQualityRiskToString(ARisk: TCodeQualityRisk): string;
begin
  case ARisk of
    cqrSafe:
      Result := 'Safe';
    cqrLow:
      Result := 'Low';
    cqrMedium:
      Result := 'Medium';
    cqrHigh:
      Result := 'High';
  end;
end;

end.
