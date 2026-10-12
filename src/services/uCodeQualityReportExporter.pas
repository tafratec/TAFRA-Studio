unit uCodeQualityReportExporter;

{$mode objfpc}{$H+}

interface

uses
  uCodeQualityModel, uResultTypes;

type
  TCodeQualityReportFormat = (cqrfJson, cqrfCsv, cqrfHtml);

  TCodeQualityReportExporter = class
  private
    function BuildCsv(const AReport: TCodeQualityReport): string;
    function BuildHtml(const AReport: TCodeQualityReport): string;
    function BuildJson(const AReport: TCodeQualityReport): string;
    function CsvValue(const AValue: string): string;
    function HtmlEncode(const AValue: string): string;
  public
    function SaveReport(const AReport: TCodeQualityReport;
      const AFileName: string; AFormat: TCodeQualityReportFormat): TOperationResult;
  end;

implementation

uses
  Classes, fpjson, SysUtils;

function TCodeQualityReportExporter.CsvValue(const AValue: string): string;
var
  Value: string;
begin
  Value := StringReplace(AValue, #13#10, '\n', [rfReplaceAll]);
  Value := StringReplace(Value, #13, '\n', [rfReplaceAll]);
  Value := StringReplace(Value, #10, '\n', [rfReplaceAll]);
  Value := StringReplace(Value, '"', '""', [rfReplaceAll]);
  Result := '"' + Value + '"';
end;

function TCodeQualityReportExporter.HtmlEncode(const AValue: string): string;
begin
  Result := StringReplace(AValue, '&', '&amp;', [rfReplaceAll]);
  Result := StringReplace(Result, '<', '&lt;', [rfReplaceAll]);
  Result := StringReplace(Result, '>', '&gt;', [rfReplaceAll]);
  Result := StringReplace(Result, '"', '&quot;', [rfReplaceAll]);
  Result := StringReplace(Result, #13#10, '<br>', [rfReplaceAll]);
  Result := StringReplace(Result, #10, '<br>', [rfReplaceAll]);
end;

function TCodeQualityReportExporter.BuildCsv(const AReport: TCodeQualityReport
  ): string;
var
  Finding: TCodeQualityFinding;
  I: Integer;
  Lines: TStringList;
begin
  Lines := TStringList.Create;
  try
    Lines.Add('scope,tool,file_path,relative_path,line,column,category,severity,risk,message,recommendation');
    for I := 0 to AReport.Findings.Count - 1 do
    begin
      Finding := TCodeQualityFinding(AReport.Findings[I]);
      Lines.Add(CsvValue(AReport.ScopeDescription) + ',' + CsvValue(Finding.ToolName) + ',' +
        CsvValue(Finding.FilePath) + ',' + CsvValue(Finding.RelativePath) + ',' +
        IntToStr(Finding.LineNumber) + ',' + IntToStr(Finding.ColumnNumber) + ',' +
        CsvValue(Finding.Category) + ',' +
        CsvValue(CodeQualitySeverityToString(Finding.Severity)) + ',' +
        CsvValue(CodeQualityRiskToString(Finding.Risk)) + ',' +
        CsvValue(Finding.MessageText) + ',' + CsvValue(Finding.Recommendation));
    end;
    Result := Lines.Text;
  finally
    Lines.Free;
  end;
end;

function TCodeQualityReportExporter.BuildHtml(const AReport: TCodeQualityReport
  ): string;
var
  Finding: TCodeQualityFinding;
  I: Integer;
  Lines: TStringList;
begin
  Lines := TStringList.Create;
  try
    Lines.Add('<!doctype html>');
    Lines.Add('<html><head><meta charset="utf-8"><title>TAFRA Studio Code Quality Report</title>');
    Lines.Add('<style>body{font-family:Segoe UI,Arial,sans-serif;margin:32px;color:#202124}' +
      'table{border-collapse:collapse;width:100%;margin-top:20px}' +
      'th,td{border:1px solid #d0d0d0;padding:8px;text-align:left;vertical-align:top}' +
      'th{background:#f2f2f2}.Critical{color:#b00020;font-weight:bold}' +
      '.Warning{color:#9b6500;font-weight:bold}.Info{color:#1b5e8b;font-weight:bold}' +
      '</style></head><body>');
    Lines.Add('<h1>TAFRA Studio Code Quality Report</h1>');
    Lines.Add('<p><strong>Project:</strong> ' + HtmlEncode(AReport.ProjectPath) + '<br>');
    Lines.Add('<strong>Scope:</strong> ' + HtmlEncode(AReport.ScopeDescription) + '<br>');
    Lines.Add('<strong>Generated:</strong> ' + HtmlEncode(DateTimeToStr(AReport.GeneratedAt)) + '<br>');
    Lines.Add('<strong>Findings:</strong> ' + IntToStr(AReport.Findings.Count) +
      ' (Critical: ' + IntToStr(AReport.CountBySeverity(cqsCritical)) +
      ', Warnings: ' + IntToStr(AReport.CountBySeverity(cqsWarning)) +
      ', Info: ' + IntToStr(AReport.CountBySeverity(cqsInfo)) + ')</p>');
    Lines.Add('<table><thead><tr><th>Tool</th><th>Location</th><th>Category</th>' +
      '<th>Severity</th><th>Risk</th><th>Message</th><th>Recommendation</th></tr></thead><tbody>');
    for I := 0 to AReport.Findings.Count - 1 do
    begin
      Finding := TCodeQualityFinding(AReport.Findings[I]);
      Lines.Add('<tr><td>' + HtmlEncode(Finding.ToolName) + '</td><td>' +
        HtmlEncode(Finding.RelativePath) + '</td><td>' + HtmlEncode(Finding.Category) +
        '</td><td class="' + CodeQualitySeverityToString(Finding.Severity) + '">' +
        HtmlEncode(CodeQualitySeverityToString(Finding.Severity)) + '</td><td>' +
        HtmlEncode(CodeQualityRiskToString(Finding.Risk)) + '</td><td>' +
        HtmlEncode(Finding.MessageText) + '</td><td>' +
        HtmlEncode(Finding.Recommendation) + '</td></tr>');
    end;
    Lines.Add('</tbody></table></body></html>');
    Result := Lines.Text;
  finally
    Lines.Free;
  end;
end;

function TCodeQualityReportExporter.BuildJson(const AReport: TCodeQualityReport
  ): string;
var
  Finding: TCodeQualityFinding;
  Findings: TJSONArray;
  I: Integer;
  Item: TJSONObject;
  Root: TJSONObject;
  Summary: TJSONObject;
begin
  Root := TJSONObject.Create;
  try
    Root.Add('project_path', AReport.ProjectPath);
    Root.Add('scope_description', AReport.ScopeDescription);
    Root.Add('scope_path', AReport.ScopePath);
    Root.Add('generated_at', FormatDateTime('yyyy"-"mm"-"dd"T"hh":"nn":"ss',
      AReport.GeneratedAt));
    Summary := TJSONObject.Create;
    Summary.Add('findings', AReport.Findings.Count);
    Summary.Add('critical', AReport.CountBySeverity(cqsCritical));
    Summary.Add('warnings', AReport.CountBySeverity(cqsWarning));
    Summary.Add('info', AReport.CountBySeverity(cqsInfo));
    Root.Add('summary', Summary);
    Findings := TJSONArray.Create;
    Root.Add('findings', Findings);
    for I := 0 to AReport.Findings.Count - 1 do
    begin
      Finding := TCodeQualityFinding(AReport.Findings[I]);
      Item := TJSONObject.Create;
      Item.Add('tool', Finding.ToolName);
      Item.Add('file_path', Finding.FilePath);
      Item.Add('relative_path', Finding.RelativePath);
      Item.Add('line', Finding.LineNumber);
      Item.Add('column', Finding.ColumnNumber);
      Item.Add('category', Finding.Category);
      Item.Add('severity', CodeQualitySeverityToString(Finding.Severity));
      Item.Add('risk', CodeQualityRiskToString(Finding.Risk));
      Item.Add('message', Finding.MessageText);
      Item.Add('recommendation', Finding.Recommendation);
      Findings.Add(Item);
    end;
    Result := Root.FormatJSON;
  finally
    Root.Free;
  end;
end;

function TCodeQualityReportExporter.SaveReport(const AReport: TCodeQualityReport;
  const AFileName: string; AFormat: TCodeQualityReportFormat): TOperationResult;
var
  Content: string;
  OutputFile: TStringList;
begin
  if not Assigned(AReport) then
    Exit(TOperationResult.Fail('REPORT_MISSING',
      'Run Code Quality before exporting a report.'));

  try
    case AFormat of
      cqrfJson: Content := BuildJson(AReport);
      cqrfCsv: Content := BuildCsv(AReport);
      cqrfHtml: Content := BuildHtml(AReport);
    end;
    OutputFile := TStringList.Create;
    try
      OutputFile.Text := Content;
      OutputFile.SaveToFile(AFileName);
    finally
      OutputFile.Free;
    end;
    Result := TOperationResult.Ok('Code Quality report exported to: ' + AFileName);
  except
    on E: Exception do
      Result := TOperationResult.Fail('REPORT_EXPORT_FAILED',
        'Unable to export the Code Quality report: ' + E.Message);
  end;
end;

end.
