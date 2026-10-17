unit uTestPointLogViewerForm;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, StdCtrls, ExtCtrls, ComCtrls, Dialogs,
  uTestPointLogService, uThemeService;

type
  TTestPointLogViewerForm = class(TForm)
  private
    FService: TTestPointLogService;
    FThemeService: TThemeService;
    FThemeName: string;
    FFileNameEdit: TEdit;
    FBrowseButton: TButton;
    FExportButton: TButton;
    FSearchEdit: TEdit;
    FStatusFilter: TComboBox;
    FAreaFilter: TComboBox;
    FGrid: TListView;
    FDetailsMemo: TMemo;
    FStatusLabel: TLabel;
    FOpenDialog: TOpenDialog;
    FSaveDialog: TSaveDialog;
    FVisibleEntries: TList;
    FSortColumn: Integer;
    FSortAscending: Boolean;
    procedure BrowseClick(Sender: TObject);
    procedure ExportClick(Sender: TObject);
    procedure FilterChange(Sender: TObject);
    procedure GridColumnClick(Sender: TObject; Column: TListColumn);
    procedure GridSelectItem(Sender: TObject; Item: TListItem;
      Selected: Boolean);
    procedure PopulateFilterLists;
    procedure RefreshGrid;
    procedure UpdateStatus;
    function EntryMatches(AEntry: TObject): Boolean;
    function EntryValue(AEntry: TObject; AColumn: Integer): string;
    function CompareEntries(AFirst, ASecond: TObject): Integer;
  public
    constructor Create(AOwner: TComponent; AThemeService: TThemeService;
      const AThemeName: string); reintroduce;
    destructor Destroy; override;
  end;

implementation

uses
  uTestPointLogModel, uResultTypes;

constructor TTestPointLogViewerForm.Create(AOwner: TComponent;
  AThemeService: TThemeService; const AThemeName: string);
var
  LabelControl: TLabel;
  DetailsLabel: TLabel;
begin
  inherited CreateNew(AOwner, 1);
  FThemeService := AThemeService;
  FThemeName := AThemeName;
  FService := TTestPointLogService.Create;
  FVisibleEntries := TList.Create;
  FSortColumn := 0;
  FSortAscending := True;

  Caption := 'Test Point Log Viewer';
  Position := poOwnerFormCenter;
  Width := 1260;
  Height := 760;
  Constraints.MinWidth := 900;
  Constraints.MinHeight := 560;

  LabelControl := TLabel.Create(Self);
  LabelControl.Parent := Self;
  LabelControl.Left := 16;
  LabelControl.Top := 18;
  LabelControl.Caption := 'Test Point JSONL file';

  FFileNameEdit := TEdit.Create(Self);
  FFileNameEdit.Parent := Self;
  FFileNameEdit.Left := 16;
  FFileNameEdit.Top := 40;
  FFileNameEdit.Width := 1050;
  FFileNameEdit.Anchors := [akLeft, akTop, akRight];
  FFileNameEdit.ReadOnly := True;

  FBrowseButton := TButton.Create(Self);
  FBrowseButton.Parent := Self;
  FBrowseButton.Left := 1076;
  FBrowseButton.Top := 38;
  FBrowseButton.Width := 150;
  FBrowseButton.Anchors := [akTop, akRight];
  FBrowseButton.Caption := 'Open log file...';
  FBrowseButton.OnClick := @BrowseClick;

  LabelControl := TLabel.Create(Self);
  LabelControl.Parent := Self;
  LabelControl.Left := 16;
  LabelControl.Top := 80;
  LabelControl.Caption := 'Search';

  FSearchEdit := TEdit.Create(Self);
  FSearchEdit.Parent := Self;
  FSearchEdit.Left := 16;
  FSearchEdit.Top := 102;
  FSearchEdit.Width := 360;
  FSearchEdit.Anchors := [akLeft, akTop];
  FSearchEdit.OnChange := @FilterChange;

  LabelControl := TLabel.Create(Self);
  LabelControl.Parent := Self;
  LabelControl.Left := 390;
  LabelControl.Top := 80;
  LabelControl.Caption := 'Status';

  FStatusFilter := TComboBox.Create(Self);
  FStatusFilter.Parent := Self;
  FStatusFilter.Left := 390;
  FStatusFilter.Top := 102;
  FStatusFilter.Width := 160;
  FStatusFilter.Style := csDropDownList;
  FStatusFilter.OnChange := @FilterChange;

  LabelControl := TLabel.Create(Self);
  LabelControl.Parent := Self;
  LabelControl.Left := 564;
  LabelControl.Top := 80;
  LabelControl.Caption := 'Area';

  FAreaFilter := TComboBox.Create(Self);
  FAreaFilter.Parent := Self;
  FAreaFilter.Left := 564;
  FAreaFilter.Top := 102;
  FAreaFilter.Width := 180;
  FAreaFilter.Style := csDropDownList;
  FAreaFilter.OnChange := @FilterChange;

  FExportButton := TButton.Create(Self);
  FExportButton.Parent := Self;
  FExportButton.Left := 1076;
  FExportButton.Top := 100;
  FExportButton.Width := 150;
  FExportButton.Anchors := [akTop, akRight];
  FExportButton.Caption := 'Export filtered...';
  FExportButton.Enabled := False;
  FExportButton.OnClick := @ExportClick;

  FGrid := TListView.Create(Self);
  FGrid.Parent := Self;
  FGrid.Left := 16;
  FGrid.Top := 138;
  FGrid.Width := 1210;
  FGrid.Height := 400;
  FGrid.Anchors := [akLeft, akTop, akRight, akBottom];
  FGrid.ViewStyle := vsReport;
  FGrid.ReadOnly := True;
  FGrid.RowSelect := True;
  FGrid.GridLines := True;
  FGrid.HideSelection := False;
  FGrid.OnColumnClick := @GridColumnClick;
  FGrid.OnSelectItem := @GridSelectItem;
  FGrid.Columns.Add.Caption := 'Timestamp';
  FGrid.Columns[0].Width := 190;
  FGrid.Columns.Add.Caption := 'Point ID';
  FGrid.Columns[1].Width := 230;
  FGrid.Columns.Add.Caption := 'Area';
  FGrid.Columns[2].Width := 110;
  FGrid.Columns.Add.Caption := 'Module';
  FGrid.Columns[3].Width := 110;
  FGrid.Columns.Add.Caption := 'Status';
  FGrid.Columns[4].Width := 90;
  FGrid.Columns.Add.Caption := 'Duration (ms)';
  FGrid.Columns[5].Width := 100;
  FGrid.Columns.Add.Caption := 'File path';
  FGrid.Columns[6].Width := 300;
  FGrid.Columns.Add.Caption := 'Request ID';
  FGrid.Columns[7].Width := 220;

  DetailsLabel := TLabel.Create(Self);
  DetailsLabel.Parent := Self;
  DetailsLabel.Left := 16;
  DetailsLabel.Top := 550;
  DetailsLabel.Anchors := [akLeft, akBottom];
  DetailsLabel.Caption := 'Selected entry (original JSON)';

  FDetailsMemo := TMemo.Create(Self);
  FDetailsMemo.Parent := Self;
  FDetailsMemo.Left := 16;
  FDetailsMemo.Top := 572;
  FDetailsMemo.Width := 1210;
  FDetailsMemo.Height := 110;
  FDetailsMemo.Anchors := [akLeft, akRight, akBottom];
  FDetailsMemo.ReadOnly := True;
  FDetailsMemo.ScrollBars := ssBoth;
  FDetailsMemo.WordWrap := False;

  FStatusLabel := TLabel.Create(Self);
  FStatusLabel.Parent := Self;
  FStatusLabel.Left := 16;
  FStatusLabel.Top := 696;
  FStatusLabel.Anchors := [akLeft, akBottom];

  FOpenDialog := TOpenDialog.Create(Self);
  FOpenDialog.Filter := 'Test Point JSONL logs (*.jsonl)|*.jsonl|JSON files (*.json)|*.json|All files (*.*)|*.*';
  FOpenDialog.Options := [ofFileMustExist, ofPathMustExist, ofEnableSizing];
  FSaveDialog := TSaveDialog.Create(Self);
  FSaveDialog.Filter := 'CSV files (*.csv)|*.csv|JSON files (*.json)|*.json';
  FSaveDialog.DefaultExt := 'csv';
  FSaveDialog.Options := FSaveDialog.Options + [ofOverwritePrompt];
  PopulateFilterLists;
  UpdateStatus;
  if Assigned(FThemeService) then
    FThemeService.ApplyTheme(Self, FThemeName);
end;

destructor TTestPointLogViewerForm.Destroy;
begin
  FVisibleEntries.Free;
  FService.Free;
  inherited Destroy;
end;

procedure TTestPointLogViewerForm.BrowseClick(Sender: TObject);
var
  ResultInfo: TOperationResult;
begin
  if not FOpenDialog.Execute then
    Exit;
  ResultInfo := FService.LoadFromFile(FOpenDialog.FileName);
  try
    if not ResultInfo.Success then
    begin
      MessageDlg('Open Test Point log', ResultInfo.MessageText, mtError, [mbOK], 0);
      Exit;
    end;
    FFileNameEdit.Text := FOpenDialog.FileName;
    PopulateFilterLists;
    RefreshGrid;
  finally
    ResultInfo.Free;
  end;
end;

procedure TTestPointLogViewerForm.PopulateFilterLists;
var
  Entry: TTestPointLogEntry;
  I: Integer;
begin
  FStatusFilter.Items.BeginUpdate;
  FAreaFilter.Items.BeginUpdate;
  try
    FStatusFilter.Items.Clear;
    FAreaFilter.Items.Clear;
    FStatusFilter.Items.Add('All statuses');
    FAreaFilter.Items.Add('All areas');
    for I := 0 to FService.Entries.Count - 1 do
    begin
      Entry := TTestPointLogEntry(FService.Entries[I]);
      if (Entry.Status <> '') and (FStatusFilter.Items.IndexOf(Entry.Status) < 0) then
        FStatusFilter.Items.Add(Entry.Status);
      if (Entry.Area <> '') and (FAreaFilter.Items.IndexOf(Entry.Area) < 0) then
        FAreaFilter.Items.Add(Entry.Area);
    end;
    FStatusFilter.ItemIndex := 0;
    FAreaFilter.ItemIndex := 0;
  finally
    FAreaFilter.Items.EndUpdate;
    FStatusFilter.Items.EndUpdate;
  end;
end;

function TTestPointLogViewerForm.EntryMatches(AEntry: TObject): Boolean;
var
  Entry: TTestPointLogEntry;
  SearchText: string;
  Values: string;
begin
  Result := False;
  Entry := TTestPointLogEntry(AEntry);
  if (FStatusFilter.ItemIndex > 0) and
    (not SameText(Entry.Status, FStatusFilter.Text)) then
    Exit;
  if (FAreaFilter.ItemIndex > 0) and
    (not SameText(Entry.Area, FAreaFilter.Text)) then
    Exit;
  SearchText := LowerCase(Trim(FSearchEdit.Text));
  if SearchText = '' then
    Exit(True);
  Values := LowerCase(Entry.Timestamp + ' ' + Entry.PointId + ' ' + Entry.Area +
    ' ' + Entry.ModuleName + ' ' + Entry.FolderPath + ' ' + Entry.FilePath + ' ' +
    Entry.Status + ' ' + Entry.Context + ' ' + Entry.RequestId);
  Result := Pos(SearchText, Values) > 0;
end;

function TTestPointLogViewerForm.EntryValue(AEntry: TObject; AColumn: Integer): string;
var
  Entry: TTestPointLogEntry;
begin
  Entry := TTestPointLogEntry(AEntry);
  case AColumn of
    0: Result := Entry.Timestamp;
    1: Result := Entry.PointId;
    2: Result := Entry.Area;
    3: Result := Entry.ModuleName;
    4: Result := Entry.Status;
    5: Result := IntToStr(Entry.DurationMS);
    6: Result := Entry.FilePath;
    7: Result := Entry.RequestId;
  else
    Result := '';
  end;
end;

function TTestPointLogViewerForm.CompareEntries(AFirst, ASecond: TObject): Integer;
var
  FirstEntry: TTestPointLogEntry;
  SecondEntry: TTestPointLogEntry;
begin
  FirstEntry := TTestPointLogEntry(AFirst);
  SecondEntry := TTestPointLogEntry(ASecond);
  if FSortColumn = 5 then
  begin
    if FirstEntry.DurationMS < SecondEntry.DurationMS then Result := -1
    else if FirstEntry.DurationMS > SecondEntry.DurationMS then Result := 1
    else Result := 0;
  end
  else
    Result := CompareText(EntryValue(AFirst, FSortColumn),
      EntryValue(ASecond, FSortColumn));
  if not FSortAscending then
    Result := -Result;
end;

procedure TTestPointLogViewerForm.RefreshGrid;
var
  I, J: Integer;
  Entry: TTestPointLogEntry;
  Item: TListItem;
  Temp: Pointer;
begin
  FVisibleEntries.Clear;
  for I := 0 to FService.Entries.Count - 1 do
    if EntryMatches(TObject(FService.Entries[I])) then
      FVisibleEntries.Add(FService.Entries[I]);
  for I := 0 to FVisibleEntries.Count - 2 do
    for J := I + 1 to FVisibleEntries.Count - 1 do
      if CompareEntries(TObject(FVisibleEntries[I]), TObject(FVisibleEntries[J])) > 0 then
      begin
        Temp := FVisibleEntries[I];
        FVisibleEntries[I] := FVisibleEntries[J];
        FVisibleEntries[J] := Temp;
      end;

  FGrid.Items.BeginUpdate;
  try
    FGrid.Items.Clear;
    for I := 0 to FVisibleEntries.Count - 1 do
    begin
      Entry := TTestPointLogEntry(FVisibleEntries[I]);
      Item := FGrid.Items.Add;
      Item.Caption := Entry.Timestamp;
      Item.SubItems.Add(Entry.PointId);
      Item.SubItems.Add(Entry.Area);
      Item.SubItems.Add(Entry.ModuleName);
      Item.SubItems.Add(Entry.Status);
      Item.SubItems.Add(IntToStr(Entry.DurationMS));
      Item.SubItems.Add(Entry.FilePath);
      Item.SubItems.Add(Entry.RequestId);
      Item.Data := Entry;
    end;
  finally
    FGrid.Items.EndUpdate;
  end;
  FDetailsMemo.Clear;
  FExportButton.Enabled := FVisibleEntries.Count > 0;
  UpdateStatus;
end;

procedure TTestPointLogViewerForm.FilterChange(Sender: TObject);
begin
  RefreshGrid;
end;

procedure TTestPointLogViewerForm.GridColumnClick(Sender: TObject;
  Column: TListColumn);
begin
  if FSortColumn = Column.Index then
    FSortAscending := not FSortAscending
  else
  begin
    FSortColumn := Column.Index;
    FSortAscending := True;
  end;
  RefreshGrid;
end;

procedure TTestPointLogViewerForm.GridSelectItem(Sender: TObject;
  Item: TListItem; Selected: Boolean);
begin
  if Selected and Assigned(Item) and Assigned(Item.Data) then
    FDetailsMemo.Lines.Text := TTestPointLogEntry(Item.Data).RawJson;
end;

procedure TTestPointLogViewerForm.UpdateStatus;
var
  InvalidText: string;
  I: Integer;
  TotalDurationMS: Int64;
begin
  TotalDurationMS := 0;
  for I := 0 to FVisibleEntries.Count - 1 do
    Inc(TotalDurationMS, TTestPointLogEntry(FVisibleEntries[I]).DurationMS);
  if FService.InvalidLineCount > 0 then
    InvalidText := '  Ignored invalid lines: ' + IntToStr(FService.InvalidLineCount)
  else
    InvalidText := '';
  FStatusLabel.Caption := 'Records in grid: ' + IntToStr(FVisibleEntries.Count) +
    '  Duration total: ' + FormatFloat('0.###', TotalDurationMS / 1000.0) +
    ' seconds' + InvalidText;
end;

procedure TTestPointLogViewerForm.ExportClick(Sender: TObject);
var
  ExportFormat: TTestPointLogExportFormat;
  OutputFileName: string;
  ResultInfo: TOperationResult;
begin
  if FVisibleEntries.Count = 0 then
    Exit;
  if FSaveDialog.FilterIndex = 2 then
    FSaveDialog.DefaultExt := 'json'
  else
    FSaveDialog.DefaultExt := 'csv';
  if not FSaveDialog.Execute then
    Exit;
  if FSaveDialog.FilterIndex = 2 then
  begin
    ExportFormat := tplefJson;
    FSaveDialog.DefaultExt := 'json';
  end
  else
  begin
    ExportFormat := tplefCsv;
    FSaveDialog.DefaultExt := 'csv';
  end;
  OutputFileName := FSaveDialog.FileName;
  if ExtractFileExt(OutputFileName) = '' then
    OutputFileName := OutputFileName + '.' + FSaveDialog.DefaultExt;
  ResultInfo := FService.ExportEntries(FVisibleEntries, OutputFileName,
    ExportFormat);
  try
    if ResultInfo.Success then
      MessageDlg('Export Test Point log', ResultInfo.MessageText, mtInformation,
        [mbOK], 0)
    else
      MessageDlg('Export Test Point log', ResultInfo.MessageText, mtError,
        [mbOK], 0);
  finally
    ResultInfo.Free;
  end;
end;

end.
