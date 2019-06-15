Program ConString;

Uses
  Crt;

Const
  OutPutFile = 'Str.asm';
  CharArray =  'ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890!.,:()? #@+-$';
  NumStrings = 3;

Var
  StF : Text;
  TextA : Array(.1..NumStrings.) Of String(.80.);
  I, I2, SLength : Integer;

Begin
  SLength := 0;
  TextA(.1.) := 'SORCERER BBS - @ 47 72 87 28 74 - THE LOST SOULS WORLD HQ - ';
  TextA(.2.) := 'TERMINATE SUPPORT SITE - BILLIONS OF BYTES ONLINE! ';
  TextA(.3.) := 'PROGRAMMING RELATED FILES AND CONFERENCES - @72872874@';

  Assign(StF, OutPutFile);
  Rewrite(StF);
  Write(StF, '                DB ');
  For I2 := 1 To NumStrings Do
  Begin
    For I := 1 To Length(TextA(.I2.)) Do Write(StF, Pos(TextA(.I2, I.), CharArray), ', ');
    Inc(SLength, Length(TextA(.I2.)));
  End;
  Close(StF);
  WriteLn('TextLength : ', Slength);
  Repeat Until KeyPressed;
End.