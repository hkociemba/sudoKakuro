unit main;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.Menus, Vcl.StdCtrls;

type
  TForm1 = class(TForm)
    PopupMenu1: TPopupMenu;
    Memo1: TMemo;
    BSolve: TButton;
    Paste1: TMenuItem;
    CheckOutlineBoxes: TCheckBox;
    BAddSolution: TButton;
    BReduce: TButton;
    GroupBox1: TGroupBox;
    CBSudokuX: TCheckBox;
    CBSudokuP: TCheckBox;
    procedure PasteClick(Sender: TObject);
    procedure BSolveClick(Sender: TObject);
    procedure BAddSolutionClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    { Private-Deklarationen }
  public
    function PrintCurrentPuzzle(a: array of Integer): Integer;
  end;

const
  DIM = 9;
  B_ROW = 3;
  B_COL = 3;

  perm3: array [0 .. 5, 0 .. 2] of Integer = ((0, 1, 2), (0, 2, 1), (1, 0, 2),
    (1, 2, 0), (2, 0, 1), (2, 1, 0));
  perm4: array [0 .. 23, 0 .. 3] of Integer = ((0, 1, 2, 3), (0, 1, 3, 2),
    (0, 2, 1, 3), (0, 2, 3, 1), (0, 3, 1, 2), (0, 3, 2, 1), (1, 0, 2, 3),
    (1, 0, 3, 2), (1, 2, 0, 3), (1, 2, 3, 0), (1, 3, 0, 2), (1, 3, 2, 0),
    (2, 0, 1, 3), (2, 0, 3, 1), (2, 1, 0, 3), (2, 1, 3, 0), (2, 3, 0, 1),
    (2, 3, 1, 0), (3, 0, 1, 2), (3, 0, 2, 1), (3, 1, 0, 2), (3, 1, 2, 0),
    (3, 2, 0, 1), (3, 2, 1, 0));

var
  Form1: TForm1;

implementation

uses ClipBrd, console, StrUtils;

{$R *.dfm}

var
  n_clauses_eff: Integer;
  clauses, output, errors, solution: TStringList;
  sums, rc_set: Array [0 .. DIM * DIM - 1] of Integer;

  // the variable name for a candidate in row r, column c and value v
  // r>=0,x>=0, v>=1 and hence varname>=1.
function varname(r, c, v: Integer): String;
begin
  result := IntToStr(r * DIM * DIM + c * DIM + v);
end;

// returns row for cell with index in box
function bk_to_r(box, index: Integer): Integer;
begin
  result := B_ROW * (box div B_ROW) + index div B_COL
end;

// returns column for cell with index in box
function bk_to_c(box, index: Integer): Integer;
begin
  result := B_COL * (box mod B_ROW) + index mod B_COL
end;

procedure cell_clauses(clauses: TStringList);
var
  row, col, num, num2: Integer;
  s: String;
begin
  for row := 0 to DIM - 1 do
    for col := 0 to DIM - 1 do
    begin
      // each cell contains at least one number, dim^2 clauses
      s := '';
      for num := 1 to DIM do // iterate over numbers
        s := s + varname(row, col, num) + ' ';
      clauses.Add(s + '0');
      Inc(n_clauses_eff);

      // never two different numbers in one cell, dim^2*Binomial(dim,2) clauses
      for num := 1 to DIM - 1 do
        for num2 := num + 1 to DIM do
        begin
          clauses.Add('-' + varname(row, col, num) + ' -' + varname(row, col,
            num2) + ' 0');
          Inc(n_clauses_eff);
        end;
    end;
end;

procedure row_clauses(clauses: TStringList);
var
  row, col, col2, num: Integer;
  s: String;
begin
  for row := 0 to DIM - 1 do
    for num := 1 to DIM do
    begin
      // each row contains each number at least once, dim^2 clauses
      s := '';
      for col := 0 to DIM - 1 do // iterate over columns of row
        s := s + varname(row, col, num) + ' ';
      clauses.Add(s + '0');
      Inc(n_clauses_eff);

      // never two same numbers in one row, dim^2*Binomial(dim,2) clauses
      for col := 0 to DIM - 2 do
        for col2 := col + 1 to DIM - 1 do
        begin
          clauses.Add('-' + varname(row, col, num) + ' -' + varname(row, col2,
            num) + ' 0');
          Inc(n_clauses_eff);
        end;
    end;
end;

procedure column_clauses(clauses: TStringList);
var
  row, row2, col, num: Integer;
  s: String;
begin
  for col := 0 to DIM - 1 do
    for num := 1 to DIM do
    begin
      // each column contains each number at least once, dim^2 clauses
      s := '';
      for row := 0 to DIM - 1 do // iterate over rows of column
        s := s + varname(row, col, num) + ' ';
      clauses.Add(s + '0');
      Inc(n_clauses_eff);

      // never two same numbers in one column, dim^2*Binomial(dim,2) clauses
      for row := 0 to DIM - 2 do
        for row2 := row + 1 to DIM - 1 do
        begin
          clauses.Add('-' + varname(row, col, num) + ' -' + varname(row2, col,
            num) + ' 0');
          Inc(n_clauses_eff);
        end;
    end;
end;

procedure block_clauses(clauses: TStringList);
var
  blk, k, k2, num: Integer;
  s: String;
begin
  for blk := 0 to DIM - 1 do // block
  begin
    for num := 1 to DIM do
    begin
      // each block contains each number at least once, dim^2 clauses
      s := '';
      for k := 0 to DIM - 1 do // iterate over block elements
        s := s + varname(bk_to_r(blk, k), bk_to_c(blk, k), num) + ' ';
      clauses.Add(s + '0');
      Inc(n_clauses_eff);
      // never two same numbers in same block, dim^2*Binomial(dim,2) clauses
      for k := 0 to DIM - 2 do
        for k2 := k + 1 to DIM - 1 do
        begin
          clauses.Add('-' + varname(bk_to_r(blk, k), bk_to_c(blk, k), num) +
            ' -' + varname(bk_to_r(blk, k2), bk_to_c(blk, k2), num) + ' 0');
          Inc(n_clauses_eff);
        end;
    end;
  end;
end;

procedure dp_clauses(clauses: TStringList);
var
  row, col, num, rd, cd1, rd2, cd2: Integer;
begin
  for row := 0 to 7 do
    for col := 0 to 8 do
      for num := 1 to 9 do
      begin
        rd := row + 1;
        cd1 := col - 1;
        cd2 := col + 1;
        if cd1 >= 0 then
        begin
          clauses.Add('-' + varname(row, col, num) + ' -' + varname(rd, cd1,
            num) + ' 0');
          Inc(n_clauses_eff);
        end;
        if cd2 <= 8 then
        begin
          clauses.Add('-' + varname(row, col, num) + ' -' + varname(rd, cd2,
            num) + ' 0');
          Inc(n_clauses_eff);
        end;
      end;
end;

procedure sumClauses(clauses: TStringList);
var
  i, j, k, m, p, row, col: Integer;
  p3: array [0 .. 2] of Integer;
  p4: array [0 .. 3] of Integer;
begin
  if sums[0] <> 0 then // upper left corner
  begin
    for i := 1 to 8 do
      for j := i + 1 to 9 do
        if i + j <> sums[0] then
        begin
          clauses.Add('-' + varname(0, 1, i) + ' -' + varname(1, 0, j) + ' 0');
          clauses.Add('-' + varname(0, 1, j) + ' -' + varname(1, 0, i) + ' 0');
          Inc(n_clauses_eff, 2);
        end;
  end;
  if sums[8] <> 0 then // upper right corner
  begin
    for i := 1 to 8 do
      for j := i + 1 to 9 do
        if i + j <> sums[8] then
        begin
          clauses.Add('-' + varname(0, 7, i) + ' -' + varname(1, 8, j) + ' 0');
          clauses.Add('-' + varname(0, 7, j) + ' -' + varname(1, 8, i) + ' 0');
          Inc(n_clauses_eff, 2);
        end;
  end;
  if sums[80] <> 0 then // lower right corner
  begin
    for i := 1 to 8 do
      for j := i + 1 to 9 do
        if i + j <> sums[80] then
        begin
          clauses.Add('-' + varname(7, 8, i) + ' -' + varname(8, 7, j) + ' 0');
          clauses.Add('-' + varname(7, 8, j) + ' -' + varname(8, 7, i) + ' 0');
          Inc(n_clauses_eff, 2);
        end;
  end;
  if sums[72] <> 0 then // lower left corner
  begin
    for i := 1 to 8 do
      for j := i + 1 to 9 do
        if i + j <> sums[72] then
        begin
          clauses.Add('-' + varname(7, 0, i) + ' -' + varname(8, 1, j) + ' 0');
          clauses.Add('-' + varname(7, 0, j) + ' -' + varname(8, 1, i) + ' 0');
          Inc(n_clauses_eff, 2);
        end;
  end;
  for row := 1 to 7 do // left side
  begin
    if sums[9 * row] <> 0 then
    begin
      for i := 1 to 7 do
        for j := i + 1 to 8 do
          for k := j + 1 to 9 do
            if i + j + k <> sums[9 * row] then
            begin
              p3[0] := i;
              p3[1] := j;
              p3[2] := k;
              for p := 0 to 5 do
                clauses.Add('-' + varname(row - 1, 0, p3[perm3[p, 0]]) + ' -' +
                  varname(row, 1, p3[perm3[p, 1]]) + ' -' + varname(row + 1, 0,
                  p3[perm3[p, 2]]) + ' 0');
              Inc(n_clauses_eff, 6);
            end;
    end;
  end;

  for row := 1 to 7 do // right side
  begin
    if sums[9 * row + 8] <> 0 then
    begin
      for i := 1 to 7 do
        for j := i + 1 to 8 do
          for k := j + 1 to 9 do
            if i + j + k <> sums[9 * row + 8] then
            begin
              p3[0] := i;
              p3[1] := j;
              p3[2] := k;
              for p := 0 to 5 do
                clauses.Add('-' + varname(row - 1, 8, p3[perm3[p, 0]]) + ' -' +
                  varname(row, 7, p3[perm3[p, 1]]) + ' -' + varname(row + 1, 8,
                  p3[perm3[p, 2]]) + ' 0');
              Inc(n_clauses_eff, 6);

            end;
    end;
  end;

  for col := 1 to 7 do // upper side
  begin
    if sums[col] <> 0 then
    begin
      for i := 1 to 7 do
        for j := i + 1 to 8 do
          for k := j + 1 to 9 do
            if i + j + k <> sums[col] then
            begin
              p3[0] := i;
              p3[1] := j;
              p3[2] := k;
              for p := 0 to 5 do
                clauses.Add('-' + varname(0, col - 1, p3[perm3[p, 0]]) + ' -' +
                  varname(0, col + 1, p3[perm3[p, 1]]) + ' -' + varname(1, col,
                  p3[perm3[p, 2]]) + ' 0');
              Inc(n_clauses_eff, 6);
            end;
    end;
  end;

  for col := 1 to 7 do // lower side
  begin
    if sums[72 + col] <> 0 then
    begin
      for i := 1 to 7 do
        for j := i + 1 to 8 do
          for k := j + 1 to 9 do
            if i + j + k <> sums[72 + col] then
            begin
              p3[0] := i;
              p3[1] := j;
              p3[2] := k;
              for p := 0 to 5 do
                clauses.Add('-' + varname(8, col - 1, p3[perm3[p, 0]]) + ' -' +
                  varname(8, col + 1, p3[perm3[p, 1]]) + ' -' + varname(7, col,
                  p3[perm3[p, 2]]) + ' 0');
              Inc(n_clauses_eff, 6);
            end;
    end;
  end;

  for row := 1 to 7 do
    for col := 1 to 7 do // inner cells
    begin
      if sums[9 * row + col] <> 0 then
      begin
        for i := 1 to 6 do
          for j := i + 1 to 7 do
            for k := j + 1 to 8 do
              for m := k + 1 to 9 do
                if i + j + k + m <> sums[9 * row + col] then
                begin
                  p4[0] := i;
                  p4[1] := j;
                  p4[2] := k;
                  p4[3] := m;
                  for p := 0 to 23 do
                  begin
                    clauses.Add('-' + varname(row - 1, col, p4[perm4[p, 0]]) +
                      ' -' + varname(row + 1, col, p4[perm4[p, 1]]) + ' -' +
                      varname(row, col - 1, p4[perm4[p, 2]]) + ' -' +
                      varname(row, col + 1, p4[perm4[p, 3]]) + ' 0');
                  end;
                  Inc(n_clauses_eff, 24);
                end;
      end;
    end;

end;

procedure sudokuX_clauses(clauses: TStringList);
var
  k, k2, num: Integer;
  s: String;
begin
  for num := 1 to DIM do
  begin
    s := '';
    for k := 0 to DIM - 1 do // iterate over diagonal
      s := s + varname(k, k, num) + ' ';
    clauses.Add(s + '0');
    Inc(n_clauses_eff);

    s := '';
    for k := 0 to DIM - 1 do // iterate over antidiagonal
      s := s + varname(DIM - 1 - k, k, num) + ' ';
    clauses.Add(s + '0');
    Inc(n_clauses_eff);

    for k := 0 to DIM - 2 do
      for k2 := k + 1 to DIM - 1 do
      begin
        clauses.Add('-' + varname(k, k, num) + ' -' + varname(k2, k2,
          num) + ' 0');
        Inc(n_clauses_eff);
      end;
    for k := 0 to DIM - 2 do
      for k2 := k + 1 to DIM - 1 do
      begin
        clauses.Add('-' + varname(DIM - 1 - k, k, num) + ' -' +
          varname(DIM - 1 - k2, k2, num) + ' 0');
        Inc(n_clauses_eff);
      end;
  end;
end;

procedure sudokuP_clauses(clauses: TStringList);
var
  pos, blk, blk2, num: Integer;
  s: String;
begin
  for pos := 0 to DIM - 1 do // positions
  begin
    for num := 1 to DIM do
    begin
      // each pos contains each number at least once, dim^2 clauses
      s := '';
      for blk := 0 to DIM - 1 do // iterate over blocks
        s := s + varname(bk_to_r(blk, pos), bk_to_c(blk, pos), num) + ' ';
      clauses.Add(s + '0');
      Inc(n_clauses_eff);
      // never two same numbers in same position, dim^2*Binomial(dim,2) clauses
      for blk := 0 to DIM - 2 do
        for blk2 := blk + 1 to DIM - 1 do
        begin
          clauses.Add('-' + varname(bk_to_r(blk, pos), bk_to_c(blk, pos), num) +
            ' -' + varname(bk_to_r(blk2, pos), bk_to_c(blk2, pos), num) + ' 0');
          Inc(n_clauses_eff);
        end;
    end;
  end;
end;

function custom_split(input: string): TArray<string>;
var
  delimiterSet: array [0 .. 1] of char;
  // split works with char array, not a single char
begin
  delimiterSet[0] := ' '; // some character
  delimiterSet[1] := '|';
  result := input.Split(delimiterSet);
end;

function makeDefString(sl: TStringList): String;
var
  snew, goodSet, badSet: TStringList;
  s_split: TArray<String>;
  i, j: Integer;
  test: Boolean;
  s: String;
begin
  snew := TStringList.Create;
  goodSet := TStringList.Create;
  badSet := TStringList.Create;

  // multi line format
  goodSet.Add('.'); // valid symbols in puzzle definition strings
  goodSet.Add('_');
  goodSet.Add('__');

  for i := 0 to 30 do
    goodSet.Add(IntToStr(i));
  for i := 0 to 9 do
    goodSet.Add('0' + IntToStr(i));

  for i := 0 to sl.Count - 1 do
  begin
    result := '';
    s_split := custom_split(sl[i]);
    for j := 0 to Length(s_split) - 1 do
    begin
      if badSet.IndexOf(s_split[j]) <> -1 then
        break;
      if goodSet.IndexOf(s_split[j]) = -1 then
        continue;

      if s_split[j] = '' then
        continue;
      if pos('_', s_split[j]) > 0 then
        s_split[j] := '0';
      // used in some testsuites for empty position
      if s_split[j] = '00' then
        s_split[j] := '0';

      result := result + s_split[j] + ' ';
    end;
    if result <> '' then
      snew.Add(result);
  end;
  result := '';
  for i := 0 to snew.Count - 1 do
    result := result + snew[i] + ' ';

  snew.Free;
  goodSet.Free;
  badSet.Free;
end;

function initSums(s: String): Boolean;
var
  i, r, c, n, idx: Integer;
  data: TArray<string>;
  t: String;
begin

  for i := 0 to DIM * DIM - 1 do
    sums[i] := 0;

  s := s.ToUpper;
  t := '';
  for i := 1 to Length(s) do
  begin
    if s[i] <> '.' then
      t := t + s[i]
    else
      t := t + ' . '
  end;
  s := t;

  data := custom_split(s);
  n := Length(data);
  idx := 0;
  for i := 0 to n - 1 do
    if data[i] <> '' then
    begin
      data[idx] := data[i];
      Inc(idx);
    end;

  try
    for i := 0 to DIM * DIM - 1 do
    begin
      r := i div DIM;
      c := i mod DIM;
      if (data[i] = '.') or (data[i] = '0') then
        continue;
      n := StrToInt(data[i]);
      sums[i] := n;
    end;
  except
    Exit(false);
  end;
  result := true;
end;

function generate_cnf(clauses: TStringList): Integer;
var
  DIM, n_variables: Integer;
  // n_clauses: UInt64;
begin
  n_clauses_eff := 0;
  DIM := B_ROW * B_COL;
  n_variables := DIM * DIM * DIM;
  clauses.Clear;
  clauses.Add('c CNF file in DIMACS format');
  clauses.Add('dummy'); // clauses.Strings[2]
  cell_clauses(clauses);
  row_clauses(clauses);
  column_clauses(clauses);
  block_clauses(clauses);
  dp_clauses(clauses);
  sumClauses(clauses);
  if Form1.CBSudokuX.Checked then
    sudokuX_clauses(clauses);
  if Form1.CBSudokuP.Checked then
    sudokuP_clauses(clauses);

  clauses.Strings[1] := 'p cnf ' + IntToStr(n_variables) + ' ' +
    IntToStr(n_clauses_eff);
  result := n_clauses_eff;
end;

function decode_solution(output, solution: TStringList): Boolean;
var
  a: array of array of Integer;
  i, r, c, v, n: Integer;
  solution_raw, s: String;
  solution_split: TArray<String>;
begin
  Setlength(a, DIM, DIM);
  solution_raw := '';
  for i := 0 to output.Count - 1 do
  begin
    s := output.Strings[i];
    if s[1] = 's' then
    begin
      if ContainsText(s, 'UNSATISFIABLE') then
      begin
        Form1.Memo1.Lines.Add('UNSATISFIABLE');
        Exit(false);
      end;
      Form1.Memo1.Lines.Add(copy(s, 3, Length(s)) + ':');
    end;

    if (s[1] = 'c') and ContainsText(s, 'Total wall clock time') then
    begin
      solution_split := custom_split(s);
      Form1.Memo1.Lines.Add(copy(s, 3, Length(s)));
    end;

    if s[1] = 'v' then
      solution_raw := solution_raw + copy(s, 3, Length(s));
  end;
  solution_split := custom_split(solution_raw);
  for i := 0 to Length(solution_split) - 1 do
    try
      n := StrToInt(solution_split[i]);
      // if Abs(n) > DIM * DIM * DIM then // eventually commander variables
      // continue;
      if n > 0 then
      begin
        v := (n - 1) mod DIM + 1;
        n := (n - 1) div DIM;
        c := n mod DIM;
        r := n div DIM;
        a[r, c] := v;
        rc_set[DIM * r + c] := v; // update puzzle definition
      end;
    except
      on EConvertError do
    end;

  for r := 0 to DIM - 1 do
  begin
    s := '';
    for c := 0 to DIM - 1 do
      if DIM < 10 then
        s := s + Format('%2d', [a[r, c]]);
    solution.Add(s) // in the current version we do not use solution any more
  end;
  result := true;
end;

procedure TForm1.BSolveClick(Sender: TObject);
begin
  // clauses := TStringList.Create;
  // output := TStringList.Create;
  // errors := TStringList.Create;
  // solution := TStringList.Create;
  clauses.Clear;
  output.Clear;
  errors.Clear;
  solution.Clear;
  generate_cnf(clauses);
  clauses.SaveToFile('cnf.txt');

  GetConsoleOutput('java.exe -jar org.sat4j.core.jar cnf.txt', output, errors);

  if decode_solution(output, solution) then
  begin
    PrintCurrentPuzzle(rc_set);
    BAddSolution.Enabled := true;
  end;
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  clauses := TStringList.Create;
  output := TStringList.Create;
  errors := TStringList.Create;
  solution := TStringList.Create;
end;

procedure TForm1.PasteClick(Sender: TObject);
var
  sl: TStringList;
  s, defstring: String;
begin
  sl := TStringList.Create;
  s := Clipboard.AsText;
  sl.Text := s;

  defstring := makeDefString(sl);
  if not initSums(defstring) then
  begin
    Memo1.Lines.Add('+-------------------------------------------+');
    Memo1.Lines.Add('| Cannot paste puzzle! Wrong format.        |');
    Memo1.Lines.Add('+-------------------------------------------+');
    Memo1.Lines.Add('');
    sl.Free;
    Exit;
  end;
  Memo1.Lines.Add('');
  PrintCurrentPuzzle(sums);
  sl.Free;
  BSolve.Enabled := true;
  BAddSolution.Enabled := false;
end;

function seperatorLine(sz: Integer): String;
var
  i, j: Integer;
begin
  result := ' +';
  for i := 0 to B_ROW - 1 do
  begin
    for j := 0 to B_COL - 1 do
      result := result + StringOfChar('-', sz);
    result := result + '-+';
  end;
end;

function TForm1.PrintCurrentPuzzle(a: array of Integer): Integer;
// returns number of unfilled cells
var
  i, r, c, sz: Integer;
  s, s2, form: String;
begin
  sz := 2;
  for i := 1 to DIM * DIM - 1 do
  begin
    if a[i] > 9 then
    begin
      sz := 3;
      break;
    end;
  end;
  if sz = 2 then
    form := '%2s'
  else
    form := '%3s';
  if CheckOutlineBoxes.Checked then
  begin
    result := 0;
    for r := 0 to DIM - 1 do
    begin
      s := '';
      if r mod B_ROW = 0 then
      begin
        Memo1.Lines.Add(seperatorLine(sz));
      end;
      for c := 0 to DIM - 1 do
      begin
        if a[DIM * r + c] = 0 then
        begin
          s2 := '.';
          Inc(result);
        end
        else
          s2 := IntToStr(a[DIM * r + c]);
        if c mod B_COL = 0 then
          s2 := ' |' + Format(form, [s2])
        else
          s2 := Format(form, [s2]);
        s := s + s2;
      end;
      s := s + ' |';
      Memo1.Lines.Add(s);
    end;
    Memo1.Lines.Add(seperatorLine(sz));
    Memo1.Lines.Add('');
  end
  else
  begin
    result := 0;
    for r := 0 to DIM - 1 do
    begin
      s := '';
      for c := 0 to DIM - 1 do
      begin
        if a[DIM * r + c] = 0 then
        begin
          s2 := '.';
          Inc(result);
        end
        else
          s2 := IntToStr(a[DIM * r + c]);
        s := s + Format(form, [s2]);
      end;
      Memo1.Lines.Add(s);
    end;
    Memo1.Lines.Add('');
  end;
  if sz = 2 then // one line display
  begin
    s := '';
    for r := 0 to DIM - 1 do
      for c := 0 to DIM - 1 do
        if rc_set[DIM * r + c] = 0 then
          s := s + '.'
        else
          s := s + IntToStr(rc_set[DIM * r + c]);
    Memo1.Lines.Add(s);
    Memo1.Lines.Add('');
  end;

end;

procedure addSolution;
var
  clauses: TStringList;
  line_split: TArray<String>;
  s: String;
var
  i, j, col: Integer;
begin
  clauses := TStringList.Create;
  clauses.LoadFromFile('cnf.txt');
  s := '';
  for i := 0 to solution.Count - 1 do
  begin
    col := 0;
    line_split := custom_split(solution.Strings[i]);
    for j := 0 to Length(line_split) - 1 do
    begin
      if line_split[j] = '' then
        continue;
      s := s + '-' + varname(i, col, StrToInt(line_split[j])) + ' ';
      Inc(col);
    end;
  end;
  clauses.Add(s + ' 0');

  // Increment number of clauses
  s := clauses.Strings[1];
  line_split := custom_split(s);
  s := '';
  for j := 0 to Length(line_split) - 2 do
    s := s + line_split[j] + ' ';
  s := s + IntToStr(StrToInt(line_split[Length(line_split) - 1]) + 1);
  clauses.Strings[1] := s;
  clauses.SaveToFile('cnf.txt');
  clauses.Free;
end;

procedure TForm1.BAddSolutionClick(Sender: TObject);
begin
  addSolution;
  solution.Clear;
  GetConsoleOutput('java.exe -jar org.sat4j.core.jar cnf.txt', output, errors);

  if decode_solution(output, solution) = true then
    PrintCurrentPuzzle(rc_set);
  BSolve.Enabled := false;
end;

end.
