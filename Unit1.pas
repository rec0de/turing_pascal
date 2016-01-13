unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Math, ExtCtrls, Grids, ComCtrls;

type
  TForm1 = class(TForm)
    Panel1: TPanel;
    Panel2: TPanel;
    Panel3: TPanel;
    Panel4: TPanel;
    Panel5: TPanel;
    Panel6: TPanel;
    Panel7: TPanel;
    Panel8: TPanel;
    Panel9: TPanel;
    Panel10: TPanel;
    Button2: TButton;
    Panel11: TPanel;
    Button3: TButton;
    OpenDialog1: TOpenDialog;
    StringGrid1: TStringGrid;
    Timer1: TTimer;
    Button1: TButton;
    TrackBar1: TTrackBar;
    Label1: TLabel;
    Edit1: TEdit;
    Button4: TButton;
    Label2: TLabel;
    Label3: TLabel;
    procedure Button2Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
    procedure TrackBar1Change(Sender: TObject);
    procedure Button4Click(Sender: TObject);
  private
    { Private-Deklarationen }
  public
    { Public-Deklarationen }
  end;

var
  Form1: TForm1;
  s_accepting: string;
  s_start: string;
  headpos: integer;
  state: string;
  accepting: integer;
  band: Array of string;
  alphabet: Array of string;
  states: Array of string;
  qdata: Array of Array of Array of string;
  steps: integer;

implementation

{$R *.dfm}

// Note:
// This code depends in the initial assumption that single characters of the input alphabet are exactly one ascii character long.
// The file format specified would be incapable of storing turing machines using longer characters as the Band input does not contain any delimiting character.

Function GetBand(index: Integer) : String;
begin
  // Transform index to positive natural number
  If index <= 0 then begin
    index := Abs(index * 2);
  end
  Else begin
    index := index*2 - 1;
  end;

  // Check array size
  If(index >= Length(band)) then begin
    Result := '#';
  end
  Else begin
    If band[index] = '' then begin
      Result := '#';
    end
    Else begin
      Result := band[index];
    end;
  end;
end;

Procedure SetBand(index: integer; value: string);
begin
  // Transform index to positive natural number
  If index <= 0 then begin
    index := Abs(index * 2);
  end
  Else begin
    index := index*2 - 1;
  end;

  // Check array size , increment if needed
  If(index >= Length(band)) then begin
    SetLength(band, index+1);
  end;

  // Write value to band
  band[index] := value;
end;

// Import Band data to array
Procedure LoadBand(input: string);
var i: integer;
begin
  For i := 1 to Length(input) do begin
    SetBand((i-1), input[i]);
  end;
end;

// Find normalized integer corresponding to input
Function NormalizeAlphabet(input: string) : Integer;
var i: integer; success: Boolean;
begin
   success := false;
   For i := 0 to Length(alphabet)-1 do begin
    If alphabet[i] = input then begin
      Result := i;
      success := true;
      Break;
    end;
   end;
   If not success then begin
    Result := 0;
    ShowMessage('Input corrupted: '+input+' is not in alphabet.');
   end;
end;

// Find normalized integer corresponding to input
Function NormalizeState(input: string) : Integer;
var i: integer; success: Boolean;
begin
   success := false;
   For i := 0 to Length(states)-1 do begin
    If states[i] = input then begin
      Result := i;
      success := true;
      Break;
    end;
   end;
   If not success then begin
    Result := 0;
    ShowMessage('Input corrupted: '+input+' is not in state list.');
   end;
end;

Procedure setq(s_state, s_read, nstate, write, move: string);
var state, read: integer;
begin
  // Normalize state & read
  state := NormalizeState(s_state);
  read := NormalizeAlphabet(s_read);

  // Increment qdata size if needed
  If state >= Length(qdata) then begin
    SetLength(qdata, state+1);
  end;

  If read >= Length(qdata[state]) then begin
    SetLength(qdata[state], read+1);
  end;

  // Save data
  SetLength(qdata[state][read], 3);
  qdata[state][read][0] := nstate;
  qdata[state][read][1] := write;
  qdata[state][read][2] := move;
end;

// Code 'borrowed' from SQL Project :P
procedure Fill_Grid(SG: TStringGrid);
var
  i,j: Integer;
begin

  SG.ColCount:=0;
  SG.RowCount:=0;

  // Wir brauchen eine Zeile mehr für die Spaltenüberschriften
  SG.RowCount := Length(states)+1;
  SG.ColCount := length(alphabet)+1;
  SG.FixedRows := 0;

  // Scale rows to fit
  SG.DefaultColWidth := floor((SG.Width - 30) / SG.ColCount); // Subtract 30 to avoid horizontal scrolling when vertical scrollbar is shown

  // Write alphabet in first row
  for i := 0 to length(alphabet)-1 do begin
    SG.Cells[i+1, 0] := alphabet[i];
  end;

  // Write q rules
  for i := 0 to length(states)-1 do begin
    SG.Cells[0, i+1] := states[i];
    If i < Length(qdata) then begin
      for j := 0 to length(qdata[i])-1 do begin
        If Length(qdata[i][j]) = 3 then
          SG.Cells[j+1, i+1] := qdata[i][j][0] + ', ' + qdata[i][j][1] + ', ' + qdata[i][j][2]
        Else
          SG.Cells[j+1, i+1] := 'HALT';
      end;
    end;

    If i = accepting then
      SG.Cells[0, i+1] := states[i] + ' (ACCEPTING)';

    // Highlight active state
    If i = NormalizeState(state) then
      SG.Row := i+1;
      SG.Col := NormalizeAlphabet(GetBand(headpos))+1;

  end;
end;

Procedure viz();
begin
  Form1.Label2.Caption := 'Steps: '+inttostr(steps);
  Form1.Label3.Caption := 'State: '+state;
  Fill_Grid(Form1.StringGrid1);
  Form1.Panel1.caption := GetBand(headpos-4);
  Form1.Panel2.caption := GetBand(headpos-3);
  Form1.Panel3.caption := GetBand(headpos-2);
  Form1.Panel4.caption := GetBand(headpos-1);
  Form1.Panel5.caption := GetBand(headpos);
  Form1.Panel6.caption := GetBand(headpos+1);
  Form1.Panel7.caption := GetBand(headpos+2);
  Form1.Panel8.caption := GetBand(headpos+3);
  Form1.Panel9.caption := GetBand(headpos+4);
  Form1.Panel10.caption := GetBand(headpos+5);
end;

Procedure accept();
begin
  Form1.Panel11.caption := 'Input accepted!';
  Form1.Panel11.color := $0000ff00;

  // Pause simulation
  Form1.Timer1.enabled := false;
  Form1.Button1.Caption := 'Play';
end;

Procedure halt();
begin
  Form1.Panel11.caption := 'Machine halted.';
  Form1.Panel11.color := $000000ff;

  // Pause simulation
  Form1.Timer1.enabled := false;
  Form1.Button1.Caption := 'Play';
end;

Function q() : String;
var i_state, read: integer;
begin

  // Increment step count
  steps := steps + 1;

  // Update visualization
  viz();

  // Normalize state & read
  i_state := NormalizeState(state);
  read := NormalizeAlphabet(GetBand(headpos));

  // Check if accepting
  If i_state = accepting then begin
    accept();
    Result := 'Accept';
  end

  Else If i_state >= Length(qdata) then begin
    halt();
    Result := 'Halt';
  end

  Else If read >= Length(qdata[i_state]) then begin
    halt();
    Result := 'Halt';
  end

  Else begin
    If Length(qdata[i_state][read]) = 3 then begin

      // Change state
      state := qdata[i_state][read][0];

      // Write character to band
      SetBand(headpos, qdata[i_state][read][1]);

      // Move head
      If qdata[i_state][read][2] = 'L' then
        headpos := headpos - 1
      Else If qdata[i_state][read][2] = 'R' then
        headpos := headpos + 1
      Else
        ShowMessage('Invalid Movement Instruction, Expecting L or R');

      Result := 'Next Step';
    end
    Else begin
      halt();
      Result := 'Halt';
    end;
  end;
end;

// Do single step
procedure TForm1.Button2Click(Sender: TObject);
begin
  q();
end;

// Import DTM
procedure TForm1.Button3Click(Sender: TObject);
var rawdata: TStringList; alpha, buffer: string; i, j, a: integer; data: array of string;
begin
  if OpenDialog1.Execute then begin
    // If file chosen successfully load lines to string list
    rawdata := TStringList.Create;
    rawdata.LoadFromFile(OpenDialog1.FileName);

    If rawdata.count > 4 then begin
      // Reset headpos to 0
      headpos := 0;

      // Reset steps
      steps := 0;

      // Reset UI
      Form1.Panel11.caption := 'Running...';
      Form1.Panel11.color := $00cccccc;

      // Clear Band, States, Alphabet & Q Function
      SetLength(band, 0);
      SetLength(states, 0);
      SetLength(alphabet, 0);
      SetLength(qdata, 0);

      // Write first line of file to band without modification
      LoadBand(rawdata[0]);

      // Write band to edit
      Form1.Edit1.text := rawdata[0];

      ////////////////////////////////////////
      // Build Alphabet Normalization Table //
      ////////////////////////////////////////
      alpha := rawdata[1];
      buffer := '';

      SetLength(alphabet, 1);
      alphabet[0] := '#'; // Add blank to alphabet
      a := 1; // Alphabet table index

      For i := 1 to Length(alpha) do begin
        If alpha[i] = '$' then begin
          If Length(alphabet) <= a then
            SetLength(alphabet, a+1);
          alphabet[a] := buffer; // Add buffer to alphabet
          buffer := ''; // Clear buffer
          a := a + 1;
        end
        Else begin
          buffer := buffer + alpha[i]; // Add latest char to buffer
        end;
      end;

      // Add remaining buffer if needed
      If buffer <> '' then begin
        If Length(alphabet) <= a then
            SetLength(alphabet, a+1);
          alphabet[a] := buffer;
          buffer := ''; // Clear buffer
      end;

      /////////////////
      // Load states //
      /////////////////

      alpha := rawdata[2];
      buffer := '';

      a := 0; // state table index

      For i := 1 to Length(alpha) do begin
        If alpha[i] = '$' then begin
          If Length(states) <= a then
            SetLength(states, a+1);
          states[a] := buffer; // Add buffer to state list
          a := a + 1;
          buffer := ''; // Clear buffer
        end
        Else begin
          buffer := buffer + alpha[i]; // Add latest char to buffer
        end;
      end;

      // Add remaining buffer if needed
      If buffer <> '' then begin
        If Length(states) <= a then
            SetLength(states, a+1);
          states[a] := buffer;
          buffer := ''; // Clear buffer
      end;

      // Get starting state
      state := rawdata[3]; // State is normalized in q function
      s_start := state;

      // Get accepting state
      s_accepting := rawdata[4];
      accepting := NormalizeState(s_accepting);

      //////////////////
      // Load q rules //
      //////////////////

      For i := 5 to rawdata.count - 1 do begin
        buffer := '';
        a := 0; // Data array index
        SetLength(data, 5);

        For j := 1 to Length(rawdata[i]) do begin
          If rawdata[i][j] = '$' then begin
            data[a] := buffer; // Add buffer to data array
            a := a + 1;
            buffer := ''; // Clear buffer
          end
          Else begin
            buffer := buffer + rawdata[i][j]; // Add latest char to buffer
          end;
        end;

        // Add remaining buffer if needed
        If buffer <> '' then begin
          data[a] := buffer;
          buffer := ''; // Clear buffer
        end;

        // Save q rule
        Setq(data[0], data[1], data[2], data[3], data[4]);
      end;

      // Update GUI
      viz();
    end
    Else begin
      ShowMessage('Input file corrupted: Not enough information.');
    end;
  end;
end;

// Pause / Play simulation
procedure TForm1.Button1Click(Sender: TObject);
begin
  if Form1.Timer1.enabled then begin
    Form1.Button1.Caption := 'Play';
    Form1.Timer1.enabled := false;
  end
  else begin
    Form1.Button1.Caption := 'Pause';
    Form1.Timer1.enabled := true;
  end;
end;

// Do single step
procedure TForm1.Timer1Timer(Sender: TObject);
begin
  q();
end;

// Update simulation delay
procedure TForm1.TrackBar1Change(Sender: TObject);
begin
  Form1.Label1.Caption := 'Step Delay: '+Inttostr(TrackBar1.Position)+'ms';
  Form1.Timer1.Interval := TrackBar1.Position;
end;

procedure TForm1.Button4Click(Sender: TObject);
begin
  // Reset headpos to 0
  headpos := 0;

  // Reset steps
  steps := 0;

  // Reset UI
  Form1.Panel11.caption := 'Running...';
  Form1.Panel11.color := $00cccccc;

  // Clear Band
  SetLength(band, 0);

  // Return to start state
  state := s_start;

  // Load new band
  LoadBand(Form1.Edit1.Text);

  // Update GUI
  viz();
end;

end.
